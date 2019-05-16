package Tuvix::InstaPlugin::Filters::Artistic;
use Tuvix::InstaPlugin::Filter;

use strict;
use warnings FATAL => 'all';

use Moose;
use Carp;

extends "Tuvix::InstaPlugin::Filter";

sub _apply {
    my $self = shift;
    my $source_image = shift;

    $source_image->Modulate(brightness => 110, saturation => 110, hue => 110);
    $source_image->ContrastStretch('5%');
    $source_image->Shave(geometry => '30x30');

    $source_image->Border(geometry => '29x29', color => 'white');
    $source_image->Border(geometry => '1x1', color => 'gray');

    return $source_image;
}

