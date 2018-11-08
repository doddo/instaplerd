package InstaPlerd::Post;

use utf8;

use InstaPlerd::ExifHelper;

use Plerd::Post;
use DateTime::Format::Strptime;
use JSON;
use File::Path qw(mkpath);
use Moose;
use Readonly;
use File::Spec;
use Try::Tiny;
use Image::Magick;
use strict;

# Todo dynamically load
use InstaPlerd::Filters::Artistic;

use warnings FATAL => 'all';

extends "Plerd::Post";

has 'source_image' => (
        is      => 'ro',
        isa     => 'Image::Magick',
        default => sub {Image::Magick->new()},
    );

has 'width' => (
        is      => 'ro',
        isa     => 'Int',
        default => 720
    );

has 'height' => (
        is      => 'ro',
        isa     => 'Int',
        default => 840
    );

has 'instaplerd_template_file' => (
        is         => 'ro',
        isa        => 'Path::Class::File',
        lazy_build => 1
    );

has 'json' => (
        is      => 'ro',
        isa     => 'JSON',
        default => sub {JSON->new->utf8->allow_nonref}
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

sub _process_source_file {
    my $self = shift;
    my %attributes;
    my $attributes_need_to_be_written_out = 0;
    my $body;
    my $destination_image;

    $self->source_image->read($self->source_file);
    $destination_image = $self->source_image->Clone();
    $self->exif_helper(
        InstaPlerd::ExifHelper->new(source_image => $self->source_image));

    my ($height, $width) = $self->source_image->Get('height', 'width');

    my @ordered_attributes = qw(title time published_filename guid comment location);
    try {
        my $source_meta = $self->json->decode($self->source_image->get('comment'));
        foreach my $key (@ordered_attributes) {
            $attributes{$key} = $$source_meta{$key} if exists $$source_meta{$key}
        };
    } catch {
        if ($self->source_image->get('comment')) {
            $attributes{'comment'} = $self->source_image->get('comment');
        }
        $attributes_need_to_be_written_out = 1;
    };

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
        $attributes{'title'} = $self->_create_title_from_filename($self->source_file->basename);
        $attributes_need_to_be_written_out = 1;

    }
    $self->title($attributes{'title'});

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

    if ($self->do_geo_lookup && !$attributes{ location }) {
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
            uri          => File::Spec->catfile('images', $attributes{ 'guid' }, $self->source_file->basename),
            context_post => $self,
        },
        \$body,
    ) || $self->plerd->_throw_template_exception($self->instaplerd_template_file);
    $self->body($body);

    if ($attributes_need_to_be_written_out) {
        my $payload = $self->json->encode(\%attributes);

        $self->source_image->Set("comment" => $payload);

        my @outdata = $self->source_image->ImageToBlob();

        $self->source_file->spew(iomode => '>:raw', @outdata);
    }

    # Here is where the magic happens
    mkpath(File::Spec->catdir(
        $self->plerd->publication_path, 'images', $attributes{ 'guid' }));

    $self->filter->apply($destination_image);
    # Remove all image metadata before publication (after filter in case it uses it for something...)
    $destination_image->Strip();

    $destination_image->write(File::Spec->catfile(
        $self->plerd->publication_path, 'images', $attributes{ 'guid' }, $self->source_file->basename));

}

sub _build_instaplerd_template_file {
    my $self = shift;
    return Path::Class::File->new(
        $self->plerd->template_directory,
        'instaplerd_post_content.tt',
    );
}

sub _create_title_from_filename {
    my $self = shift;
    my $filename = shift;
    $filename =~ s/\.jpe?g//i;
    $filename =~ s/_/ /g;
    $filename =~ s/([\w']+)/\u\L$1/g;
    return $filename;
}

1;