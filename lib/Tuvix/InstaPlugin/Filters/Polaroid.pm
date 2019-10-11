package Tuvix::InstaPlugin::Filters::Polaroid;
use strict;
use warnings FATAL => 'all';

use Moose;

extends "Tuvix::InstaPlugin::Filter";

sub _apply {
    my $self = shift;
    my $source_image = shift;

    my $angle = rand(6) - 3;

    # TODO: add caption=
    $source_image->Polaroid(angle=>$angle, gravity=>'center', background=>'gray');
    # TODO: remove when introducing png support !!
    $source_image->Set(background=>'white', alpha=>'remove', alpha=>'off' );

    $source_image->Resize(width=>$self->width, height => $self->height);

    return $source_image;
}


1;