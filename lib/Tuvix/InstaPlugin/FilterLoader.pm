package Tuvix::InstaPlugin::FilterLoader;
use strict;
use warnings FATAL => 'all';

use Moose;
use Mojo::Log;

use Module::Load;
use Try::Tiny;

use Moose::Util::TypeConstraints;

subtype 'Filter'
    => as 'Tuvix::InstaPlugin::Filter'
    => where {$_->isa('Tuvix::InstaPlugin::Filter')}
    => message {"invalid filter $_ type provided"};

coerce 'Filter'
    => from 'Str'
    => via {load_filter($_)};

has 'filter' => (
    is         => 'rw',
    isa        => 'Filter',
    coerce     => 1,
    lazy_build => 1
);

has 'available_filters' => (
    isa     => 'ArrayRef[Str]',
    is      => 'rw',
    # Todo this can be done automatically, but would that be the right thing to do?
    default => sub {[
        'Tuvix::InstaPlugin::Filters::Artistic',
        'Tuvix::InstaPlugin::Filters::ArtisticGrayScale',
        'Tuvix::InstaPlugin::Filters::Batman',
        'Tuvix::InstaPlugin::Filters::Nofilter',
        'Tuvix::InstaPlugin::Filters::Pi',
        'Tuvix::InstaPlugin::Filters::Polaroid',
        'Tuvix::InstaPlugin::Filters::InstaGraph::Toaster',
        'Tuvix::InstaPlugin::Filters::InstaGraph::Lomo',
        'Tuvix::InstaPlugin::Filters::InstaGraph::TiltShift',
    ]}
);

sub _build_filter {
    my $self = shift;
    return $self->available_filters->[rand @{$self->available_filters}];
}

sub load_filter {
    my $filter_to_load = shift;
    my $filter_name;
    my $log = Mojo::Log->new(); # TODO fix at some point

    try {
        $filter_name = $filter_to_load =~ m/^Tuvix::InstaPlugin::/
            ? $filter_to_load
            : 'Tuvix::InstaPlugin::Filters::' . $filter_to_load;
        load $filter_name;
    }
    catch {
        my $err = shift || 'Unknown error';
        # jajaja
        $log->error("Unable to load filter $filter_to_load. Loading default (Artistic) instead, $err");
        $filter_name = 'Tuvix::InstaPlugin::Filters::Artistic';
        load $filter_name;
    };
    $log->info("Loaded $filter_name filter.");
    return $filter_name->new()
}

1;