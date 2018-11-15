package InstaPlerd::TitleGenerator;
use strict;
use warnings;
use Text::Sprintf::Named;
use v5.10;
use utf8;

use Moose;

has 'exif_helper' => (
        is  => 'ro',
        isa => 'InstaPlerd::ExifHelper',
        required => 1
    );

has 'season' => (
        is => 'rw',
        isa => 'Maybe[Str]',
        lazy_build => 1
);

has 'time_of_day' => (
        is => 'rw',
        isa => 'Maybe[Str]',
        lazy_build => 1
    );

has 'title_template_list' => (
        is => 'rw',
        isa => 'ArrayRef[Str]',
        default => sub {
            return [
                "%(superlative)s %(time_of_day)s %(location_with_random_precision)s",
                "%(superlative)s %(season)s %(time_of_day)s %(location_with_random_precision)s",
                "%(time_of_day)s %(location_with_random_precision)s",
                "%(season)s %(location_with_random_precision)s",
                "%(season)s %(location_with_random_precision)s",
                "%(season)s in the %(time_of_day)s %(location_with_random_precision)s",
            ];
        }
    );

has 'superlative_list' => (
        is => 'rw',
        isa => 'ArrayRef[Str]',
        default => sub {
            return [
                "A Great",
                "A Wonderful",
                "A Quite Decent",
                "An OK",
                "The Best",
            ];
        }
    );

sub location_with_random_precision {
    my $self = shift;
    my $geo = $self->exif_helper->geo_data();
    my @loc;

    if (defined $geo && defined $$geo{ location } && defined $$geo{ location }{ address }){
        my $address = $$geo{ location }{ address };
        foreach my $interesting_key (qw/in-country in-state in-county
            in-city in-suburb at-road at-postcode at-cafe in-town at-marina/) {
            (my $at_or_in, my $location) = split /-/, $interesting_key, 2; # Nice
            if (defined $$address{ $location } && length $$address{ $location }) {
                push @loc, sprintf"%s %s", $at_or_in, $$address{ $location };
            }
        }
    }
    return $loc[ rand @loc ];
}

sub fmt_hash {
    my $self = shift;
    return (
        superlative => ${$self->superlative_list()}[ rand @{$self->superlative_list()}],
        time_of_day => $self->_capitalise($self->time_of_day),
        location_with_random_precision => $self->location_with_random_precision(),
        season => $self->_capitalise($self->season)
    );
}

sub generate_title {
    my $self = shift;
    my $filename = shift;

    if ($filename =~ m/^(?:\d]{4,}|(?:img|dscf?|p|dcf)_?\d{3,})/i) {
        # Here is the camera default crap name, make a great one instead.
        return $self->_make_great_title || "An untitled picture";
    }
    return $self->_capitalise($filename);
}

sub _build_time_of_day {
    my $self = shift;

    my $h = $self->exif_helper->timestamp->hour;
    if ($h < 5){
        return 'late night'
    } elsif ($h < 9 ) {
        return 'early morning'
    } elsif ($h < 12 ) {
        return 'morning'
    } elsif ($h < 15 ) {
        return 'early afternoon'
    } elsif ($h < 17 ) {
        return 'afternoon'
    } elsif ($h < 22 ) {
        return 'evening'
    } else {
        return 'night'
    }
}

sub _build_season {
    my $self = shift;

    my $m = $self->exif_helper->timestamp->month;

    my $lat = ${$self->exif_helper->geo_data()}{ latitude } || 1;

    if ($m >= 3 && $m < 6) {
        # March 1 to May 31;
        return $lat > 0 ? 'spring': ('fall', 'autumn')[rand 2]
    } elsif ($m < 9){
        # June 1 to August 31
        return $lat > 0 ? 'summer':'winter'
    } elsif ($m < 12){
         # September 1 to November 30;
        return $lat > 0 ? ('fall', 'autumn')[rand 2]:'spring'
    } else {
        return $lat > 0 ? 'winter':'summer'
    }
}

sub _make_great_title {
    my $self = shift;
    my $title_fmt = ${$self->title_template_list}[ rand @{$self->title_template_list()} ];
    my $formatter = Text::Sprintf::Named->new(
        {fmt => $title_fmt}
    );
    my %fmt_hash = $self->fmt_hash;

    return $formatter->format({args => \%fmt_hash});
}

sub _capitalise {
    my $self = shift;
    $_ = lc (shift);
    s/\.jpe?g//;
    s/_/ /g;
    s/(?<=\b)(.)/\u$1/g;
    return $_;
}

1;