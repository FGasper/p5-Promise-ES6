#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::FailWarnings;
use Test::Fatal;
use Test::Deep;

use parent 'Test::Class';

BEGIN {
    for my $req ( qw( Future::AsyncAwait  AnyEvent ) ) {
        eval "require $req" or plan skip_all => "No $req";
    }
}

use Promise::ES6;

use Future::AsyncAwait future_class => 'Promise::ES6';

__PACKAGE__->new()->runtests() if !caller;

sub delay {
    my $secs = shift;

    return Promise::ES6->new( sub {
        my $res = shift;

        my $timer; $timer = AnyEvent->timer(
            after => $secs,
            cb => sub {
                undef $timer;
                $res->($secs);
            },
        );
    } );
}

async sub thethings {
    await delay(0.01);

    return 5;
}

async sub reject_nonono {
    await delay(0.01)->then( sub { die 'nonono' } );

    die 'I should not get here.';
}

sub simple_delay : Tests(1) {
    my $cv = AnyEvent->condvar();

    thethings()->then($cv);

    my ($got) = $cv->recv();

    is $got, 5, 'expected resolution';
}

sub await_reject : Tests(2) {
    my $err;

    my @w;

    {
        local $SIG{'__WARN__'} = sub { push @w, @_ };

        my $cv = AnyEvent->condvar();

        reject_nonono()->then(
            sub { $cv->(1, shift) },
            sub { $cv->(0, shift) },
        );

        my @fate = $cv->recv();

        cmp_deeply(
            \@fate,
            [
                0,
                all(
                    re( qr<\Anonono> ),
                    none( re( qr<should not get here> ) ),
                ),
            ],
            'expected rejection',
        );
    }

    is_deeply(\@w, [], 'no warnings') or diag explain \@w;
}

1;
