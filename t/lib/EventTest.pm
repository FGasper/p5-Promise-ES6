package EventTest;

use strict;
use warnings;
use autodie;

use Test::More;
use Test::FailWarnings -allow_deps => 1;

use constant _TEST_COUNT => 8;

sub _FULL_BACKEND {
    return "Promise::ES6::" . $_[0]->_BACKEND();
}

sub run {
    my ($class) = @_;

    plan tests => _TEST_COUNT();

  SKIP: {
        eval { $class->_REQUIRE(); 1 } or skip "$class: Backend isn’t available: $@", _TEST_COUNT();

        $class->_REQUIRE_BACKEND();

        $class->_test_normal();
        $class->_test_die_in_constructor();
        $class->_test_resolve();
        $class->_test_reject();

        $class->_test_call_again_in_callback();
        $class->_test_die_in_then();
        $class->_test_die_in_catch();
        $class->_test_finally_after_rejection_rejects();
    }
}

sub _REQUIRE_BACKEND {
    my ($class) = @_;

    my $backend = $class->_BACKEND();
    require "Promise/ES6/$backend.pm";
}

sub _test_call_again_in_callback {
    my ($class) = @_;

    my @events;

    my $promise = $class->_FULL_BACKEND()->resolve(123123);

    my $promise_r = \$promise;

    my $big_promise = Promise::ES6->new( sub {
        my ($y, $n) = @_;

        $promise->then( sub {
            $$promise_r->then( sub { push @events, 1; $y->() } );

            push @events, 2;
        } );
    } );

    $class->_RESOLVE($big_promise);

    is( "@events", "2 1", 'then() from pre-resolved promise again' );
}

sub _test_normal {
    my ($class) = @_;

    my @things;

    my $promise = $class->_FULL_BACKEND()->new( sub {
        push @things, 'a';
        shift()->(123);
        push @things, 'b';
    } );

    push @things, 'c';

    $promise->then( sub { push @things, shift() } );

    push @things, 'e';

    $class->_RESOLVE($promise);

    push @things, 'f';

    is(
        "@things",
        'a b c e 123 f',
        'then() callback invoked asynchronously',
    );
}

sub _test_resolve {
    my ($class) = @_;

    my @things;

    my $promise = $class->_FULL_BACKEND()->resolve(123);

    push @things, 'c';

    $promise->then( sub { push @things, 'd' } );

    push @things, 'e';

    $class->_RESOLVE($promise);

    push @things, 'f';

    is(
        "@things",
        'c e d f',
        'then() callback invoked asynchronously',
    );
}

sub _test_reject {
    my ($class) = @_;

    my @things;

    my $promise = $class->_FULL_BACKEND()->reject(123);

    push @things, 'c';

    my $p2 = $promise->catch( sub { push @things, shift } );

    push @things, 'e';

    $class->_RESOLVE($p2);

    push @things, 'f';

    is(
        "@things",
        'c e 123 f',
        'catch() callback invoked asynchronously',
    );
}

sub _test_die_in_constructor {
    my ($class) = @_;

    my @things;

    my $promise = $class->_FULL_BACKEND()->new( sub {
        push @things, 'a';
        die "123\n";
        push @things, 'b';
    } );

    push @things, 'c';

    $promise = $promise->catch( sub { push @things, shift } );

    push @things, 'e';

    $class->_RESOLVE($promise);

    push @things, 'f';

    is(
        "@things",
        "a c e 123\n f",
        'catch() callback invoked asynchronously',
    );
}

sub _test_die_in_then {
    my ($class) = @_;

    my @things;

    my $promise = $class->_FULL_BACKEND()->resolve(1)->then( sub {
        die "123\n";
    } );

    push @things, 'c';

    my $p2 = $promise->catch( sub { push @things, shift } );

    push @things, 'e';

    $class->_RESOLVE($p2);

    push @things, 'f';

    is(
        "@things",
        "c e 123\n f",
        'catch() callback invoked asynchronously',
    );
}

sub _test_die_in_catch {
    my ($class) = @_;

    my @things;

    my $promise = $class->_FULL_BACKEND()->reject(1)->catch( sub {
        die "123\n";
    } );

    push @things, 'c';

    my $p2 = $promise->catch( sub { push @things, shift } );

    push @things, 'e';

    $class->_RESOLVE($p2);

    push @things, 'f';

    is(
        "@things",
        "c e 123\n f",
        'catch() callback invoked asynchronously',
    );
}

sub _test_finally_after_rejection_rejects {
    my ($class) = @_;

    my $caught;

    {
        $class->_RESOLVE(
            $class->_FULL_BACKEND()->reject(6666)->finally( sub {} )->catch( sub { $caught = shift } )
        );
    }

    like(
        $caught,
        qr<6666>,
        'finally() rejects ',
    );
}

1;
