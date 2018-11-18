#!/usr/bin/perl
use strict;
use warnings;
use feature qw/say/;
use InstaPlerd::Util;
use utf8;
use v5.22;
use Getopt::Long;
use File::Basename qw/basename/;

my @deltags;
my $list;
my $util = InstaPlerd::Util->new;
my $length = 24;
my $clear = 0;

GetOptions ("length=i"  => \$length,
              "list"    => \$list,
              "clear"   => \$clear,
              "deltag=s"  => \@deltags)
or die("Error in command line arguments\n");

while (<@ARGV>) {
    printf "\nProcessing [%-s]:\n", basename($_);
    if ($clear) {
        die "can't use clear in combination with 'list', 'deltag' ...\n"
            if ($list || @deltags);
        say "Deleting all InstaPlerd meta...";
        $util->save_image_meta($_, {});
    }
    else {
        my $meta = $util->load_image_meta($_);
        if (do_stuff($_, $meta)) {
            $util->save_image_meta($_, $meta);
        }
    }
}

sub do_stuff {
    my $file = shift;
    my $meta = shift;
    my $indent = shift || 20;
    my $item = shift || "";
    my $change = 0;

    foreach my $key ( sort {$a cmp $b} keys %{$meta} ){
        my $rel_key = $item eq "" ? $key : "$item.$key";

        if ($key ~~ @deltags) {
            printf "%${indent}s - %-s\n",  $rel_key, "*** DELETED ***";
            delete ($$meta{$key});
            $change++;
        } else {
            if (ref $$meta{$key} eq 'HASH') {
                printf "%${indent}s = {\n", $rel_key;
                do_stuff($file, $$meta{$key}, $indent + 20, $rel_key);
                printf "    %${indent}s\n", "}";
            } elsif (ref $$meta{$key} eq 'ARRAY') {
                printf "%${indent}s = [%-s]\n",  $rel_key, join (', ', @{$$meta{$key}});
            } else {
               printf "%${indent}s = '%-s'\n",  $rel_key, $$meta{$key};
            }
        }
    }
    return $change;
}

