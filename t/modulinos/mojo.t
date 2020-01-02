#!/usr/bin/env perl

package t::mojo;

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

use constant _BACKEND => 'Mojo';

#----------------------------------------------------------------------

if (!caller) {
    __PACKAGE__->runtests();
}

#----------------------------------------------------------------------

sub _REQUIRE {
    require Mojo::IOLoop;
    die "Mojo::IOLoop lacks next_tick()." if !Mojo::IOLoop->can('next_tick');
}

sub _RESOLVE {
    my ($class, $promise) = @_;

    $promise->finally( sub { Mojo::IOLoop->stop() } );

    Mojo::IOLoop->start();
}

1;
