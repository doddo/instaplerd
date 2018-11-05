package InstaPlerd::Filters::Artistic;
use InstaPlerd::Filter;

use strict;
use warnings FATAL => 'all';

use Moose;
use Carp;

extends "InstaPlerd::Filter";

sub apply {
    my $self = shift;
    my $source_image = shift;

    $source_image->Modulate(brightness=>110,saturation=>110,hue=>110);
    $source_image->Label('Border');
    $source_image->Shave(geometry=>'11x11');
    $source_image->Border(geometry=>'1x1',color=>'gray');
    $source_image->Border(geometry=>'10x10',color=>'light gray');
    $source_image->Set(type=>'grayscale');

}

