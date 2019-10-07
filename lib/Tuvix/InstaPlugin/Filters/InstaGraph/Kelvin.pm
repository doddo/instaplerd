package Tuvix::InstaPlugin::Filters::InstaGraph::Kelvin;
use strict;
use warnings FATAL => 'all';

use Moose;

extends "Tuvix::InstaPlugin::Filters::InstaGraph";

sub _apply {
    my $self = shift;
    my ($width, $height) = $self->_load_tmp_file->Get('width', 'height');

    $self->execute("
        ( $self->{_tmp_file} -auto-gamma -modulate 120,50,100 )
        ( -size ${width},${height} -fill rgba(255,153,0,0.5) -draw 'rectangle 0,0 ${width},${height}' )
        -compose multiply
        $self->{_tmp_file}");
    #$this->frame('Assets/Frames/Kelvin');

    return $self->add_frame($self->_load_tmp_file());
}

=pod

=encoding utf-8

=head1 NAME

Tuvix::InstaPlugin::Filters::InstaGraph::Kelvin

=head1 DESCRIPTION

This is an adaption of the L<InstaGraph|https://github.com/adineer/instagraph>,
"Kelvin" filter.

=cut


1;