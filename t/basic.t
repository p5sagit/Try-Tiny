use strict;
use warnings;

use Test::More tests => 57;
use Try::Tiny;

sub _eval {
  local $@;
  local $Test::Builder::Level = $Test::Builder::Level + 2;
  return ( scalar(eval { $_[0]->(); 1 }), $@ );
}


sub lives_ok (&$) {
  my ( $code, $desc ) = @_;
  local $Test::Builder::Level = $Test::Builder::Level + 1;

  my ( $ok, $error ) = _eval($code);

  ok($ok, $desc );

  diag "error: $@" unless $ok;
}

sub throws_ok (&$$) {
  my ( $code, $regex, $desc ) = @_;
  local $Test::Builder::Level = $Test::Builder::Level + 1;

  my ( $ok, $error ) = _eval($code);

  if ( $ok ) {
    fail($desc);
  } else {
    like($error || '', $regex, $desc );
  }
}


my $prev;

lives_ok {
  try {
    die "foo";
  };
} "basic try";

throws_ok {
  try {
    die "foo";
  } catch { die $_ };
} qr/foo/, "rethrow";


{
  local $@ = "magic";
  is( try { 42 }, 42, "try block evaluated" );
  is( $@, "magic", '$@ untouched' );
}

{
  local $@ = "magic";
  is( try { die "foo" }, undef, "try block died" );
  is( $@, "magic", '$@ untouched' );
}

{
  local $@ = "magic";
  like( (try { die "foo" } catch { $_ }), qr/foo/, "catch block evaluated" );
  is( $@, "magic", '$@ untouched' );
}

is( scalar(try { "foo", "bar", "gorch" }), "gorch", "scalar context try" );
is_deeply( [ try {qw(foo bar gorch)} ], [qw(foo bar gorch)], "list context try" );

is( scalar(try { die } catch { "foo", "bar", "gorch" }), "gorch", "scalar context catch" );
is_deeply( [ try { die } catch {qw(foo bar gorch)} ], [qw(foo bar gorch)], "list context catch" );


{
  my ($sub) = catch { my $a = $_; };
  is(ref($sub), 'Try::Tiny::Catch', 'Checking catch subroutine scalar reference is correctly blessed');
}

{
  my ($sub) = finally { my $a = $_; };
  is(ref($sub), 'Try::Tiny::Finally', 'Checking finally subroutine scalar reference is correctly blessed');
}

lives_ok {
  try {
    die "foo";
  } catch {
    my $err = shift;

    try {
      like $err, qr/foo/;
    } catch {
      fail("shouldn't happen");
    };

    pass "got here";
  }
} "try in try catch block";

throws_ok {
  try {
    die "foo";
  } catch {
    my $err = shift;

    try { } catch { };

    die "rethrowing $err";
  }
} qr/rethrowing foo/, "rethrow with try in catch block";


sub Evil::DESTROY {
  eval { "oh noes" };
}

sub Evil::new { bless { }, $_[0] }

{
  local $@ = "magic";
  local $_ = "other magic";

  try {
    my $object = Evil->new;
    die "foo";
  } catch {
    pass("catch invoked");
    like($_, qr/foo/, 'error message is correct');
  };

  is( $@, "magic", '$@ untouched' );
  is( $_, "other magic", '$_ untouched' );
}

{
  my ( $caught, $prev );

  {
    local $@;

    eval { die "bar\n" };

    is( $@, "bar\n", 'previous value of $@' );

    try {
      die {
        prev => $@,
      }
    } catch {
      $caught = $_;
      $prev = $@;
    }
  }

  is_deeply( $caught, { prev => "bar\n" }, 'previous value of $@ available for capture' );
  is( $prev, "bar\n", 'previous value of $@ also available in catch block' );
}

{
  local $@ = "magic";
  local $_ = "other magic";

  try {
    local $@;
    die "foo";
  } catch {
    pass("catch invoked");
    like($_, qr/foo/, 'error message is correct even after $@ was localized');
  };

  is( $@, "magic", '$@ untouched' );
  is( $_, "other magic", '$_ untouched' );
}

sub Evil2::DESTROY { eval { die "oh noes" } }
sub Evil2::new { bless { }, $_[0] }

{
  local $@ = "magic";
  local $_ = "other magic";

  try {
    my $object = Evil2->new;
    die "foo";
  } catch {
    pass("catch invoked");
    like($_, qr/foo/, 'error message is correct');
  };

  is( $@, "magic", '$@ untouched' );
  is( $_, "other magic", '$_ untouched' );
}

sub Evil3::DESTROY { $@ = "oh noes" }
sub Evil3::new { bless { }, $_[0] }

{
  local $@ = "magic";
  local $_ = "other magic";

  try {
    my $object = Evil3->new;
    die "foo";
  } catch {
    pass("catch invoked");
    like($_, qr/foo/, 'error message is correct');
  };

  is( $@, "magic", '$@ untouched' );
  is( $_, "other magic", '$_ untouched' );
}

sub Evil4::DESTROY { eval { "oh noes" } }
sub Evil4::new { bless { }, $_[0] }

{
  local $@ = "magic";
  local $_ = "other magic";

  try {
    for (Evil4->new) {
      die "foo";
    }
  } catch {
    pass("catch invoked");
    like($_, qr/foo/, 'error message is correct');
  };

  is( $@, "magic", '$@ untouched' );
  is( $_, "other magic", '$_ untouched' );
}

{
  local $SIG{__DIE__} = sub { die "modified $_[0]" };

  local $@ = "magic";
  local $_ = "other magic";

  try {
    die "foo";
  } catch {
    pass("catch invoked");
    like($_, qr/modified foo/, 'error message is correct even after $SIG{__DIE__} was used');
  };

  is( $@, "magic", '$@ untouched' );
  is( $_, "other magic", '$_ untouched' );
}

{
  local $SIG{__DIE__} = sub { die "modified $_[0]" };

  local $@ = "magic";
  local $_ = "other magic";

  try {
    local $@;
    die "foo";
  } catch {
    pass("catch invoked");
    like($_, qr/modified foo/, 'error message is correct even after $SIG{__DIE__} was used and $@ was localized');
  };

  is( $@, "magic", '$@ untouched' );
  is( $_, "other magic", '$_ untouched' );
}

{
  local $SIG{__DIE__} = sub { die bless { error => $_[0] }, 'Object' };

  local $@ = "magic";
  local $_ = "other magic";

  try {
    die "foo";
  } catch {
    pass("catch invoked");
    isa_ok($_, 'Object', 'object exception is correct');
  };

  is( $@, "magic", '$@ untouched' );
  is( $_, "other magic", '$_ untouched' );
}

{
  local $SIG{__DIE__} = sub { die bless { error => $_[0] }, 'Object' };

  local $@ = "magic";
  local $_ = "other magic";

  try {
    local $@;
    die "foo";
  } catch {
    pass("catch invoked");
    isa_ok($_, 'Object', 'object exception is correct even after $@ was localized');
  };

  is( $@, "magic", '$@ untouched' );
  is( $_, "other magic", '$_ untouched' );
}
