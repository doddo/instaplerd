package Tuvix::InstaPlugin::Filters::InstaGraph;
use strict;
use warnings FATAL => 'all';
use POSIX;
use File::Temp qw/tempfile/;
use Tuvix::InstaPlugin qw/$ASSET_DIR/;
use Text::ParseWords;


use Mojo::Log;
use IPC::Run qw/run timeout/;

use v5.14;
use Moose;

extends "Tuvix::InstaPlugin::Filter";

around 'apply' => sub {
    my $orig = shift;
    my $self = shift;
    my $image = shift;

    my ($fh, $filename) = tempfile();
    binmode $fh;
    print $fh $image->ImageToBlob();
    close($fh);

    $self->log->info("Applying filter: " . $self->meta->name);

    $self->_tmp_file($filename);

    return $self->_apply($image);

};

has '_tmp_file' => (
    is  => 'rw',
    isa => 'Str'
);

has 'cmd' => (
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub {[ 'convert' ]}
);

has 'log' => (
    is      => 'rw',
    isa     => 'Mojo::Log',
    default => sub {Mojo::Log->new()}
);

sub colortone {
    my $self = shift;
    my $color = shift;
    my $level = shift;
    my $type = shift || 0;

    my $negate = $type == 0 ? '-negate' : '';

    $self->execute(sprintf "
        %s -set colorspace RGB
            ( -clone 0 -fill %s -colorize 100%% )
            ( -clone 0 -colorspace gray %s )
            -compose blend -define compose:args=%s,%s -composite
        %s
    ", $self->_tmp_file, $color, $negate, $level, 100 - $level, $self->_tmp_file
    );
}

sub vignette {
    my $self = shift;
    my $color_1 = shift || 'none';
    my $color_2 = shift || 'black';
    my $crop_factor = shift || 1.5;

    my ($width, $height) = $self->_load_tmp_file->Get('width', 'height');

    my $crop_x = floor($width * $crop_factor);
    my $crop_y = floor($height * $crop_factor);

    $self->execute(sprintf('( %s )
        (
            -size %sx%s radial-gradient:%s-%s
            -gravity center
            -crop %sx%s+0+0 +repage
        )
        -compose multiply -flatten
        %s', $self->_tmp_file, $crop_x, $crop_y, $color_1, $color_2, $width, $height, $self->_tmp_file));
}


sub execute() {
    my $self = shift;
    my $args = shift;
    $args =~ s/^\s+|\s+$//g;
    my @args;

    local $/ = undef;
    #@args = split(/\s+/, );


    @args = shellwords($args);

    #unshift(@args, qw|strace -o /tmp/strace.out -s 256 magick|);
    unshift(@args, @{$self->{cmd}});

    my $cmd = sprintf('"%s"', join '", "', @args);

    #my $cmd = join( ' ', @args);

    $self->log->debug(sprintf 'About to run [%s]', $cmd);

    run \@args, \my $in, \my $out, \my $err, timeout(10)
        or $self->log->error(sprintf ("Can't run [\"%s\"]: %s ", join(' ', @args), $?));

    $self->log->warn(sprintf 'Error running %s]: STDERR: %s.', $cmd, $err) if $err;
    $self->log->debug($out) if $out;

}


sub _load_tmp_file {
    my $self = shift;

    my $source_image = Image::Magick->new();
    $source_image->read($self->_tmp_file);

    return $source_image;
}

sub DEMOLISH {
    my $self = shift;
    unlink $self->_tmp_file if (-f $self->_tmp_file);
}

=pod

=encoding utf-8

=head1 NAME

Tuvix::InstaPlugin::Filters::InstaGraph

=head1 DESCRIPTION

This package provides base functionality for the L<InstaGraph|https://github.com/adineer/instagraph> based filters.

This package, 'Tuvix::InstaPlugin::Filters::InstaGraph', as well as any package extending it, have been adapted from
the L<InstaGraph|https://github.com/adineer/instagraph> project.

=head1 COPYRIGHT AND LICENSE

Instagraph is open-sourced software licensed under the MIT License. (c) Instagraph authors

This package is also open-sourced software licenced under the MIT Licence.


=cut


1;