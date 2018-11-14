use strict;
use warnings;
use Test::More 0.98;


use_ok $_ for qw(
    InstaPlerd
    InstaPlerd::Post
    InstaPlerd::ExifHelper
    InstaPlerd::TitleGenerator
    InstaPlerd::Filter
    InstaPlerd::Filters::Artistic
    InstaPlerd::Util
    );

done_testing;

