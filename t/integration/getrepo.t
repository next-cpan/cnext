#!perl

use FindBin;
use lib $FindBin::Bin . '/../lib';
use lib $FindBin::Bin . '/../../fatlib';

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use cPlayTestHelpers;

use App::next::std;
use App::next::Tester;

#use App::next::IPC;
#use App::next::Helpers qw{read_file write_file};

#use File::Temp;
#use File::pushd;

note "Testing cplay get-repo action";

{

    cplay(
        command => 'get-repo',
        args    => [qw{A1z::Html}],
        exit    => 0,
        test    => sub($out) {
            my $lines = [ split( /\n/, $out->{output} ) ];
            is $lines => array {
                item 'A1z-Html';
                end;
            }, "A1z::Html";
        },
    );

    cplay(
        command => 'get-repo',
        args    => [qw{Unkown::Module::XYZ}],
        exit    => 256,
        test    => sub($out) {
            my $lines = [ split( /\n/, $out->{output} ) ];
            is $lines => array {
                item match qr{ERROR Cannot find a repository for module 'Unkown::Module::XYZ'};
                end;
            }, "Fail to find repo for Unkown::Module::XYZ";
        },
    );

    cplay(
        command => 'get-repo',
        args    => [qw{warnings}],
        exit    => 0,
        test    => sub($out) {
            my $lines = [ split( /\n/, $out->{output} ) ];
            is $lines => array {
                item 'CORE v5.006';
                end;
            }, "warnings is CORE";
        },
    );

    cplay(
        command => 'get-repo',
        args    => [qw{File::Basename}],
        exit    => 0,
        test    => sub($out) {
            my $lines = [ split( /\n/, $out->{output} ) ];
            is $lines => array {
                item 'CORE v5';
                end;
            }, "File::Basename is CORE";
        },
    );

    cplay(
        command => 'get-repo',
        args    => [qw{perl}],
        exit    => 0,
        test    => sub($out) {
            my $lines = [ split( /\n/, $out->{output} ) ];
            is $lines => array {
                item 'CORE';
                end;
            }, "perl";
        },
    );

}

done_testing;
