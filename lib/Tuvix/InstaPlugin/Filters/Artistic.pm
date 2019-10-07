package Tuvix::InstaPlugin::Filters::Artistic;
use Tuvix::InstaPlugin::Filter;

use strict;
use warnings FATAL => 'all';

use Moose;

extends "Tuvix::InstaPlugin::Filter";

sub _apply {
    my $self = shift;
    my $source_image = shift;

    $source_image->Modulate(brightness => 110, saturation => 110, hue => 110);
    $source_image->ContrastStretch('5%');

    $source_image = $self->add_border($source_image, 'white');
    $source_image->Shave(geometry => '1x1');
    $source_image->Border(geometry => '1x1', color => 'gray');

    return $source_image;
}

