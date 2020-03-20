# perl Makefile.PL (from git repo) copies 'cplay' -> 'bin/cplay'

if (-e 'cplay') {
    for my $file ("bin/cplay") {
        print STDERR "Generating $file from cplay\n";
        open my $in,  "<cplay" or die $!;
        open my $out, ">$file" or die $!;
        while (<$in>) {
            s|^#!/usr/bin/env perl|#!perl|; # so MakeMaker can fix it
            print $out $_;
        }
    }
}
