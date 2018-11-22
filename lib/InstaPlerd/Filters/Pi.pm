package InstaPlerd::Filters::Pi;

use strict;
use warnings FATAL => 'all';

use Moose;

extends "InstaPlerd::Filter";

sub _apply {
    my $self = shift;
    my $source_image = shift;


    $source_image->Modulate(brightness => 110, saturation => 60, hue => 80);
    #$source_image->ContrastStretch('33%');
    $source_image->Colorspace(colorspace => 'Gray');

    my $specs = $source_image->Clone();
    $specs->ContrastStretch('40%');
    $specs->AddNoise("Laplacian");

    $source_image->AutoGamma;
    $source_image->Composite(compose => 'Overlay', image=>$specs, opacity=>'40%');

    return $source_image;
}


1;