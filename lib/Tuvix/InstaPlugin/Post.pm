package Tuvix::InstaPlugin::Post;

use utf8;
use strict;

use Tuvix::InstaPlugin::ExifHelper;
use Tuvix::InstaPlugin::TitleGenerator;
use Tuvix::InstaPlugin::Util;
use Tuvix::InstaPlugin::ObjectDetector;

use Carp;
use Plerd::Post;

use Mojo::Log;

use Path::Class::File;
use DateTime::Format::Strptime;
use Digest::MD5 qw(md5_hex);
use JSON;
use File::Path qw(mkpath);
use File::Spec;
use Image::Magick;

use Module::Load;
use Moose;

use Readonly;
use Try::Tiny;

use warnings FATAL => 'all';

extends "Plerd::Post";

sub file_type {
    'jpe?g';
}

around BUILDARGS => sub {
    my $orig = shift;
    my $class = shift;
    my %args = @_;

    # Inject preferences from the global plerd config
    if ($args{plerd}{ extension_preferences }{ $class }) {
        my $plugin_prefs = $args{plerd}->{ extension_preferences }{ $class };
        foreach my $key (%{$plugin_prefs}) {
            if ($key eq 'filter' && !defined $args{ filter }) {
                load $$plugin_prefs{ $key };
                $args{$key} = $$plugin_prefs{ $key }->new();
            }
            else {
                # Preferences already set when creating object take precedence over
                # what ever is specified in the config.
                $args{$key} ||= $$plugin_prefs{ $key }
            }
        }
    }
    # load the default filter if none is specified ...
    unless (defined ${args}{'filter'}) {
        load Tuvix::InstaPlugin::Filters::Artistic;
    }

    my @args = %args;
    return $class->$orig(@args);
};

has 'source_image' => (
    is         => 'rw',
    isa        => 'Maybe[Image::Magick]',
    lazy_build => 1,
);

has 'log' => (
    is      => 'rw',
    isa     => 'Mojo::Log',
    default => sub {Mojo::Log->new()}
);

has 'width' => (
    is      => 'ro',
    isa     => 'Int',
    default => 847
);

has 'height' => (
    is      => 'ro',
    isa     => 'Int',
    default => 840
);

has 'image_compression' => (
    is      => 'rw',
    isa     => 'Int',
    default => 85
);

has 'instaplerd_template_file' => (
    is         => 'ro',
    isa        => 'Path::Class::File',
    lazy_build => 1
);

has 'exif_helper' => (
    is  => 'rw',
    isa => 'Tuvix::InstaPlugin::ExifHelper',
);

has 'resize_source_picture' => (
    is      => 'rw',
    isa     => 'Bool',
    default => 1
);

has 'do_geo_lookup' => (
    is      => 'rw',
    isa     => 'Bool',
    default => 1
);

has 'source_file' => (
    is       => 'ro',
    isa      => 'Path::Class::File',
    required => 1,
    trigger  => \&_process_source_file,
);

has 'filter' => (
    is         => 'rw',
    isa        => 'Tuvix::InstaPlugin::Filter',
    lazy_build => 1,
);

has 'util' => (
    is      => 'ro',
    isa     => 'Tuvix::InstaPlugin::Util',
    default => sub {Tuvix::InstaPlugin::Util->new()}

);

has 'title_generator' => (
    is  => 'rw',
    isa => 'Tuvix::InstaPlugin::TitleGenerator',
);

has 'clarafai_api_key' => (
    is       => 'ro',
    isa      => 'Str',
    required => 0
);

has '_dest_image' => (
    is         => 'rw',
    isa        => 'Maybe[Image::Magick]',
    lazy_build => 1
);

sub BUILD {
    my $self = shift;
    if (!-f $self->instaplerd_template_file) {
        carp sprintf("Can't load '%s'\n", $self->instaplerd_template_file);
    }
};


