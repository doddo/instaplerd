package Tuvix::InstaPlugin::Filters::InstaGraph::Lomo;
use strict;
use warnings FATAL => 'all';

use Moose;

extends "Tuvix::InstaPlugin::Filters::InstaGraph";

sub _apply {
    my $self = shift;

    $self->execute(
        sprintf("%s -channel R -level 33%% -channel G -level 33%% %s", $self->_tmp_file, $self->_tmp_file));
    $self->vignette();

    return $self->_load_tmp_file();
}


=pod

=encoding utf-8

=head1 NAME

Tuvix::InstaPlugin::Filters::InstaGraph::Lomo

=head1 DESCRIPTION

This is an adaption of the L<InstaGraph|https://github.com/adineer/instagraph>,
"Lomo" filter.

=cut


1;