#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use Digest::MD5 qw(md5_hex);

use Image::Magick;
use FindBin;

use v5.15;

use lib "$FindBin::Bin/../lib";

my %FILTERS = (
    'Tuvix::InstaPlugin::Filter'                         => '6397b3fe11c1986631d9517edce32161',
    'Tuvix::InstaPlugin::Filters::Artistic'              => '42d2244670f4fdd5ebb66679e9c0183d',
    'Tuvix::InstaPlugin::Filters::ArtisticGrayScale'     => 'fa10ced9d50b805664975d2f7d2214ad',
    'Tuvix::InstaPlugin::Filters::Batman'                => 'e5b3ea78437da3b36559655adcb4e485',
    'Tuvix::InstaPlugin::Filters::Nelville'              => '9d3c8d9cede5bd6c501f345cf28a5832',
    'Tuvix::InstaPlugin::Filters::Nofilter'              => '6397b3fe11c1986631d9517edce32161',
    'Tuvix::InstaPlugin::Filters::Pi'                    => '53e43d49b650e2ca73bb7d7341d4b34e',
    'Tuvix::InstaPlugin::Filters::InstaGraph::Toaster'   => '2d883a3102d114e6d7848a2bb6e8dbae',
    'Tuvix::InstaPlugin::Filters::InstaGraph::Lomo'      => 'f3a163855cc2356ff0ba6d823ddb4c9b',
    'Tuvix::InstaPlugin::Filters::InstaGraph::TiltShift' => '2bd917c00a01c57940868adb9b63f405',
    'Tuvix::InstaPlugin::Filters::InstaGraph::Nashville' => 'bab8d64bd44731ed8e163eb30d00e122',
    'Tuvix::InstaPlugin::Filters::InstaGraph::TiltShift' => '2bd917c00a01c57940868adb9b63f405',
    'Tuvix::InstaPlugin::Filters::InstaGraph::Gotham'    => 'ca42c5ecea2d89d96513281be7a18d9a',
);

use_ok $_ for (keys %FILTERS);

my $img = "$FindBin::Bin/source/betong_lion.jpg";

my $source_image = Image::Magick->new();
$source_image->read($img);

for (keys %FILTERS) {
    my $filter = new $_;
    my $test_image = $source_image->clone();

    ok(my $filtered_image = $filter->apply($test_image), "$_ can apply");

    my $checksum = md5_hex($filtered_image->ImageToBlob());

    cmp_ok ($checksum, 'eq', $checksum, "Checksum for $_ OK" );

}

done_testing();

