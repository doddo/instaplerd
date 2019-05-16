use strict;
use warnings;
use Test::More 0.98;

use FindBin;

use lib "$FindBin::Bin/../lib";


use_ok $_ for qw(
    Tuvix::InstaPlugin
    Tuvix::InstaPlugin::Post
    Tuvix::InstaPlugin::ExifHelper
    Tuvix::InstaPlugin::TitleGenerator
    Tuvix::InstaPlugin::Filter
    Tuvix::InstaPlugin::Filters::Artistic
    Tuvix::InstaPlugin::Util
    );
    
done_testing;

