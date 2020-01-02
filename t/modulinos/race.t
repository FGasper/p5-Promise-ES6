package t::race;
use strict;
use warnings;

use Cwd;
use File::Spec;

BEGIN {
    my @path = File::Spec->splitdir( Cwd::abs_path(__FILE__) );
    splice( @path, -2, 2, 'lib' );
    push @INC, File::Spec->catdir(@path);
}

use MemoryCheck;
use PromiseTest;

use parent qw(Test::Class::Tiny);

use Time::HiRes;

use Test::Fatal qw(exception);
use Test::More;
use Test::FailWarnings;

use Promise::ES6;

sub T0_race_with_value {
    my ($self) = @_;

    my $resolve_cr;

    # This will never resolve.
    my $p1 = Promise::ES6->new(sub {});

    my $p2 = Promise::ES6->new(sub {
        my ($resolve, $reject) = @_;
        $resolve->(2);
    });

    my $value = PromiseTest::await( Promise::ES6->race([$p1, $p2]) );

    is $value, 2, 'got raw value instantly';
}

if (!caller) {
    __PACKAGE__->runtests();
}

1;
