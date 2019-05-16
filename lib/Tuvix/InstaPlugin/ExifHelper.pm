package Tuvix::InstaPlugin::ExifHelper;

use strict;
use warnings FATAL => 'all';
use Moose;
use Carp;
use utf8;

use Mojo::Log;


use Try::Tiny;
use DateTime::Format::Strptime;
use Geo::Coordinates::Transform;
use Geo::Coder::OSM;
use Image::ExifTool;
use Path::Class::File;

has 'source_file' => (
    is       => 'ro',
    isa      => 'Path::Class::File',
    required => 1,
);

has 'exifDateTimeParser' => (
    is      => 'ro',
    isa     => 'DateTime::Format::Strptime',
    default => sub {
        DateTime::Format::Strptime->new(
            pattern  => "%Y:%m:%d %T",
            on_error => 'croak')
    }
);

has 'exiftool' => (
    is      => 'ro',
    isa     => 'Image::ExifTool',
    default => sub {
        my $tool = Image::ExifTool->new();
        $tool->Options(CoordFormat => q{%d %d %+.4f});
        return $tool;
    }
);

has 'log' => (
    is      => 'rw',
    isa     => 'Mojo::Log',
    default => sub { Mojo::Log->new() }
);

has '_geo_coder' => (
    is      => 'ro',
    isa     => 'Geo::Coder::OSM',
    default => sub {
        Geo::Coder::OSM->new(
            sources => [ 'osm' ],
            debug   => 0
        )
    }
);

has '_geo_converter' => (
    is      => 'ro',
    isa     => 'Geo::Coordinates::Transform',
    default => sub {new Geo::Coordinates::Transform()}
);

has 'geo_data' => (
    is         => 'rw',
    isa        => 'Maybe[HashRef]',
    lazy_build => 1
);

has 'exif_data' => (
    is         => 'rw',
    isa        => 'HashRef',
    lazy_build => 1,
);

sub timestamp {
    my $self = shift;
    return ${$self->exif_data()}{ DateTime } || undef;
}

sub latitude {
    my $self = shift;
    return
        ${$self->geo_data()}{ latitude } ||
            ${$self->geo_data()}{ location }{ lat } ||
            undef;
}

sub longitude {
    my $self = shift;
    return
        ${$self->geo_data()}{ longitude } ||
            ${$self->geo_data()}{ location }{ lon } ||
            undef;

}


sub _build_exif_data {
    my $self = shift;
    my $timestamp;

    my $exif = $self->exiftool->ImageInfo($self->source_file->stringify);
    while (my ($key, $value) = each %{$exif}) {
        if ($key =~ /Date/) {
            try {
                my $date = $self->exifDateTimeParser->parse_datetime($value);
                $$exif{$key} = $date;
                if ($key eq 'CreateDate') {
                    $timestamp = $date;
                }
            }
            catch {
                $self->log->warn(
                    sprintf"can't make '%s': '%s' into DateTime object.", $key, $value);
            }
        }
    }
    if ($timestamp) {
        # ¯\_(ツ)_/¯
        $$exif{DateTime} = $timestamp;
    } else {
        $self->log->warn("Unable to parse date from exif data.");
        # TODO try to grab it from filename instead.
    }
    return $exif;
}

sub _build_geo_data {
    my $self = shift;
    my $lat_long;
    my $geo_data;

    if (${$self->exif_data()}{ GPSLatitude } && ${$self->exif_data()}{ GPSLongitude }) {
        my $lat = ${$self->exif_data()}{ GPSLatitude };
        my $lon = ${$self->exif_data()}{ GPSLongitude };
        $$geo_data{hemisphere} = ${$self->exif_data()}{ GPSLatitudeRef };

        # Remove + to avoid sprintf error... TODO fix
        $lat =~ s/\+//;
        $lon =~ s/\+//;
        my @lat_long_list = ($lat, $lon);

        my $lat_long_dd = $self->_geo_converter->cnv_to_dd(\@lat_long_list);
        $lat_long = join(',', @{$lat_long_dd});

        if ($lat_long && $lat_long ne 'NaN') {
            $geo_data = $self->_geo_coder->reverse_geocode(latlng => $lat_long);
            if (defined $$geo_data{display_name}){
                $self->log->info(
                    sprintf "Got geo data [%s]", $$geo_data{display_name} // 'no display_name');
            } else {
                my $r = $self->_geo_coder->response();
                if ($r->is_success){
                    $self->log->error(
                        sprintf "Unexpected response from geo data lookup [%.30s]", $r->decoded_content);
                }
                else {
                    $self->log->error(
                        sprintf "Error looking up geo data [%s]", $r->status_line);
                }
            }

            $$geo_data{latitude} ||= @{$lat_long_dd}[0];
            $$geo_data{longitude} ||= @{$lat_long_dd}[1];

        }
        else {
            $self->log->warn(
                sprintf("Could not make decimal lat/long from lat:%s lon:%s", $lat, $lon));
        }
    }
    else {
        $self->log->warn("No / not enough geo data to process. No lookup will occur.");
    }
    return $geo_data;
}

1;