sub _process_source_file {
    my $self = shift;
    my %attributes;
    my $attributes_need_to_be_written_out = 0;
    my $image_needs_to_be_published = 0;
    my $body;

    my @ordered_attributes = qw(title time published_filename guid comment location concepts checksum filter tags);
    try {
        my $source_meta = $self->util->load_image_meta($self->source_file->stringify);

        foreach my $key (@ordered_attributes) {
            $attributes{$key} = $$source_meta{$key} if exists $$source_meta{$key}
        };
    }
    catch {
        $self->log->info(
            sprintf("No \"special\" comment data loaded from '%s':%s\n", $self->source_file, $&));
        $attributes_need_to_be_written_out = 1;
    };

    $self->exif_helper(
        Tuvix::InstaPlugin::ExifHelper->new(
            source_file => $self->source_file,
            log         => $self->log
        ));

    if ($attributes{location} // 0) {
        $self->exif_helper->geo_data($attributes{location});
    }

    $self->attributes(\%attributes);

    if ($attributes{ 'guid' }) {
        $self->guid(Data::GUID->from_string($attributes{ 'guid' }));
    }
    else {
        my $guid = Data::GUID->new;
        $attributes{ 'guid' } = $guid->as_string;
        $self->guid($guid);
        $attributes_need_to_be_written_out = 1;
    }

    if ($attributes{ time }) {
        eval {
            $self->date(
                $self->plerd->datetime_formatter->parse_datetime($attributes{ time })
            );
            $self->date->set_time_zone('local');
        };
        unless ($self->date) {
            die 'Error processing ' . $self->source_file . ': '
                . 'The "time" attribute is not in W3C format.'
            ;
        }
    }
    else {
        my $publication_dt;
        # TODO use exif for this rather than NOW
        $publication_dt = DateTime->now(time_zone => 'local');
        $self->date($publication_dt);

        my $date_string =
            $self->plerd->datetime_formatter->format_datetime($publication_dt);

        $attributes{ time } = $date_string;
        $attributes_need_to_be_written_out = 1;
    }

    if ($attributes{ published_filename }) {
        $self->published_filename($attributes{ published_filename });
    }
    else {
        $attributes{ published_filename } = $self->published_filename;
        $attributes_need_to_be_written_out = 1;
    }

    if ($attributes{ location } && %{$attributes{ location }}) {
        $self->exif_helper->geo_data($attributes{ location });
    }
    elsif ($self->do_geo_lookup) {
        $self->log->info("Doing geo data lookup");
        if ($self->exif_helper->geo_data) {
            $attributes{ location } = $self->exif_helper->geo_data;
            $attributes_need_to_be_written_out = 1;
        }
    }
    else {
        $self->debug('skipping geo lookup: do_geo_lookup not enabled.');
    }

    if ($attributes{ filter }) {
        # TODO
        my $filter = 'Tuvix::InstaPlugin::Filters::' . $attributes{ filter };
        load $filter;
        $self->filter($filter->new());
    }
    else {
        $attributes_need_to_be_written_out = 1;
        $attributes{ filter } = $self->filter->name;
    }

    # TODO
    if ($attributes{ image }) {
        $self->image(URI->new($attributes{ image }));
        $self->image_alt($attributes{ image_alt } || '');
        $self->socialmeta_mode('featured_image');
    }
    else {
        $self->image($self->plerd->image);
        $self->image_alt($self->plerd->image_alt || '');
    }

    my $published_filename_jpg = $attributes{ published_filename };
    $published_filename_jpg =~ s/\.html?$/.jpeg/i;

    my $target_jpg_file_path = File::Spec->catfile(
        $self->plerd->publication_path, 'images', $published_filename_jpg);

    if (-e $target_jpg_file_path && $attributes{ checksum }) {

        my $fh = Path::Class::File->new($target_jpg_file_path);
        my $checksum = md5_hex($fh->slurp(iomode => '<:raw'));
        if ($checksum ne $attributes{ checksum }) {
            printf "checksum for '%s' has changed. On disk: <%s>, in '%s' meta: <%s>. Regenerating it usw.\n",
                $fh->basename, ${checksum}, $self->source_file->basename, $attributes{ checksum };
            $image_needs_to_be_published = 1;
            $attributes_need_to_be_written_out = 1;
        }
    }
    else {
        $self->log->info(sprintf "checksum for '%s' not stored in META. This triggers image generation.",
            $self->source_file->basename);
        $image_needs_to_be_published = 1;
        $attributes_need_to_be_written_out = 1;
    }

    $self->plerd->template->process(
        $self->instaplerd_template_file->open('<:encoding(utf8)'),
        {
            plerd        => $self->plerd,
            posts        => [ $self ],
            title        => $self->title,
            width        => $self->width,
            height       => $self->height,
            exif         => $self->exif_helper->exif_data,
            filter       => $attributes{ filter },
            location     => $attributes{ location }{ address } || undef,
            uri          => File::Spec->catfile('/images', $published_filename_jpg),
            context_post => $self,
        },
        \$body,
    ) || $self->plerd->_throw_template_exception($self->instaplerd_template_file);
    $self->body($body);

    if (!$attributes{concepts}) {
        # Do obj detection on the cropped image
        if ($self->clarafai_api_key) {
            $self->log->info('Attempting some object detection.');
            my $object_detector = Tuvix::InstaPlugin::ObjectDetector->new(
                clarafai_api_key => $self->clarafai_api_key,
                image            => $self->_dest_image
            );
            $object_detector->process();

            $attributes{'concepts'} = $object_detector->concepts;
            if ($attributes{'concepts'}) {
                $attributes_need_to_be_written_out = 1;
            }
            else {
                $self->log->info("No concepts detected in the image.");
            }
        }
    }

    if ($attributes{concepts}){
        # Todo maybe limit (here will be up to like 20 tags from concepts)
        my @concepts =
            sort { $attributes{concepts}{$a} <=> $attributes{concepts}{$b} }
                keys %{$attributes{concepts}};

        my @ten_concepts = map { $_ // () } @concepts[0..9];
        $self->tags(\@ten_concepts);
    }

    if (!$attributes{'title'}) {
        $self->title_generator(
            Tuvix::InstaPlugin::TitleGenerator->new(
                exif_helper => $self->exif_helper(),
                concepts    => $attributes{concepts} // {}));
        $attributes{'title'} = $self->title_generator->generate_title($self->source_file->basename);
        $attributes_need_to_be_written_out = 1;

    }
    $self->title($attributes{ title });

    if ($image_needs_to_be_published) {

        my $destination_image = $self->_dest_image;

        # Here is where the magic happens
        mkpath(File::Spec->catdir(
            $self->plerd->publication_path, 'images'));

        my $filtered_image = $self->filter->apply($destination_image);

        $filtered_image->Coalesce();
        # Remove all image metadata before publication (after filter in case it uses it for something...)
        $filtered_image->Strip();
        $filtered_image->Set(compression => $self->image_compression);

        # TODO: make path/ name more uniq
        my $fh = Path::Class::File->new($target_jpg_file_path);
        $fh->spew(iomode => '>:raw', $filtered_image->ImageToBlob());

        $attributes{ checksum } = md5_hex($filtered_image->ImageToBlob());

    }

    if ($attributes_need_to_be_written_out) {
        $self->util->save_image_meta(
            $self->source_file->stringify, \%attributes);
    }
    # To save some memory.
    $self->source_image(undef);
    $self->_dest_image(undef);
}

sub _build_instaplerd_template_file {
    my $self = shift;
    return Path::Class::File->new(
        $self->plerd->template_directory,
        'instaplerd_post_content.tt',
    );
}

sub _build__dest_image {
    my $self = shift;

    my $destination_image = $self->source_image->Clone();

    # fix rotation if need be
    $destination_image->AutoOrient();

    my ($height, $width) = $self->source_image->Get('height', 'width');
    $destination_image->Resize(
        'gravity'  => 'Center',
        'geometry' =>
            $height / $self->height < $width / $self->width
                ? sprintf 'x%i', $self->height
                : sprintf '%ix', $self->width
    );

    $destination_image->Crop(
        'gravity'  => 'Center',
        'geometry' => sprintf("%ix%i", $self->width, $self->height),
    );

    return $destination_image;
}

sub _build_source_image {
    my $self = shift;
    my $source_image = Image::Magick->new();
    $source_image->read($self->source_file);
    return $source_image;
}

sub _build_filter {
    my $self = shift;
    my @available_filters = qw/Artistic ArtisticGrayscale Batman Nelville Pi/;
    my $filter = sprintf 'Tuvix::InstaPlugin::Filters::%s', $available_filters[rand @available_filters];
    load $filter;
    return $filter->new();

}

1;