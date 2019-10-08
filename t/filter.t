#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use Image::Magick;
use FindBin;

use v5.15;

use lib "$FindBin::Bin/../lib";

my %FILTERS = (
    'Tuvix::InstaPlugin::Filter'                         => '156b3466df4e82f969f2840c230831ed070e5006d647a2711dc5c976378b9cce',
    'Tuvix::InstaPlugin::Filters::Artistic'              => 'd7b5fd9635a2bb9acc99343da5848681acc8a4d70ff140a6e85de3b510ebed64',
    'Tuvix::InstaPlugin::Filters::ArtisticGrayScale'     => 'e26521bf8b4dd8018d856fefb4d13a0ea948bfb1365498e900d7b0dd898699bb',
    'Tuvix::InstaPlugin::Filters::Batman'                => '1892fdadbd88d816fc70dafa3d0bf30f25b38db45df101aae783b62f4b8be1cd',
    'Tuvix::InstaPlugin::Filters::Nofilter'              => '156b3466df4e82f969f2840c230831ed070e5006d647a2711dc5c976378b9cce',
    'Tuvix::InstaPlugin::Filters::Pi'                    => '',
    'Tuvix::InstaPlugin::Filters::InstaGraph::Toaster'   => 'f97b9598146992746f0cf0b3000c85ccf181790236c3eede9c747043609980ba',
    'Tuvix::InstaPlugin::Filters::InstaGraph::Lomo'      => 'c24a4cef2126c3e3501a575e6d465f01f4bab186727de72d5d7916b42754d5d1',
    'Tuvix::InstaPlugin::Filters::InstaGraph::TiltShift' => '',
    'Tuvix::InstaPlugin::Filters::InstaGraph::Nashville' => '4ff710f9d9cc23d0486eb4e5ec31090dccecb77820d32265ddd3f2e0aa9514e1',
    'Tuvix::InstaPlugin::Filters::InstaGraph::TiltShift' => '0390e8b1cb82bfc10701a112c9eff9a06da553cf6be44d89011e8d8e93665f33',
    'Tuvix::InstaPlugin::Filters::InstaGraph::Gotham'    => 'bb630b35df21fb069f0533d7c0e8317287eef4872465a16d3671e9e593e2fc6a',
);

use_ok $_ for (keys %FILTERS);

my $img = "$FindBin::Bin/source/betong_lion.jpg";

my $source_image = Image::Magick->new();
$source_image->read($img);

my $magick_version = $source_image->Get('version');

for (keys %FILTERS) {
    my $filter = new $_;
    my $test_image = $source_image->clone();

    ok(my $filtered_image = $filter->apply($test_image), "$_ can apply");

    my $signature = $filtered_image->Get('Signature');

    if  ($magick_version =~ /\b7\.0\.7/ && $FILTERS{$_}){
        cmp_ok($signature, 'eq', $FILTERS{$_}, "Signature for $_ OK" );
    }
}

done_testing();

