package Tuvix::InstaPlugin::Filters::Polaroid;
use strict;
use warnings FATAL => 'all';

use Moose;

extends "Tuvix::InstaPlugin::Filter";

sub _apply {
    my $self = shift;
    my $source_image = shift;

    my $angle = rand(6) - 3;

    $source_image->Set(magick => 'PNG');
#    $source_image->Set( alpha=>'on' );
    # TODO: add caption=
    $source_image->Polaroid(angle=>$angle, gravity=>'center', background=>'gray');

    $source_image->Resize(width=>$self->width, height => $self->height);

    return $source_image;
}


1;