#!/usr/bin/perl
use strict;
use warnings;
use feature qw/say/;
use utf8;
use v5.22;
use Getopt::Long qw/GetOptions/;
use File::Basename qw/basename/;
use File::Path qw(mkpath);
use File::Spec;
use Path::Class;
use Pod::Usage qw/pod2usage/;
use Module::Load;
use Image::Magick;
use Text::MultiMarkdown 'markdown';

my $width = 300;
my $height = 300;
my $cols;
my @filters;

my $help = 0;
my $man = 0;
my $output_format = 'md';
my $output_dir = "filterdemo";

GetOptions("width=i"  => \$width,
    "height=i"        => \$height,
    "cols=i"          => \$cols,
    "output-format=s" => \$output_format,
    "output-dir=s"    => \$output_dir,
    "filters=s"       => \@filters,
    "help=i"          => \$help,
    "man"             => \$man
) or pod2usage(-exitval => 2, -verbose => 1);

pod2usage(-exitval => 0, -verbose => 1) if $help;
pod2usage(-exitval => 0, -verbose => 2) if $man;
die "illegal output format.\n" unless ($output_format =~ m/^(:?html?|md|markdown)$/i);

my $img_dir = 'images';
push @filters, qw/Nofilter Artistic ArtisticGrayScale Nelville Batman Pi/ unless @filters;

$cols ||= @filters < 10 ? @filters : 3;

mkpath($output_dir);
mkpath(File::Spec->catdir($output_dir, $img_dir));


# Load alla filters
load 'InstaPlerd::Filters::' . $_ for (@filters);

my @generated_files;


sub crop_and_scale {
    my $image = shift;
    # fix rotation if need be
    $image->AutoOrient();
    my ($theight, $twidth) = $image->Get('height', 'width');
    $image->Resize(
        'gravity'  => 'Center',
        'geometry' =>
            $theight / $height < $twidth / $width
                ? sprintf 'x%i', $height
                : sprintf '%ix', $width
    );
    $image->Crop(
        'gravity'  => 'Center',
        'geometry' => sprintf("%ix%i", $width, $height),
    );
    $image->Strip();
    return $image;
}

sub do_stuff {
    my $file = shift;
    my $image = shift;
    my @generated_objects;
    foreach my $f (@filters) {
        my $filter = "InstaPlerd::Filters::${f}"->new();

        my $dst_image = $filter->apply($image->Clone());
        my $img_filename = sprintf "%s_%sx%s_%s", $f, $height, $width, $file->basename;
        $dst_image->write(File::Spec->catfile($output_dir, $img_dir, $img_filename));
        push @generated_objects, $img_filename;
    }
    return @generated_objects;
}

sub create_md {
    my @generated_objects = @_;
    my @filters_used;
    my $i = 0;
    my $body;

    my $filters_are_headlines = (@generated_objects % $cols == 0 && $cols == @filters)
        ? 1
        : 0;

    if ($filters_are_headlines) {
        $body .= "| $_" for @filters;
    }
    else {
        $body .= "|  " x $cols;
    }

    $body .= "\n|";
    $body .= " --- |" x $cols;
    $body .= "\n";

    foreach my $generaded_object (@generated_objects) {
        $i++;
        my $filter_name = (split("_", $generaded_object))[0];

        $body .= sprintf '| ![img alt](%s "%s") ', File::Spec->catfile($img_dir, $generaded_object), $filter_name;
        push(@filters_used, $filter_name) unless $filters_are_headlines;
        if ($i % $cols == 0) {
            $body .= "|\n";
            unless ($filters_are_headlines) {
                while (my $f = shift @filters_used) {
                    $body .= "| ${f} ";
                }
                $body .= "|\n";
            }
        }
    }
    if (@generated_objects % $cols != 0) {
        for (my $i = @generated_objects; $i % $cols != 0; $i++) {
            $body += "| ";
            push @filters_used, "-";
        }
        while (my $f = shift @filters_used) {
            unless ($filters_are_headlines) {
                $body .= "| ${f}";
            }
        }
        $body .= "|\n";
    }

    return $body;
}


while (<@ARGV>) {

    printf "\nProcessing [%-s]:\n", basename($_);
    if (!-e || !m/\.jpe?g$/i) {
        warn "No good file $_\n";
        next;
    }
    my $src_file = file($_);
    my $img = Image::Magick->new();
    $img->read("$src_file");
    push @generated_files, do_stuff($src_file, crop_and_scale($img));
}

my $body = create_md(@generated_files);
my $out_file;

if ($output_format =~ m/html?/i) {
    $out_file = "instaplerd_demo.$&";

    $body = '<html><head><title>InstaPlerd Filter demo</title></head><body>' .
        markdown($body) . '</body></html>';
}
else {
    $out_file = 'instaplerd_demo.md'
}

my $dst_file = file(File::Spec->catfile($output_dir, $out_file));
$dst_file->spew(iomode => '>:encoding(utf8)', $body);

say "Great success, go have a look at $dst_file!!";


__END__
=encoding utf-8

=head1 NAME

Render images using filters for demostrative purposes.

=head1 SYNOPSIS

instaplerd_filter_demo.pl [option ...] FILE ... [FILE ...]

 Options:

   --width WIDTH                     Width of sample image
   --height HEIGHT                   Height of sample image
   --cols   COLS                     columns per row of images
   --output-format  [html | md]      Output format, either html or markdown
   --output-dir OUTPUT_DIR           Output directory for the rendered pictures and associated files.
   --filters FILTER                  filter to use, can be used multiple times to specify multiple filters.
                                     Defaults to all filters.
   --help                            Brief help message
   --man                             read embedded man page

=head1 OPTIONS

=over 4

=item B<--width WIDTH>

Width to set the pictures to. Defaults to 300

=item B<--heigth HEIGHT>

Height to set the pictures to. Defaults to 300

=item B<--cols COLS>

Amount of columns to use, defaults to amount of specified filters if less than 10, else 3

=item B<--output-format [html|md]>

Specify output format to use Either html or markdown (md). Defaults to md.

=item B<--output-dir [html|md]>

Specify what output dir to put the resulting images and file. Defaults to 'filterdemo'

=item B<--help>

Print a brief help message and exits.

=item B<--man>

Red the embedded man page



=back

=head1 DESCRIPTION

B<instaplerd_filter_demo.pl> is used to generate a filter demo by applying InstaPlerd filters on the specified FILEs

=head1 EXAMPLES

=over 4

=item B<generate nice html demo>

instaplerd_filter_demo.pl --output-dir /tmp/testabs  --output-format html IMG_20181105_215107.jpg IMG_20181113_123627.jpg IMG_20181115_184251.jpg

=back

=cut
