#!/usr/bin/env perl

package t::race_async;

use strict;
use warnings;

use parent qw(Test::Class::Tiny);

use Test::More;
use Test::FailWarnings;

use Cwd;
use File::Spec;

BEGIN {
    my @path = File::Spec->splitdir( Cwd::abs_path(__FILE__) );
    splice( @path, -2, 2, 'lib' );
    push @INC, File::Spec->catdir(@path);
}

use MemoryCheck;

use Eventer;
use PromiseTest;

use Promise::ES6;

sub T0_tests {
    my $eventer = Eventer->new();

    my @resolves;

    my $p1 = Promise::ES6->new(sub {
        my ($resolve, $reject) = @_;

        push @resolves, sub {
            if ($eventer->has_happened('ready1') && !$eventer->has_happened('resolved1')) {
                $resolve->(1);
                $eventer->happen('resolved1');
            }
        };
    });

    my $p2 = Promise::ES6->new(sub {
        my ($resolve, $reject) = @_;

        push @resolves, sub {
            if ($eventer->has_happened('ready2') && !$eventer->has_happened('resolved2')) {
                $resolve->(2);
                $eventer->happen('resolved2');
            }
        };
    });

    my $pid = fork or do {
        $eventer->happen('ready2');

        $eventer->wait_until('resolved2');

        $eventer->happen('ready1');

        exit;
    };

    my $race = Promise::ES6->race([$p1, $p2]);

    my $value = PromiseTest::await( $race, \@resolves );
    is $value, 2;

    waitpid $pid, 0;

    # This appears to be needed to solve a garbage-collection problem
    # that Perl 5.18 fixed.
    splice @resolves if $^V lt 5.18.0;
}

if (!caller) {
    __PACKAGE__->runtests();
}

1;
