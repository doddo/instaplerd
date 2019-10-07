package Tuvix::InstaPlugin::Filters::InstaGraph::Toaster;
use strict;
use warnings FATAL => 'all';

use Moose;

extends "Tuvix::InstaPlugin::Filters::InstaGraph";

sub _apply  {
    my $self = shift;

    $self->colortone('#330000', 100, 0);
    $self->execute(
        sprintf "%s -modulate 150,80,100 -gamma 1.2 -contrast -contrast %s",
            $self->_tmp_file, $self->_tmp_file);

    $self->vignette('none', 'LavenderBlush3');
    $self->vignette('#ff9966', 'none');

    return $self->_load_tmp_file();
}

=pod

=encoding utf-8

=head1 NAME

Tuvix::InstaPlugin::Filters::InstaGraph::Toaster

=head1 DESCRIPTION

This is an adaption of the L<InstaGraph|https://github.com/adineer/instagraph>,
"Toaster" filter.

=cut

1;