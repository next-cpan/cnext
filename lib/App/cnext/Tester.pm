package App::cnext::Tester;    # inspired by App::Yath::Tester

use App::cnext::std;

#use App::cnext::Logger;

use Test2::API qw/context run_subtest/;
use Test2::Tools::Compare qw/is/;

use Carp qw/croak/;
use File::Spec;
use File::Temp qw/tempfile tempdir/;
use File::Basename qw(basename);
use POSIX;
use Fcntl qw/SEEK_CUR/;

use Cwd 'abs_path';

use Test2::Harness::Util::IPC qw/run_cmd/;

use Exporter 'import';
our @EXPORT = qw/cnext use_fatpack/;

sub find_cnext {
    state $cache;

    if ( !defined $cache ) {
        require App::cnext;
        my $path = abs_path( $INC{'App/cnext.pm'} );

        if ( use_fatpack() ) {
            $path =~ s{\Qlib/App/cnext.pm\E$}{cnext};
            -x $path or die "Cannot find cnext fatpack script";
            $cache = [$path];
        }
        else {
            my $base = $path;
            $base =~ s{\Qlib/App/cnext.pm\E$}{};
            $path = $base . 'script/cnext.PL';
            my $lib = $base . 'lib';

            die "script $path is missing"        unless -f $path;
            die "lib directory is missing: $lib" unless -d $lib;

            $cache = [ $path, "-I$lib" ];
        }
    }

    return $cache->[0] unless wantarray;    # scalar context
    return @$cache;
}

sub use_fatpack {
    return $ENV{USE_CPLAY_COMPILED} ? 1 : 0;
}

sub cnext(%params) {
    my $ctx = context();

    my $cmd = delete $params{cmd} // delete $params{command};
    my $cli = delete $params{cli} // delete $params{args} // [];
    my $env = delete $params{env} // {};
    my $prefix = delete $params{prefix};

    my $subtest  = delete $params{test} // delete $params{tests} // delete $params{subtest};
    my $exittest = delete $params{exit};

    my $debug   = delete $params{debug}   // 0;
    my $capture = delete $params{capture} // 1;

    if ( keys %params ) {
        croak "Unexpected parameters: " . join( ', ', sort keys %params );
    }

    my ( $wh, $cfile );
    if ($capture) {
        ( $wh, $cfile ) = tempfile( "cnext-$$-XXXXXXXX", TMPDIR => 1, CLEANUP => 1, SUFFIX => '.out' );
        $wh->autoflush(1);
    }

    my ( $cnext, @lib ) = find_cnext;
    my @all_args = ( $cmd ? ($cmd) : (), @$cli );
    my @cmd      = ( $^X, @lib, $cnext, @all_args );

    print "DEBUG: Command = " . join( ' ' => @cmd ) . "\n" if $debug;

    local %ENV = %ENV;
    $ENV{$_} = $env->{$_} for keys %$env;
    my $pid = run_cmd(
        no_set_pgrp => 1,
        $capture ? ( stderr => $wh, stdout => $wh ) : (),
        command       => \@cmd,
        run_in_parent => [ sub { close($wh) } ],
    );

    my ( @lines, $exit );
    if ($capture) {
        open( my $rh, '<', $cfile ) or die "Could not open output file: $!";
        $rh->blocking(0);
        while (1) {
            seek( $rh, 0, SEEK_CUR );    # CLEAR EOF
            my @new = <$rh>;
            push @lines => @new;
            print map { chomp($_); "DEBUG: > $_\n" } @new if $debug > 1;

            waitpid( $pid, WNOHANG ) or next;
            $exit = $?;
            last;
        }

        while ( my @new = <$rh> ) {
            push @lines => @new;
            print map { chomp($_); "DEBUG: > $_\n" } @new if $debug > 1;
        }
    }
    else {
        print "DEBUG: Waiting for $pid\n" if $debug;
        waitpid( $pid, 0 );
        $exit = $?;
    }

    print "DEBUG: Exit: $exit\n" if $debug;

    my $out = {
        exit => $exit,
        $capture ? ( output => join( '', @lines ) ) : (),
    };

    my $name = join( ' ', map { length($_) < 30 ? $_ : substr( $_, 0, 10 ) . "[...]" . substr( $_, -10 ) } grep { defined($_) } basename($cnext), @all_args );
    run_subtest(
        $name,
        sub {
            if ( defined $exittest ) {
                my $ictx = context( level => 3 );
                is( $exit, $exittest, "Exit Value Check" );
                $ictx->release;
            }

            if ($subtest) {
                local $_ = $out->{output};
                local $? = $out->{exit};
                $subtest->($out);
            }

            my $ictx = context( level => 3 );

            $ictx->diag( "Command = " . join( ' ' => grep { defined $_ } @cmd ) . "\nExit = $exit\n==== Output ====\n$out->{output}\n========" )
              unless $ictx->hub->is_passing;

            $ictx->release;
        },
        { buffered => 1 },
        $out,
    ) if $subtest || defined $exittest;

    $ctx->release;

    return $out;
}

1;
