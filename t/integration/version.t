#!perl

use FindBin;
use lib $FindBin::Bin . '/../lib';

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use App::cplay::std;
use App::cplay::Tester;

use App::cplay;

my $V = $App::cplay::VERSION;

{
    cplay(
        args => [qw{--version}],
        exit => 0,
        test => sub($out) {
            my $lines = [ split( /\n/, $out->{output} ) ];
            is $lines => array {
                item match qr{cplay $V};
                end;
            }, "--version";
        },
    );
}

done_testing;
