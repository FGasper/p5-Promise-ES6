package t::reject;
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
use Test::More;
use Test::FailWarnings;

use Promise::ES6;

sub T1_reject {
    Promise::ES6->reject('oh my god')->then(sub {
        die;
    }, sub {
        my ($reason) = @_;
        is $reason, 'oh my god';
    });
}

sub T2_reject_promise {
    my $p2 = Promise::ES6->resolve(123);

    Promise::ES6->reject($p2)->catch( sub {
        my $reason = shift;
        is( $reason, $p2, 'reject() - promise as rejection is literal rejection value' );
    } );

    Promise::ES6->new( sub { $_[1]->($p2) } )->catch( sub {
        my $reason = shift;
        is( $reason, $p2, 'callback - promise as rejection is literal rejection value' );
    } );
}

__PACKAGE__->runtests() if !caller;

1;
