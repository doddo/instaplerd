package InstaPlerd::Filter;
use strict;
use warnings FATAL => 'all';

use Moose;

has restrictions => (
        is => 'ro',
        isa => 'HashRef[Array]',
        lazy_build => 1
    );

sub apply {
    my $self = shift;
    my $image = shift;
    return $self->_apply($image);
}

sub _apply {
    my $self = shift;
    my $image = shift;

}

sub _build_restrictions {
    return {};
}

1;