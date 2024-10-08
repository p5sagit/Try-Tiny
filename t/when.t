use strict;
use warnings;

use Test::More;

BEGIN {
  plan skip_all => 'Perl 5.010 is required' unless "$]" >= '5.010';
  plan skip_all => 'Tests skipped on perl 5.27.{7,8,9} when smartmatch behaviour changed' if "$]" >= '5.027007' and "$]" < '5.027010';
  plan skip_all => 'given/when have been removed in perl 5.42' if "$]" >= '5.041003';
  plan tests => 5;
}

use Try::Tiny;

use 5.010;
no if "$]" >= 5.017011, warnings => 'experimental::smartmatch';

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
