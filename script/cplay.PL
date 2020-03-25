#!/usr/bin/env perl

BEGIN {
    if ( "$]" < 5.019 ) {    # needs 5.20 for function signature
        die <<"EOS";
$0 is not supported on Perl $]
	cplay needs Perl 5.20 or higher
	please consider alternate solutions such as App::cpanminus or App::cpm
EOS
    }
}

# __FATPACK__

use strict;
use warnings;

use FindBin qw($Bin);    # Auto-removed
use lib "$Bin/../lib", "$Bin/../fatlib";    # Auto-removed

use App::cplay::cli ();

unless (caller) {
    exit( App::cplay::cli->new( name => "App::cplay" )->run(@ARGV) // 0 );
}

1;

### DO NOT EDIT POD HERE, adjuts cplay.pm
## __CPLAY_POD_MARKER__

=encoding utf8

=head1 NAME

App::cplay -  CPAN client using pause-play indexes

=head1 SYNOPSIS

    # Install one ore more distribution [using module or distribution names]
    cplay Cwd
    cplay Cwd File::Copy
    cplay Path-Tools

    cplay install Cwd
    cplay install Cwd File::Copy

    # install a custom or trial version
    cplay install Devel-PPPort@3.57_02

    # preserve .cpbuild directory to preserve cache and debug
    cplay install --no-cleanup --verbose A1z::Html

    # install distributions from a cpanfile
    cplay cpanfile .
    cplay cpanfile ~/my-custom.cpanfile

    cplay --version
    cplay --help

Run C<cplay -h> or C<perldoc cplay> for more options.

=head1 DESCRIPTION

This repository provides the `cplay` client to install Perl modules without using PAUSE.
This is using the `pause-play` GitHub repositories indexed by `pause-index`

[https://pause-play.github.io/pause-index/](https://pause-play.github.io/pause-index/)

Rather than using distribution tarball from PAUSE itself, `play` is relying on GitHub infrastructure to download distributions.

The repo `pause-index` host some index files which can be consumed to download and install most Perl modules.

`cplay` is the recommended CPAN client using these indexes and GitHub repositories.
You can read more about cplay client on the [cplay website](https://pause-play.github.io/cplay/).

=head1 INSTALLATION

=head2 Package management system

...

=head2 Installing to system perl

...

=head1 How to use cplay

=head2 Install a Perl Module

   # install a single module
   cplay A1z::Html
   cplay install A1z::Html
   cplay install --verbose A1z::Html

   # install multiple modules
   cplay First::Module Second::Module ...

   # install a custom version
   cplay A1z::Html@0.04

   # install a trial version
   cplay Devel::PPPort@3.57_02

=head2 Install a Perl distribution

You could use either a module name or a distribution name.

   # install a single distribution
   cplay A1z-Html
   cplay install A1z-Html
   cplay install --verbose A1z-Html

   # install multiple modules
   cplay First-Distribution Second-Distribution

   # install a custom version
   cplay A1z-Html@0.04

   # install a trial version
   cplay Devel-PPPort@3.57_02

=head2 Mix Perl modules and distributions

   cplay Module::Name Distribution-Name ...

=head2 Install Perl Modules from a cpanfile

    cplay cpanfile .
    cplay cpanfile ~/path-to/my-custom.cpanfile

=head2 Install a development or TRIAL version

   # install a trial version
   cplay Devel::PPPort@3.57_02
   cplay Devel-PPPort@3.57_02

=head2 Install a module from a custom repository

   cplay --from-tarball ./path-to/custom.tar.gz
   # where :owner, :repository and :sha are replaced with the accurate values
   cplay --from-tarball https://github.com/:owner/:repository/archive/:sha.tar.gz

=head1 Available options when installing a distribution

   --no-cleanup     preserve the .cpbuild directory
   --verbose        display more output
   --debug


=head1 Developer guide

=head2 Install dependencies

=head2 Build the fatpack version

=head1 Known issues

Probably a lot at this point this is still in active development.

=head1 TODO

=over 4

=item * [ ] setup GitHub pages

=item * [ ] support for cpanfiles

=item * [ ] write some pod/doc

=item * [ ] write some tests

=item * [ ] download the .idx tarball rather than the files themselves

=item * [ ] check the .idx signature

=item * [ ] purge .idx older than X hours

=item * [ ] prefer a quick file read/scan?

=item * [ ] log output to file

=item * [ ] improve IPC::run3 and isolate it to its own module

=item * [ ] ability to download trial version    Module@1.1_0001

=item * [ ] ability to download a custom version Module@1.3

=item * [ ] better detection of make / gmake

=item * [ ] check tarball signature

=back

=head1 DEPENDENCIES

...

=head1 QUESTIONS

=head2 Something?

Answer

=head1 COPYRIGHT

Copyright 2020 - Nicolas R.

The standalone executable contains the following modules embedded.

=over 4

=item L<HTTP::Tiny> Copyright 2011 Christian Hansen

=item L<JSON::PP> Copyright 2007-2011 by Makamaka Hannyaharamitu

=item L<File::pushd> Copyright 2012 David Golden

=item L<parent> Copyright (c) 2007-10 Max Maischein

=back

=head1 LICENSE

This software is licensed under the same terms as Perl.

=head1 CREDITS

=head2 CONTRIBUTORS

Patches and code improvements were contributed by:

...

=head2 ACKNOWLEDGEMENTS

Bug reports, suggestions and feedbacks were sent by, or general
acknowledgement goes to:

....

=head1 NO WARRANTY

This software is provided "as-is," without any express or implied
warranty. In no event shall the author be held liable for any damages
arising from the use of the software.

=head1 SEE ALSO

Also consider using traditional CPAN Clients, relying on PAUSE index:

=over 4

=item * L<App::cpm> - a fast CPAN moduler installer

=item * L<App:cpanm> - get, unpack, build and install modules from CPAN

=item * L<CPAN> - the traditional CPAN client

=item * L<CPANPLUS>

=item * L<pip>

=back

=cut

## __CPLAY_POD_MARKER__

__END__

TODO

- support for cpanfile
- support for sudo
