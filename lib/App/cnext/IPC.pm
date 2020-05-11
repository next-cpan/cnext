package App::cnext::IPC;

use App::cnext::std;
use App::cnext::Logger qw{RUN DEBUG STDERROR};

use IPC::Run3 ();

sub run3 ( $cmd, $log_level = 'DEBUG' ) {
    my ( $out, $err );

    {
        my $oneliner = ref $cmd ? join( ' ', @$cmd ) : $cmd;
        RUN($oneliner);
    }

    IPC::Run3::run3( $cmd, \undef, _output( \$out, $log_level ), _error( \$err ) );

    return ( $?, $out, $err );
}

sub _output ( $r_str, $log_level = 'DEBUG' ) {
    my $log = App::cnext::Logger->can($log_level) or die "unknown log level '$log_level'";
    return sub($line) {
        $log->($line);
        $$r_str = '' unless defined $$r_str;
        $$r_str .= $line;
        return;
    };
}

sub _error($r_str) {
    return sub($line) {
        STDERROR($line);
        $$r_str = '' unless defined $$r_str;
        $$r_str .= $line;
        return;
    };
}

1;
