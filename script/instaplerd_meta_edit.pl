#!/usr/bin/perl
use strict;
use warnings;
use feature qw/say/;
use InstaPlerd::Util;
use utf8;
use v5.22;
use Getopt::Long qw/GetOptions/;
use File::Basename qw/basename/;
use Pod::Usage qw/pod2usage/;

my @deltags;
my $list;
my $util = InstaPlerd::Util->new;
my $clear = 0;
my $jsondump = 0;
my $help = 0;
my $man = 0;
my $verbose = 0;
my $grep;

GetOptions("list" => \$list,
    "help"        => \$help,
    "man"         => \$man,
    "clear"       => \$clear,
    "grep=s"      => \$grep,
    "verbose"     => \$verbose,
    "jsondump"    => \$jsondump,
    "deltag=s"    => \@deltags)
    or pod2usage(-exitval => 2, -verbose => 1);

pod2usage(-exitval => 0, -verbose => 1) if $help;
pod2usage(-exitval => 0, -verbose => 2) if $man;

my $stream = $jsondump || $grep ? \*STDERR : \*STDOUT;

my $filename;
while ($filename = <@ARGV>) {

    printf $stream "\nProcessing [%-s]:\n", basename($filename) if $verbose;
    if (!-e $filename || $filename !~ m/\.jpe?g$/i) {
        warn "No good file $filename\n";
    }
    elsif ($jsondump) {
        die "can't use clear in combination with 'deltag' or 'grep' ...\n"
            if (@deltags || $grep);
        say $util->encode($util->load_image_meta($filename));
    }
    elsif ($clear) {
        die "can't use clear in combination with 'list', 'grep' or 'deltag' ...\n"
            if ($list || @deltags || $grep);
        say "Deleting all InstaPlerd meta...";
        $util->save_image_meta($filename, {});
    }
    else {
        my $meta = $util->load_image_meta($filename);
        if (do_stuff($filename, $meta)) {
            if (!$grep) {
                my $rval = $util->save_image_meta($filename, $meta);
                if ($rval == 2) {
                    say "No Changes Made to $filename.";
                }
                else {
                    say "Saving changes to $filename.";
                }
            }
        }
    }
}

sub maybe_print(@) {
    if ($grep) {
        my $candidate = shift;
        my $grep = qr{$grep}i;
        say $filename . ':' . $candidate  =~ s/^\s+//r if ($candidate =~ $grep);
    }
    else {
        printf shift;
    }
}

sub do_stuff {
    my $file = shift;
    my $meta = shift;
    my $indent = shift || 20;
    my $item = shift || "";
    my $change = 0;

    foreach my $key (sort {$a cmp $b} keys %{$meta}) {
        my $rel_key = $item eq "" ? $key : "$item.$key";

        if (grep /^\Q$key$/, @deltags) {
            maybe_print sprintf "%${indent}s - %-s\n", $rel_key, "*** DELETED ***";
            delete($$meta{$key});
            $change++;
        }
        else {
            if (ref $$meta{$key} eq 'HASH') {
                maybe_print sprintf "%${indent}s = {\n", $rel_key;
                $change += do_stuff($file, $$meta{$key}, $indent + 20, $rel_key);
                maybe_print sprintf "    %${indent}s\n", "}";
            }
            elsif (ref $$meta{$key} eq 'ARRAY') {
                maybe_print sprintf "%${indent}s = [%-s]\n", $rel_key, join(', ', @{$$meta{$key}});
            }
            else {
                maybe_print sprintf "%${indent}s = '%-s'\n", $rel_key, $$meta{$key};
            }
        }
    }
    return $change;
}

__END__
=encoding utf-8

=head1 NAME

instaplerd_meta_edit.pl - Tamper with a jpeg files InstaPlerd metadata (hidden in the "comment" field...)

=head1 SYNOPSIS

instaplerd_meta_edit.pl [option ...] [file ...]

 Options:
   --help            brief help message
   --man             read embedded man page
   --list            list InstaPlerd meta from file(s)
   --clear           swipe away InstaPlerd meta from file(s)
   --grep MATCH      Find file matching tag in file
   --deltag TAG      Delete InstaPlerd meta with [tag] from file(s)
   --jsondump        Dump InstaPlerd meta from file(s) in JSON format

=head1 OPTIONS

=over 4

=item B<--help>

Print a brief help message and exits.

=item B<--man>

Read the embedded man page

=item B<--list>

list InstaPlerd meta from file(s)

=item B<--clear>

Swipe away InstaPlerd meta from file by setting the comment to an empty json {}

=item B<--grep>

Find metadata which matches case insensitive regex "MATCH" in files, and print the file names and matching attr.

=item B<--deltag>

Remove any given tag from the InstaPlerd meta in the file. Can be specified multiple times to specify multiple tags.

=item B<--jsondump>

Dump InstaPlerd metadata from file(s) in JSON format to STDOUT

=back

=head1 DESCRIPTION

B<instaplerd_meta_edit.pl> is used to tamper or displaty the InstaPlerd metadata stored in the jpeg files exif
 comment field.

=head1 EXAMPLES

=over 4

=item B<remove checksum> is useful to trigger a republication of image on next plerdall run.

instaplerd_meta_edit.pl --deltag checksum a_test_image1.jpg a_test_image1.jpg

=item B<list metadata> list what stored InstaPlerd data is stored.

instaplerd_meta_edit.pl  a_test_image.jpg


=back

=cut
