package InstaPlerd::ExifHelper;

use strict;
use warnings FATAL => 'all';
use Moose;
use Carp;
use Try::Tiny;
use DateTime::Format::Strptime;

use Geo::Coder::Bing;
use Geo::Coder::Googlev3;
use Geo::Coder::Mapquest;
use Geo::Coder::OSM;
use Geo::Coder::Many;
use Geo::Coder::Many::Util qw( country_filter );

### Geo::Coder::Many object
my $geocoder_many = Geo::Coder::Many->new( );

$geocoder_many->add_geocoder({ geocoder => Geo::Coder::Googlev3->new });
$geocoder_many->add_geocoder({ geocoder => Geo::Coder::Bing->new( key => 'GET ONE' )});
$geocoder_many->add_geocoder({ geocoder => Geo::Coder::Mapquest->new( apikey => 'GET ONE' )});
$geocoder_many->add_geocoder({ geocoder => Geo::Coder::OSM->new( sources => 'mapquest' )});

$geocoder_many->set_filter_callback(country_filter('United States'));
$geocoder_many->set_picker_callback('max_precision');

for my $location (@locations) {
  my $result = $geocoder_many->geocode({ location => $location });
}


has 'source_image' => (
    is => 'ro',
    isa => 'Image::Magick',
    required => 1,
    trigger => \&_load_exif_data
);

has 'exifDateTimeParser' => (
    is => 'ro',
    isa => 'DateTime::Format::Strptime',
    default => sub {
        DateTime::Format::Strptime->new(
            pattern => "%Y:%m:%d %T",
            on_error => 'croak')
    }
);

has 'exif_data' => (
    is => 'rw',
    isa => 'HashRef',
);

sub _load_exif_data {
    my $self = shift;
    my %exif = map { m/(?:exif:)?([^=]+)=([^=]+)/
    ? ($1, $2)
    : ()} split(/[\r\n]/, $self->source_image->Get('format', '%[EXIF:*]'));

    while (my ($key, $value) = each %exif){
        if ($key =~ /Date/) {
            try {
                $exif{$key} = $self->exifDateTimeParser->parse_datetime($value);
            } catch {
                carp sprintf "can't make '%s': '%s' into DateTime object.", $key, $value;
            }
        }
    }
    $self->exif_data(\%exif);
}

1;