package InstaPlerd::Filters::Batman;
use InstaPlerd::Filter;

use strict;
use warnings FATAL => 'all';

use Moose;


extends "InstaPlerd::Filter";

sub _apply{

    my $self = shift;
    my $source_image = shift;

    $source_image->Modulate(brightness => 110, saturation => 60, hue => 110);
    $source_image->Gamma(0.8);
    $source_image->Colorize(fill => '#222b6d', blend=> '20' );

    $source_image->Contrast(sharpen=>'True');
    $source_image->Contrast(sharpen=>'True');

    $source_image->Shave(geometry => '20x20');
    $source_image->Border(geometry => '20x20', color => 'black');

    return $source_image;
}

sub _build_restrictions {
    return (
        brightness => qw/LightValue > 0.8/
    );
}

1;