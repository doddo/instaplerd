package InstaPlerd::Util;

use strict;
use warnings FATAL => 'all';
use Moose;
use Image::ExifTool qw(:Public);
use JSON;
use utf8;

use Carp qw\cluck\;

has 'json' => (
    is      => 'ro',
    isa     => 'JSON',
    default => sub {JSON->new->utf8->allow_nonref}
);

has 'exiftool' => (
    is      => 'ro',
    isa     => 'Image::ExifTool',
    default => sub {Image::ExifTool->new()}
);

sub decode {
    my $self = shift;
    my $meta = shift;
    $self->json->decode($meta);
}

sub encode {
    my $self = shift;
    my $meta = shift;
    $self->json->pretty->encode($meta);
}

sub load_image_meta {
    my $self = shift;
    my $image = shift;
    my $info = $self->exiftool->ImageInfo($image);

    return $self->decode($$info{ Comment });
}

sub save_image_meta {
    my $self = shift;
    my $image = shift;
    my $meta = shift;

    my $payload = $self->json->encode($meta);
    $self->exiftool->SetNewValue(Comment => $payload);
    my $rval = $self->exiftool->WriteInfo($image);
    unless ($rval){
        cluck (sprintf "Unable to write meta for %s: Error:[%s]",
            $image, $self->exiftool->GetValue('Error'));
    }
    return $rval;
}

1;