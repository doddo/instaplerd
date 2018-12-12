package InstaPlerd;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.01";

use File::ShareDir qw(dist_dir);
use File::Which;

use vars qw(@ISA @EXPORT $ASSET_DIR);

@ISA = qw(Exporter);
@EXPORT = qw($ASSET_DIR);
$ASSET_DIR = dist_dir('InstaPlerd');

1;
__END__

=encoding utf-8

=head1 NAME

InstaPlerd - Extend Plerd with photoblog support

=head1 SYNOPSIS

    use InstaPlerd::Post;

=head1 DESCRIPTION

InstaPlerd is some sort of pluin for L<Plerd|https://github.com/jmacdotorg/plerd> which enables jpeg files as source files. It will apply some various filters and the like, crop, scale and make it into an Plerd::Post.

It does not currently work with Plerd because this is a work in progress.


=head1 LICENSE

Copyright (C) Petter H

This library is released under the MIT license. The Flag icons are from  L<www.famfamfam.com|http://www.famfamfam.com/lab/icons/flags/>.
If enabled, The GEO lookup data resolved from the jpeg EXIF any processed images is L<© OpenStreetMap contributors|https://www.openstreetmap.org/copyright>.


=head1 AUTHOR

Petter H E<lt>dr.doddo@gmail.comE<gt>

=cut

