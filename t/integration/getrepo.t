#!perl

use FindBin;
use lib $FindBin::Bin . '/../lib';
use lib $FindBin::Bin . '/../../fatlib';

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use cNextTestHelpers;

use App::cnext::std;
use App::cnext::Tester;

#use App::cnext::IPC;
#use App::cnext::Helpers qw{read_file write_file};

#use File::Temp;
#use File::pushd;

note "Testing cnext get-repo action";

{

    cnext(
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

    cnext(
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

    cnext(
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

    cnext(
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

    cnext(
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
