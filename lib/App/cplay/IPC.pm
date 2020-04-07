package App::cplay::IPC;

use App::cplay::std;
use App::cplay::Logger qw{RUN DEBUG STDERROR};

use IPC::Run3 ();

sub run3 ( $cmd ) {
    my ( $out, $err );

    {
        my $oneliner = ref $cmd ? join( ' ', @$cmd ) : $cmd;
        RUN($oneliner);
    }

    IPC::Run3::run3( $cmd, \undef, _output( \$out ), _error( \$err ) );

    return ( $?, $out, $err );
}

sub _output($r_str) {
    return sub($line) {
        DEBUG($line);
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
