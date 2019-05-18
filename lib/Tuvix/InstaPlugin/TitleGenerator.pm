package Tuvix::InstaPlugin::TitleGenerator;
use strict;
use warnings;
use Text::Sprintf::Named;
use v5.10;
use utf8;

use Moose;

has 'exif_helper' => (
    is       => 'ro',
    isa      => 'Tuvix::InstaPlugin::ExifHelper',
    required => 1
);

has 'season' => (
    is         => 'rw',
    isa        => 'Maybe[Str]',
    lazy_build => 1
);

has 'time_of_day' => (
    is         => 'rw',
    isa        => 'Maybe[Str]',
    lazy_build => 1
);

has 'title_template_list' => (
    is      => 'rw',
    isa     => 'ArrayRef[Str]',
    default => sub {
        return [
            "%(concept)s %(time_of_day)s %(location_with_random_precision)s",
            "%(concept)s %(time_of_day)s %(location_with_random_precision)s",
            "%(concept)s %(season)s %(location_with_random_precision)s",
            "%(concept)s %(season)s %(location_with_random_precision)s",
            "%(concept)s %(season)s %(time_of_day)s %(location_with_random_precision)s",

            "%(time_of_day)s %(location_with_random_precision)s",
            "%(time_of_day)s %(location_with_random_precision)s",
            "%(season)s %(location_with_random_precision)s",
            "%(season)s %(location_with_random_precision)s",
            "%(season)s %(time_of_day)s %(location_with_random_precision)s",
        ]}
);

has 'concepts' => (
    is => 'ro',
    isa=> 'HashRef[Str]',
    default => sub { {} },
);

sub get_weighted_concept {
    my $self = shift;
    my @concepts =
        sort { $self->concepts->{$b} <=> $self->concepts->{$a} }
            keys %{$self->concepts};

    my $i = rand @concepts;
    my $j = rand @concepts;

    return $concepts[ $i < $j ? $i : $j]
}

sub location_with_random_precision {
    my $self = shift;
    my $geo = $self->exif_helper->geo_data();
    my @interesting_keys_in = qw/country state county
        city suburb town road city_district/;
    my @uninteresting_keys = qw/house_number postcode country_code/;
    my @loc;
    my $special;

    if (defined $geo && defined $$geo{ address } && defined $$geo{ address }) {
        my $address = $$geo{ address };
        while (my ($key, $value) = each(%{$address})) {

            if (map {$key =~ $_ } @uninteresting_keys){
                next;
            }
            elsif (map {$key =~ $_ } @interesting_keys_in) {
                push @loc, [ 'in', $value ];
            }
            else {
                # Assume this key is something super special or something
                unshift @loc, [ 'at', $value ];
                $special++;
            }
        }
    }

    my @title;
    if ($special) {
        push @title, splice(@loc, rand $special, 1);

    }
    my $i = rand @loc;
    my $j = rand @loc;

    my @p;
    push @title, $i < $j ? $loc[$i] : $loc[$j];
    my $spec = $title[0][0];

    foreach my $t (@title) {
        push @p, $$t[-1];
    }

    return [ $spec, join(', ', @p) ]

}

sub fmt_hash {
    my $self = shift;

    my $location = $self->location_with_random_precision();
    if ($location) {
        $location = join(" ", @{$self->location_with_random_precision()})
    }

        # TODO: fix this
    return(
        concept                        => $self->get_weighted_concept =~ s/(?<=\b)(.)/\u$1/r || '',
        time_of_day                    => $self->_capitalise($self->time_of_day) || 'Unknown Time Of Day',
        location_with_random_precision => $location || 'Unknown Location',
        season                         => $self->_capitalise($self->season || '')
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

    unless ($self->exif_helper->timestamp) {
        return "unknown time of day";
    }
    my $h = $self->exif_helper->timestamp->hour;
    if ($h < 5) {
        return 'late night'
    }
    elsif ($h < 9) {
        return 'early morning'
    }
    elsif ($h < 12) {
        return 'morning'
    }
    elsif ($h < 15) {
        return 'early afternoon'
    }
    elsif ($h < 17) {
        return 'afternoon'
    }
    elsif ($h < 22) {
        return 'evening'
    }
    else {
        return 'night'
    }
}

sub _build_season {
    my $self = shift;
    my $m;
    my $lat;

    # TODO: Fix this
    eval {
        $m = $self->exif_helper->timestamp->month;
        $lat = ${$self->exif_helper->geo_data()}{ latitude } || 0;
        unless ($lat eq "North" || $lat eq "South") {
            if ($lat < 0) {
                $lat = "South";
            }
            else {
                $lat = "North";
            }
        }
    };
    return undef if $@;

    if ($m < 3) {
        return $lat eq 'North' ? 'winter' : 'summer'
    }
    elsif ($m < 6) {
        # March 1 to May 31;
        return $lat eq 'North' ? 'spring' : ('fall', 'autumn')[rand 2]
    }
    elsif ($m < 9) {
        # June 1 to August 31
        return $lat eq 'North' ? 'summer' : 'winter'
    }
    elsif ($m < 12) {
        # September 1 to November 30;
        return $lat eq 'North' ? ('fall', 'autumn')[rand 2] : 'spring'
    }
    else {
        return $lat eq 'North' ? 'winter' : 'summer'
    }
}

sub _make_great_title {
    my $self = shift;
    my $title_fmt = ${$self->title_template_list}[ rand @{$self->title_template_list()} ];
    my $formatter = Text::Sprintf::Named->new(
        { fmt => $title_fmt }
    );
    my %fmt_hash = $self->fmt_hash;

    my $title = $formatter->format({ args => \%fmt_hash });
    chomp($title);
    $title =~ s/^\s+|\s+$//g;

    return $title;
}

sub _capitalise {
    my $self = shift;
    $_ = lc(shift);
    s/\.jpe?g//;
    s/_/ /g;
    s/(?<=\b)(.)/\u$1/g;
    return $_;
}

1;