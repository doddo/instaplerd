package Tuvix::InstaPlugin::Filters::InstaGraph::Gotham;
use strict;
use warnings FATAL => 'all';

use Moose;

extends "Tuvix::InstaPlugin::Filters::InstaGraph";

sub _apply {
    my $self = shift;

    $self->execute(sprintf(
        "%s -modulate 120,10,100 -fill #222b6d -colorize 20 -gamma 0.5 -contrast -contrast %s->_tmp",
        $self->_tmp_file, $self->_tmp_file));

    return $self->add_border($self->_load_tmp_file);
}

=pod

=encoding utf-8

=head1 NAME

Tuvix::InstaPlugin::Filters::InstaGraph::Gotham

=head1 DESCRIPTION

This is an adaption of the L<InstaGraph|https://github.com/adineer/instagraph>,
"Gotham" filter.

=cut

1;