#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use FindBin;

use lib "$FindBin::Bin/../lib";

use_ok('Tuvix::InstaPlugin::FilterLoader');

my $filter_loader = Tuvix::InstaPlugin::FilterLoader->new();

ok(my $filter = $filter_loader->filter(), 'can call filter');

isa_ok($filter, 'Tuvix::InstaPlugin::Filter');

ok(my $artistic_filter = $filter_loader->filter('NONEXISTANT FILTER'), 'can call nonexistent filter');

isa_ok($artistic_filter, 'Tuvix::InstaPlugin::Filters::Artistic');

done_testing();

