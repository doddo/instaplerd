package InstaPlerd::Filters::ArtisticGrayScale;
use InstaPlerd::Filter;

use strict;
use warnings FATAL => 'all';

use Moose;
use Carp;

extends "InstaPlerd::Filters::Artistic";

around '_apply' => sub {
    my $orig = shift;
    my $self = shift;
    my $source_image = shift;

    $source_image->Set(type => 'grayscale');

    return self->$orig($source_image);
};

1;
