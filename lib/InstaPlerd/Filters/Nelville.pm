package InstaPlerd::Filters::Nelville;
use strict;
use warnings FATAL => 'all';
use InstaPlerd::Filter;

use Moose;

extends "InstaPlerd::Filter";

sub _apply {
    my $self = shift;
    my $source_image = shift;
    $source_image->Colorspace(colorspace => 'RGB');
    my $blue = $source_image->Clone();
    my $beige = $source_image->Clone();

    my $gray = $blue->Clone();
    $gray->Colorspace(colorspace => 'Gray');

    $blue->Colorize(fill => '#222b6d', blend => "100%"); # BLUE
    $blue->Composite(compose => 'Blend', image => $gray);

    undef $gray;

    $gray = $beige->Clone();
    $gray->Colorspace(colorspace => 'Gray');
    $gray->Negate();
    $beige->Colorize(fill => '#f7daae', blend => "100%"); # Beige

    $beige->Composite(compose => 'Blend', image => $gray);
    $beige->Composite(compose => 'Multiply', image => $blue);
    $source_image->Set("compose:args", "55");
    $source_image->Composite(compose => 'Blend', image => $beige);

    $source_image->Modulate(100, 150, 100);
    $source_image->AutoGamma;

    return $self->add_frame($source_image, '100%');
}

1;