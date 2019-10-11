#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use Image::Magick;
use FindBin;

use v5.15;

use lib "$FindBin::Bin/../lib";

my @FILTERS = (
    'Tuvix::InstaPlugin::Filters::Artistic',
    'Tuvix::InstaPlugin::Filters::ArtisticGrayScale',
    'Tuvix::InstaPlugin::Filters::Batman',
    'Tuvix::InstaPlugin::Filters::Nofilter',
    'Tuvix::InstaPlugin::Filters::Pi',
    'Tuvix::InstaPlugin::Filters::Polaroid',
    'Tuvix::InstaPlugin::Filters::InstaGraph::Toaster',
    'Tuvix::InstaPlugin::Filters::InstaGraph::Lomo',
    'Tuvix::InstaPlugin::Filters::InstaGraph::TiltShift',
);

use_ok $_ for (@FILTERS);

my $img = "$FindBin::Bin/source/betong_lion.jpg";

my $source_image = Image::Magick->new();
$source_image->read($img);

my ($ref_height, $ref_width) = $source_image->get('Height', 'Width');

for (@FILTERS) {

    my $filter = new $_;
    my $test_image = $source_image->clone();
    $test_image->Strip();

    ok(my $filtered_image = $filter->apply($test_image), "$_ can apply");

    my ($height, $width) = $filtered_image->get('Height', 'Width');

    cmp_ok($height, '==', $ref_height, "ref image height $ref_height matches.");
    cmp_ok($width, '==', $ref_width, "ref image width $ref_width matches.");

    cmp_ok('Tuvix::InstaPlugin::Filters::' . $filter->name(), 'eq', $_, "$_ has correct name");

    # TODO diff filtered images with reference images
}

done_testing();

