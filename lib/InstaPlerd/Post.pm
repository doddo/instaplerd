package InstaPlerd::Post;

use utf8;
use strict;

use InstaPlerd::ExifHelper;
use InstaPlerd::TitleGenerator;
use InstaPlerd::Util;

use Carp;
use Plerd::Post;

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
    my $orig  = shift;
    my $class = shift;
    my %args = @_;

    # Inject preferences from the global plerd config
    if ($args{plerd}{ extension_preferences }{ $class }){
        my $plugin_prefs = $args{plerd}->{ extension_preferences }{ $class };
        foreach my $key (%{$plugin_prefs}){
            if ($key eq 'filter' && ! defined $args { filter }) {
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
    unless (defined ${args}{'filter'}){
        load InstaPlerd::Filters::Artistic;
    }

    my @args = %args;
    return $class->$orig(@args);
};

has 'source_image' => (
        is      => 'rw',
        isa     => 'Maybe[Image::Magick]',
        default => sub {Image::Magick->new()},
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
        is  => 'rw',
        isa => 'Int',
        default => 85
    );

has 'instaplerd_template_file' => (
        is         => 'ro',
        isa        => 'Path::Class::File',
        lazy_build => 1
    );

has 'exif_helper' => (
        is  => 'rw',
        isa => 'InstaPlerd::ExifHelper',
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
        is      => 'rw',
        isa     => 'InstaPlerd::Filter',
        default => sub {InstaPlerd::Filters::Artistic->new()}
    );

has 'util' => (
        is      => 'ro',
        isa     => 'InstaPlerd::Util',
        default => sub {InstaPlerd::Util->new()}

    );

has 'title_generator' => (
        is      => 'rw',
        isa     => 'InstaPlerd::TitleGenerator',
    );



sub _process_source_file {
    my $self = shift;
    my %attributes;
    my $attributes_need_to_be_written_out = 0;
    my $image_needs_to_be_published = 0;
    my $body;

    my @ordered_attributes = qw(title time published_filename guid comment location checksum);
    try {
        my $source_meta = $self->util->load_image_meta($self->source_file->stringify);

        foreach my $key (@ordered_attributes) {
            $attributes{$key} = $$source_meta{$key} if exists $$source_meta{$key}
        };
    } catch {
        carp (sprintf ("No \"special\" comment data loaded from '%s':%s\n", $self->source_file, $&));
        $attributes_need_to_be_written_out = 1;
    };


    $self->exif_helper(
        InstaPlerd::ExifHelper->new
            (source_file => $self->source_file));
    $self->title_generator(
        InstaPlerd::TitleGenerator->new(exif_helper => $self->exif_helper()));


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

    if (!$attributes{'title'}) {
        $attributes{'title'} = $self->title_generator->generate_title($self->source_file->basename);
        $attributes_need_to_be_written_out = 1;

    }
    $self->title($attributes{ title });

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

    if ( $attributes{ location } && %{ $attributes{ location } } ) {
        $self->exif_helper->geo_data( $attributes{ location } );
    }
    elsif ($self->do_geo_lookup) {
        if ($self->exif_helper->geo_data) {
            $attributes{ location } = $self->exif_helper->geo_data;
            $attributes_need_to_be_written_out = 1;
        }
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

    my $published_filename_jpg = $attributes { published_filename };
    $published_filename_jpg =~ s/\.html?$/.jpeg/i;

    my $target_jpg_file_path =  File::Spec->catfile(
            $self->plerd->publication_path, 'images', $published_filename_jpg);

    if ( -e $target_jpg_file_path && $attributes{ checksum }) {

        my $fh = Path::Class::File->new($target_jpg_file_path);
        my $checksum = md5_hex($fh->slurp(iomode => '<:raw'));
        if ($checksum ne $attributes{ checksum }) {
            $image_needs_to_be_published = 1;
            $attributes_need_to_be_written_out =1;
        }
    } else {
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
            heigth       => $self->height,
            exif         => $self->exif_helper->exif_data,
            location     => $attributes{ location }{ address } || undef,
            uri          => File::Spec->catfile('images', $published_filename_jpg),
            context_post => $self,
        },
        \$body,
    ) || $self->plerd->_throw_template_exception($self->instaplerd_template_file);
    $self->body($body);

    if ($image_needs_to_be_published) {
        # this is expensive memory-wise
        $self->source_image->read($self->source_file);
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
            'geometry' => sprintf ("%ix%i", $self->width, $self->height),
        );

         # Here is where the magic happens
        mkpath(File::Spec->catdir(
            $self->plerd->publication_path, 'images'));

        $self->filter->apply($destination_image);
        # Remove all image metadata before publication (after filter in case it uses it for something...)
        $destination_image->Strip();

        # TODO: make path/ name more uniq
        $destination_image->write(
            filename => $target_jpg_file_path,
            compression => $self->image_compression);

        $attributes{ checksum } = md5_hex($destination_image->ImageToBlob());
    }

    if ($attributes_need_to_be_written_out) {
        $self->util->save_image_meta(
            $self->source_file->stringify, \%attributes);
    }
    $self->source_image(undef);
}

sub _build_instaplerd_template_file {
    my $self = shift;
    return Path::Class::File->new(
        $self->plerd->template_directory,
        'instaplerd_post_content.tt',
    );
}

1;