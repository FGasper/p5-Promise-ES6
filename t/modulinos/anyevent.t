#!/usr/bin/env perl

package t::anyevent;

use strict;
use warnings;
use autodie;

use Cwd;
use File::Spec;

BEGIN {
    my @path = File::Spec->splitdir( Cwd::abs_path(__FILE__) );
    splice( @path, -2, 2, 'lib' );
    push @INC, File::Spec->catdir(@path);
}

use parent qw( EventTest );

use Test::More;

if (!caller) {
    __PACKAGE__->runtests();
}

use constant _BACKEND => 'AnyEvent';

sub _REQUIRE {
    require AnyEvent;
}

sub _RESOLVE {
    my ($class, $promise) = @_;

    my $cv = AnyEvent->condvar();
    $promise->finally($cv);
    $cv->recv();
}

1;
