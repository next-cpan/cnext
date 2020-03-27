package App::cplay;

our $VERSION = "0.0001";

1;

## __CPLAY_POD_MARKER__

=encoding utf8

=head1 NAME

App::cplay -  CPAN client using pause-play indexes

=head1 SYNOPSIS

    # Install one ore more distribution [using module or distribution names]
    cplay Cwd
    cplay Cwd File::Copy

    cplay install Cwd
    cplay install Cwd File::Copy

    cplay install --verbose Cwd  # more output
    cplay install --debug Cwd    # additional debug informations

    # install a specific version or trial version
    cplay install Devel-PPPort@3.57
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

=head2 Installing to system perl

This is using cplay to install itself.

    curl -L https://github.com/pause-play/cplay/raw/master/cplay | perl - App::cplay
    curl -L https://git.io/cplay | perl - App::cplay

=head2 Local installation

   curl -fsSL --compressed https://github.com/pause-play/cplay/raw/master/cplay > cplay
   chmod +x cplay
   ./cplay --version

=head1 How to use cplay

=head2 Install a Perl Module

   # install a single module
   cplay A1z::Html
   cplay install A1z::Html
   cplay install --verbose A1z::Html

   # install multiple modules
   cplay First::Module Second::Module ...

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

    # by default use ./cpanfile
    cplay cpanfile
    cplay cpanfile .
    cplay cpanfile ~/cpanfile.custom

    # use one or more cpanfiles
    cplay cpanfile ~/cpanfile.1 ~/cpanfile.2 ...

    # set some feature with cpanfile
    cplay cpanfile --feature one --feature two

    # set some types/phases
    cplay cpanfile --with-requires --with-build --with-runtime --with-test

    # shortcut to enable all
    cplay cpanfile --with-all


=head2 Install a development or TRIAL version

   # install a trial version
   cplay Devel-PPPort@3.57_02

=head2 Install a module from a custom repository

   cplay --from-tarball ./path-to/custom.tar.gz
   # where :owner, :repository and :sha are replaced with the accurate values
   cplay --from-tarball https://github.com/:owner/:repository/archive/:sha.tar.gz

=head1 OPTIONS

=head2 Generic options

       --no-cleanup         preserve the .cpbuild directory
   -v, --verbose            display more output
   -d, --debug              enable --verbose and display some additional informations
       --refresh            force refresh the index files
       --color, --no-color  turn on/off color output, default: on
       --test, --no-test    run test cases, default: on
       --reinstall          reinstall the distribution(s)/module(s) even if you already have the latest version installed
                            do not apply to dependencies

=head2 cpanfile options

       --feature=identifier
         specify the feature to enable in cpanfile; you can use --feature multiple times
       --with-requires,   --without-requires   (default: with)
       --with-recommends, --without-recommends (default: without)
       --with-suggests,   --without-suggests   (default: without)
       --with-configure,  --without-configure  (default: without)
       --with-build,      --without-build      (default: with)
       --with-test,       --without-test       (default: with)
       --with-runtime,    --without-runtime    (default: with)
       --with-develop,    --without-develop    (default: without)
       --with-all         shortcut for
                          --with-requires --with-recommends --with-suggests \
                          --with-configure --with-build --with-test --with-runtime --with-develop
         specify types/phases of dependencies in cpanfile to be installed

=head1 Developer guide

=head2 Install dependencies

=head2 Build the fatpack version

=head1 Known issues

Probably a lot at this point this is still in active development.

=head1 TODO

=over 4

=item * [ ] setup GitHub pages

=item * [ ] write some pod/doc

=item * [ ] write some tests

=item * [ ] download the .idx tarball rather than the files themselves

=item * [ ] prefer a quick file read/scan?

=item * [ ] log output to file

=item * [ ] improve IPC::run3 and isolate it to its own module

=item * [ ] check tarball signature

=item * [ ] check builder type play for cplay, Build.PL and Makefile.PL...

=item * [ ] look at AcePerl and Acme BUILD.PL - configure_requires

=item * [ ] test default to t/*.t if not there

=item * [ ] find best location for .cpbuild root [local dir or home dir, ... ]

=item * [ ] cplay::Index cannot find version in file bug

=item * [ ] implement timeouts

=item * [X] update installed modules: also flag all new provided modules

=item * [X] --force to force reinstalling an existing module

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
