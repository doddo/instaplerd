package InstaPlerd::Filter;
use strict;
use warnings FATAL => 'all';

use File::Spec;
use InstaPlerd qw/$ASSET_DIR/;

use Moose;

has restrictions => (
    is         => 'ro',
    isa        => 'HashRef[Array]',
    lazy_build => 1
);

has _frame => (
    is         => 'ro',
    isa        => 'Maybe[Image::Magick]',
    lazy_build => 1
);

has name => (
    is         => 'ro',
    isa        => 'Str',
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


sub add_frame {
    my $self = shift;
    my $image = shift;
    my $opacity = shift || '50%';

    if ($self->_frame) {
        my ($width, $height) = $image->Get('width', 'height');
        $self->_frame->Resize(
            'gravity'  => 'Center',
            'geometry' => sprintf "%ix%i", $width, $height);

        $self->_frame->Composite(
            compose => 'Overlay',
            image   => $image,
            blend   => '100%',
            opacity => $opacity);
    }
    return $self->_frame->Clone();
}

sub _build_name {
    my $self = shift;

    (my $name) = $self->meta->name =~ /::([A-Z][a-z0-9A-Z]+)$/;
    return $name;
}

sub _build_restrictions {
    return {};
}

sub _build__frame {
    my $self = shift;
    my $surface_file = File::Spec->catfile($ASSET_DIR, 'filters', sprintf 'border_%s.png', $self->name);

    if (-e $surface_file) {
        my $border = Image::Magick->new();
        $border->read($surface_file);
        return $border
    }
}


1;