use warnings;
use strict;
use Test::More;
use utf8;

use feature qw/say/;

use DateTime;
use Image::Magick;
use Path::Class::File;

use FindBin;

use lib "$FindBin::Bin/../lib";
use InstaPlerd::TitleGenerator;
use InstaPlerd::ExifHelper;
use InstaPlerd::Util;


my $img = "$FindBin::Bin/source/betong_lion.jpg";

my $img_file = Path::Class::File->new($img);

my $eh = InstaPlerd::ExifHelper->new(source_file => $img_file);
my $tg = InstaPlerd::TitleGenerator->new(exif_helper => $eh);
my $util = InstaPlerd::Util->new();

my $meta = $util->load_image_meta($img);
$eh->geo_data($$meta{location});

is (ref $eh->exif_data(), 'HASH', 'exif data is HASH');
is (ref $eh->geo_data(), 'HASH', 'exif data is HASH');
is (ref $meta, 'HASH', 'metadata is HASH');

is (ref ${$eh->exif_data()}{ DateTime }, 'DateTime', 'DateTime object grabbed from image exif metadata');
is (${$eh->exif_data()}{ DateTime }, $eh->timestamp(), 'Dates match');
is ($eh->timestamp()->ymd, "2018-11-10", "timestamp set correct date");
is ($eh->timestamp(),
    $eh->exifDateTimeParser->parse_datetime("2018:11:10 17:04:51"), "dates match parsed timestamp in exif fmt.");

like ($tg->season, qr/fall|autumn/, 'exif date data can be translated to metrological season');
is ($tg->time_of_day, 'evening', 'exif date data can translated to time of day');

#is ($eh->longitude(), "18.0622516", "Longitude OK");
#is ($eh->latitude(), "59.3353589", "Latitude OK");

is ($tg->generate_title("betong_lion.jpg"), "Betong Lion", 'create nice title from from name');

foreach my $bad_title (qw/IMG_4142.JPG dscf0008.jpg dsc_1010.jpg P4122246.jpg dsc_1011.jpeg IMG_20181105_215107.jpg/) {
    isnt ($tg->generate_title($bad_title), $tg->_capitalise($bad_title),
        "Don't just capitalize title '$bad_title'");
    my $title = $tg->generate_title($bad_title);
    ok (defined $title, "Some defined title derived from $bad_title :" . $title || 'undef' );
}


done_testing();
