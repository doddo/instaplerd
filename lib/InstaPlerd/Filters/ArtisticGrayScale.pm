package InstaPlerd::Filters::ArtisticGrayScale;
use InstaPlerd::Filter;

use strict;
use warnings FATAL => 'all';

use Moose;
use Carp;

extends "InstaPlerd::Filter";

sub _apply {
    my $self = shift;
    my $source_image = shift;

    $source_image->Modulate(brightness => 110, saturation => 110, hue => 110);
    $source_image->ContrastStretch('5%');

    # Add the border
    $source_image->Shave(geometry => '15x15');
    $source_image->Border(geometry => '14x14', color => 'white');
    $source_image->Border(geometry => '1x1', color => 'gray');

    $source_image->Set(type => 'grayscale');

    return $source_image;
}

