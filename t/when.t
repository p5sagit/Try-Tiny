#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

BEGIN {
  plan skip_all => "Perl 5.10 is required" unless eval 'use 5.010';
  plan tests => 5;
}

use Try::Tiny;

no if $] >= 5.017011, warnings => 'experimental::smartmatch';

my ( $foo, $bar, $other );

$_ = "magic";

try {
  die "foo";
} catch {

  like( $_, qr/foo/ );

  when (/bar/) { $bar++ };
  when (/foo/) { $foo++ };
  default { $other++ };
};

is( $_, "magic", '$_ not clobbered' );

ok( !$bar, "bar didn't match" );
ok( $foo, "foo matched" );
ok( !$other, "fallback didn't match" );
