#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use File::Copy;
use Path::Class::File;

use Image::Magick;

use FindBin;

use lib "$FindBin::Bin/../lib";

use Tuvix::InstaPlugin::Post;
use Plerd;

my @TEST_GEOMETREIS = (
    {'width' => 48, 'heigth' => 64},
    {'width' => 64, 'heigth' => 48},
    {'width' => 847, 'heigth' => 48},
    {'width' => 48, 'heigth' => 847},
    {'width' => 4032, 'heigth' => 3024},
    {'width' => 3024, 'heigth' => 4032},
    {'width' => 3036, 'heigth' => 4048},
    {'width' => 4048, 'heigth' => 3036}
);


my $img_file_name = "$FindBin::Bin/source/slask/IMG_20190106_214653_64x64.jpg";

unlink $img_file_name if (-f $img_file_name);

copy("$FindBin::Bin/source/IMG_20190106_214653_64x64.jpg", $img_file_name)
    or die "Cannot setup test file $img_file_name: $!\n";


my $plerd = Plerd->new(
    path             => "$FindBin::Bin/target",
    publication_path => "$FindBin::Bin/target/public",
    title            => 'Test Blog',
    author_name      => 'Nobody',
    author_email     => 'nobody@example.com',
    extensions       => [ 'Tuvix::InstaPlugin' ],
    base_uri         => URI->new('http://blog.example.com/'),
    image            => URI->new('http://blog.example.com/logo.png'),
);

my $img_file = Path::Class::File->new($img_file_name);

ok(my $post = Tuvix::InstaPlugin::Post->new(source_file => $img_file, plerd => $plerd));


my ($width, $height) = $post->_dest_image()->Get('width', 'height');


cmp_ok($width, 'eq', 847, "actual width is 847");
cmp_ok($height, 'eq', 840, "actual height is 840");

my $image = Image::Magick->new();
$image->Read($img_file);


foreach my $t (@TEST_GEOMETREIS){
    my $desired_width = $$t{width};
    my $desired_height = $$t{heigth};


    my $desired_geometry = sprintf ("%sx%s", $desired_width, $desired_height);

    {
        my $image_to_resize = $image->clone();
        $image_to_resize->Resize($desired_geometry);
        $image_to_resize->Extent(geometry=>$desired_geometry, background=>"brown");

        $post->_resize_image($image_to_resize);
        $post->_crop_image($image_to_resize);

        my $width = $image_to_resize->Get("width");
        my $height = $image_to_resize->Get("height");

        cmp_ok($width, 'eq', 847, "actual width is 847 for $desired_geometry");
        cmp_ok($height, 'eq', 840, "actual height is 840 for $desired_geometry");
    }

}



done_testing();

