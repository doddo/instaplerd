package Tuvix::InstaPlugin::Filters::InstaGraph::Nashville;
use strict;
use warnings FATAL => 'all';

use Moose;

extends "Tuvix::InstaPlugin::Filters::InstaGraph";

sub _apply  {
    my $self = shift;

    $self->colortone('#222b6d', 100, 0);
    $self->colortone('#f7daae', 100, 1);
    $self->execute(sprintf("$self->{_tmp_file} -contrast -modulate 100,150,100 -auto-gamma $self->{_tmp_file}"));

    return $self->add_frame($self->_load_tmp_file());
}

=pod

=encoding utf-8

=head1 NAME

Tuvix::InstaPlugin::Filters::InstaGraph::Nashville

=head1 DESCRIPTION

This is an adaption of the L<InstaGraph|https://github.com/adineer/instagraph>,
"Nashville" filter.

=cut


1;