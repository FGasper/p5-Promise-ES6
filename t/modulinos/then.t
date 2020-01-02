package t::then;
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
use parent qw(Test::Class::Tiny);

use Time::HiRes;

use Test::More;
use Test::FailWarnings;

use Promise::ES6;

sub T0_already_resolved {
    my $called = 0;
    my $p = Promise::ES6->new(sub {
        my ($resolve, $reject) = @_;
        $resolve->('executed');
    });

    $p->then(sub {
        $called = 'called';
    });
    is $called, 'called', 'call fulfilled callback if promise already resolved';
}

if (!caller) {
    __PACKAGE__->runtests();
}

1;
