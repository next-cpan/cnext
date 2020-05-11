#!perl

use FindBin;
use lib $FindBin::Bin . '/../lib';

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use App::cnext::std;
use App::cnext::Tester;

use App::cnext;

my $V = $App::cnext::VERSION;

{
    cnext(
        args => [qw{--version}],
        exit => 0,
        test => sub($out) {
            my $lines = [ split( /\n/, $out->{output} ) ];
            is $lines => array {
                item match qr{cnext $V};
                end;
            }, "--version";
        },
    );
}

done_testing;
