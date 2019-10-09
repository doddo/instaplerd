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
        'Tuvix::InstaPlugin::Filters::Nelville',
        'Tuvix::InstaPlugin::Filters::Nofilter',
        'Tuvix::InstaPlugin::Filters::Pi',
        'Tuvix::InstaPlugin::Filters::InstaGraph::Toaster',
        'Tuvix::InstaPlugin::Filters::InstaGraph::Lomo',
        'Tuvix::InstaPlugin::Filters::InstaGraph::TiltShift',
        'Tuvix::InstaPlugin::Filters::InstaGraph::Nashville',
        'Tuvix::InstaPlugin::Filters::InstaGraph::TiltShift',
        'Tuvix::InstaPlugin::Filters::InstaGraph::Gotham',
);

use_ok $_ for (@FILTERS);

my $img = "$FindBin::Bin/source/betong_lion.jpg";

my $source_image = Image::Magick->new();
$source_image->read($img);


for (@FILTERS) {


    my $filter = new $_;
    my $test_image = $source_image->clone();
    $test_image->Strip();

    ok(my $filtered_image = $filter->apply($test_image), "$_ can apply");


        #my $ref_image = Image::Magick->new();

        cmp_ok('Tuvix::InstaPlugin::Filters::' . $filter->name(), 'eq',  $_, "$_ has correct name");

        # TODO diff filtered images with reference images
}

done_testing();

