package InstaPlerd::Util;

use strict;
use warnings FATAL => 'all';
use Moose;
use JSON;
use Carp;
use utf8;

has 'json' => (
        is      => 'ro',
        isa     => 'JSON',
        default => sub {JSON->new->utf8->allow_nonref}
    );

sub load_image_meta {
    my $self = shift;
    my $image = shift;
    return $self->json->decode($image->get('comment'));
}

sub save_image_meta {
    my $self = shift;
    my $image = shift;
    my $meta = shift;

    my $payload = $self->json->encode($meta);

    $image->Set("comment" => $payload);

    return $image->ImageToBlob();
}

1;