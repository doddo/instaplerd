package InstaPlerd::ExifHelper;

use strict;
use warnings FATAL => 'all';
use Moose;
use Carp;
use utf8;

use Try::Tiny;
use DateTime::Format::Strptime;
use Geo::Coordinates::Transform;
use Geo::Coder::OSM;

has 'source_image' => (
        is       => 'ro',
        isa      => 'Image::Magick',
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
    my %exif = map {m/(?:exif:)?([^=]+)=([^=]+)/
        ? ($1, $2)
        : ()} split(/[\r\n]/, $self->source_image->Get('format', '%[EXIF:*]'));

    while (my ($key, $value) = each %exif) {
        if ($key =~ /Date/) {
            try {
                my $date = $self->exifDateTimeParser->parse_datetime($value);
                $exif{$key} = $date;
            } catch {
                carp sprintf "can't make '%s': '%s' into DateTime object.", $key, $value;
            }
        }
    }
    return \%exif;
}

sub _build_geo_data {
    my $self = shift;
    my %geo;
    my @lat_long_list;
    my $lat_long;
    my $geo_data;

    while (my ($key, $value) = each %{$self->exif_data()}) {
        if ($key =~ /L(?:ong|at)itude/) {
            my $long_or_lat = lc($&);
            # 18/1, 0/1, 613/100 <-- google pixel phone
            # Degrees Minutes Decimal Seconds DD MM SS.SSSS
            if ($value =~ m|
                (?<degrees>\d+)/(?<degrees_f>\d+)[\s,]+
                    (?<minutes>\d+)/(?<minutes_f>\d+)[\s,]+
                    (?<seconds>\d+)/(?<seconds_f>\d+)
                |x) {
                my $dms = sprintf "%s %s %s",
                    $+{degrees} / $+{degrees_f},
                    $+{minutes} / $+{minutes_f},
                    $+{seconds} / $+{seconds_f};
                $geo{$long_or_lat} = $dms;

            }
            elsif ($value =~ m/[\s\d.]{3,}/) {
                # Looks like it could be coordinates?
                $geo{$long_or_lat} = $value;
            }
            else {
                carp sprintf "This: '%s' does not look like long / lat but key was: '%s'.", $value, $key;
            }
        }
    }
    if ($geo{latitude} && $geo{longitude}) {
        push(@lat_long_list, $geo{latitude}, $geo{longitude});

        my $lat_long_dd = $self->_geo_converter->cnv_to_dd(\@lat_long_list);
        $lat_long = join(',', @{$lat_long_dd});

        if ($lat_long && $lat_long ne 'NaN') {
            $geo_data = $self->_geo_coder->reverse_geocode(latlng => $lat_long);
            $$geo_data{latitude} ||= @{$lat_long_dd}[0];
            $$geo_data{longitude} ||= @{$lat_long_dd}[1];
        }
        else {
            carp sprintf "Could not make decimal lat/long from lat:%s long:%s", $geo{latitude}, $geo{longitude};
        }
    }
    else {
        carp sprintf "No / not enough geo data to process. No lookup will occur.";
    }
    return $geo_data;
}

1;