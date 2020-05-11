# perl Makefile.PL (from git repo) copies 'cnext' -> 'bin/cnext'

if ( -e 'cnext' ) {
    for my $file ("bin/cnext") {
        print STDERR "Generating $file from cnext\n";
        open my $in,  "<cnext" or die $!;
        open my $out, ">$file" or die $!;
        while (<$in>) {
            s|^#!/usr/bin/env perl|#!perl|;    # so MakeMaker can fix it
            print $out $_;
        }
    }
}
