package BackendTest;

use strict;
use warnings;

use FindBin;

use Test::More;

sub run_modulinos {
    my @path = File::Spec->splitdir(__FILE__);
    pop @path;  # filename
    pop @path;  # up one dir
    push @path, 'modulinos';

    my $wildcard_path = File::Spec->catdir(@path, '*.t');

    my @modulino_nss;

    my @paths = glob $wildcard_path;

    _run_series(@paths);
    # _run_parallel(@paths);
}

sub _run_series {
    for my $path ( @_ ) {
        my @test_path = File::Spec->splitpath($path);
        my $filename = $test_path[-1];

        my $module_name_leaf = $filename;
        $module_name_leaf =~ s<\.t\z><> or die "weird modulino name: $module_name_leaf";

        my $ns = "t::$module_name_leaf";

        subtest $ns => sub {
            require $path;
            $ns->runtests();
        }
    }
}

#sub _run_parallel {
#    use Test::SharedFork;
#
#    use MCE::Loop;
#    MCE::Loop::init( {
#        chunk_size => 1,
#        max_workers => 6,
#    } );
#
#    my @out = mce_loop {
#        my $path = $_;
#        my @test_path = File::Spec->splitpath($path);
#        my $filename = $test_path[-1];
#
#        my $module_name_leaf = $filename;
#        $module_name_leaf =~ s<\.t\z><> or die "weird modulino name: $module_name_leaf";
#
#        my $ns = "t::$module_name_leaf";
#
#        my $out = q<>;
#
#        my $Test = Test::Builder->new;
#        $Test->output(\$out);
#        $Test->failure_output(\$out);
#
#        subtest $ns => sub {
#            require $path;
#            $ns->runtests();
#        };
#
#        MCE->gather($out);
#    } @_;
#
#    print "# ------- DONE\n";
#
#    print $_ for @out;
#}

1;
