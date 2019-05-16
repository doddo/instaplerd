package Tuvix::InstaPlugin;
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

Tuvix::InstaPlugin - Extend Tuvix (and maybe Plerd in the future) with photoblog support

=head1 SYNOPSIS

    use Tuvix::InstaPlugin::Post;

=head1 DESCRIPTION

This is some sort of pluin for L<Tuvix|https://github.com/doddo/tuvix> which enables jpeg files as source files. It will apply some various filters and the like, crop, scale and make it into an Plerd::Post.

It does not currently work with Plerd because it does not have extension support yet,.


=head1 LICENSE

Copyright (C) Petter H

This library is released under the MIT license. The Flag icons are from  L<www.famfamfam.com|http://www.famfamfam.com/lab/icons/flags/>.
If enabled, The GEO lookup data resolved from the jpeg EXIF any processed images is L<© OpenStreetMap contributors|https://www.openstreetmap.org/copyright>.


=head1 AUTHOR

Petter H E<lt>dr.doddo@gmail.comE<gt>

=cut

