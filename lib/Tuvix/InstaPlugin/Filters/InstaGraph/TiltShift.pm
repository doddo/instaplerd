package Tuvix::InstaPlugin::Filters::InstaGraph::TiltShift;
use strict;
use warnings FATAL => 'all';

use Moose;

extends "Tuvix::InstaPlugin::Filters::InstaGraph";

sub _apply {
    my $self = shift;

    $self->execute(
        "( $self->{_tmp_file} -gamma 0.75 -modulate 100,130 -contrast )
         ( +clone -sparse-color Barycentric '0,0 black 0,%h white' -function polynomial 4,-4,1 -level 0,50% )
        -compose blur -set option:compose:args 5 -composite
        $self->{_tmp_file}"
      );

    return $self->_load_tmp_file;
}


=pod

=encoding utf-8

=head1 NAME

Tuvix::InstaPlugin::Filters::InstaGraph::TiltShift

=head1 DESCRIPTION

This is an adaption of the L<InstaGraph|https://github.com/adineer/instagraph>,
"TiltShift" filter.

=cut

1;