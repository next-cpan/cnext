package App::cplay::IPC;

use App::cplay::std;

use IPC::Run3 ();

sub run3 ( $cmd, $outfile = undef ) {
    my $out;
    IPC::Run3::run3 $cmd, \undef, ( $outfile ? $outfile : \$out ), \my $err;

    return ( $?, $out, $err );
}

1;
