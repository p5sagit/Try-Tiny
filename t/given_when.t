use strict;
use warnings;

use Test::More;

BEGIN {
  plan skip_all => 'Perl 5.010 is required' unless "$]" >= '5.010';
  plan skip_all => 'Tests skipped on perl 5.27.{7,8,9} when smartmatch behaviour changed' if "$]" >= '5.027007' and "$]" < '5.027010';
  plan skip_all => 'given/when have been removed in perl 5.42' if "$]" >= '5.041003';
  plan tests => 2;
}

use Try::Tiny;

use 5.010;
no if "$]" >= 5.017011, warnings => 'experimental::smartmatch';

my ( $error, $topic );

given ("foo") {
  when (qr/./) {
    try {
      die "blah\n";
    } catch {
      $topic = $_;
      $error = $_[0];
    }
  };
}

is( $error, "blah\n", "error caught" );

{
  local $TODO = "perhaps a workaround can be found"
    if "$]" < 5.017003;
  is( $topic, $error, 'error is also in $_' );
}

# ex: set sw=4 et:
