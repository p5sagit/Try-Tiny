use strict;
use warnings;

use Test::More tests => 35;
use Try::Tiny;

try {
  my $a = 1+1;
} catch {
  fail('Cannot go into catch block because we did not throw an exception')
} finally {
  pass('Moved into finally from try');
};

try {
  die('Die');
} catch {
  ok($_ =~ /Die/, 'Error text as expected');
  pass('Into catch block as we died in try');
} finally {
  pass('Moved into finally from catch');
};

try {
  die('Die');
} finally {
  pass('Moved into finally from catch');
} catch {
  ok($_ =~ /Die/, 'Error text as expected');
};

try {
  die('Die');
} finally {
  pass('Moved into finally block when try throws an exception and we have no catch block');
};

try {
  die('Die');
} finally {
  pass('First finally clause run');
} finally {
  pass('Second finally clause run');
};

try {
  # do not die
} finally {
  if (@_) {
    fail("errors reported: @_");
  } else {
    pass("no error reported") ;
  }
};

try {
  die("Die\n");
} finally {
  is_deeply(\@_, [ "Die\n" ], "finally got passed the exception");
};

try {
  try {
    die "foo";
  }
  catch {
    die "bar";
  }
  finally {
    pass("finally called");
  };
};

$_ = "foo";
try {
  is($_, "foo", "not localized in try");
}
catch {
}
finally {
  is(scalar(@_), 0, "nothing in \@_ (finally)");
  is($_, "foo", "\$_ not localized (finally)");
};
is($_, "foo", "same afterwards");

$_ = "foo";
try {
  is($_, "foo", "not localized in try");
  die "bar\n";
}
catch {
  is($_[0], "bar\n", "error in \@_ (catch)");
  is($_, "bar\n", "error in \$_ (catch)");
}
finally {
  is(scalar(@_), 1, "error in \@_ (finally)");
  is($_[0], "bar\n", "error in \@_ (finally)");
  is($_, "foo", "\$_ not localized (finally)");
};
is($_, "foo", "same afterwards");

{
  my @warnings;
  local $SIG{__WARN__} = sub {
    $_[0] =~ /\QExecution of finally() block CODE(0x\E.+\Q) resulted in an exception/
      ? push @warnings, @_
      : warn @_
  };

  my $error;
  my @order;
  try {
    try {
      push @order, 1;
      pass('try called');
      die 'trying';
    } finally {
      push @order, 2;
      pass('fin 1 called');
      die 'fin 1'
    } finally {
      push @order, 3;
      pass('fin 2 called')
    } finally {
      push @order, 4;
      pass('fin 3 called');
      die 'fin 3';
    };
  } catch {
    $error = $_;
  };

  is( "@order", '1 4 3 2', 'try and finally blocks were called in correct order');

  # If Scope::Cleanup is available then exception from the last block would be propagated
  if (eval { require Scope::Cleanup; Scope::Cleanup->import('establish_cleanup'); 1; }) {
    is( scalar @warnings, 0, 'no warnings from fatal finally blocks (Scope::Cleanup is available)' ) or diag("warnings:\n" . join "\n", @warnings);
    like $error, qr/^fin 1 at /, 'Exception from the first finally block was propagated (Scope::Cleanup is available)';
    pass 'dummy test to fill plan (Scope::Cleanup is available)';
    pass 'dummy test to fill plan (Scope::Cleanup is available)';
  } else {
    is( scalar @warnings, 2, 'warnings from both fatal finally blocks (Scope::Cleanup is not available)' );

    my @originals = sort map { $_ =~ /Original exception text follows:\n\n(.+)/s } @warnings;

    like $originals[0], qr/^fin 1 at /, 'First warning contains original exception (Scope::Cleanup is not available)';
    like $originals[1], qr/^fin 3 at /, 'Second warning contains original exception (Scope::Cleanup is not available)';
    is $error, undef, 'No exception was propagated  (Scope::Cleanup is not available)';
  }

}

{
  my $finally;
  SKIP: {
    try {
      pass('before skip in try');
      skip 'whee', 1;
      fail('not reached');
    } finally {
      $finally = 1;
    };
  }
  ok $finally, 'finally ran';
}
