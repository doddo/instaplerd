package  InstaPlerd::Filters::Nelville;
use strict;
use warnings FATAL => 'all';
use InstaPlerd::Filter;

use Moose;

extends "InstaPlerd::Filter";

sub _apply {
    my $self = shift;
    my $source_image = shift;
    my $invert = $source_image->Clone();
    my $beige = $source_image->Clone();

    $invert->Colorspace(colorspace => 'Gray');
    $invert->Colorize(fill => '#222b6d', blend => '60%'); # BLUE
    $invert->Negate();
    $beige->Colorspace(colorspace => 'Gray');
    $beige->Colorize(fill => '#f7daae', blend=>"60%"); # Beige
    $beige->Colorspace(colorspace => 'RGB');


    $invert->Composite(compose => 'Overlay', image=>$beige, blend=>'100%');

    $source_image->Composite(compose => 'Overlay', image => $invert, blend=>'30%');
    $source_image->Modulate(100,150,100);
    $source_image->AutoGamma;

    return $self->add_frame($source_image, '100%');
}

1;