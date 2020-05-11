package App::cnext;

use App::cnext::std;

our $VERSION  = "0.0001";
our $REVISION = '~REVISION~';

sub source {
    state $branch = "$]" > 7 ? 'p7' : 'p5';
    return $branch;
}

1;

## __CNEXT_POD_MARKER__

=encoding utf8

=head1 NAME

App::cnext -  CPAN client using next-cpan indexes

=head1 SYNOPSIS

    # Install one ore more distribution [using module or distribution names]
    cnext Cwd
    cnext Cwd File::Copy

    cnext install Cwd
    cnext install Cwd File::Copy

    cnext install --verbose Cwd  # more output
    cnext install --debug Cwd    # additional debug informations

    # install a specific version or trial version
    cnext install Devel-PPPort@3.57
    cnext install Devel-PPPort@3.57_02

    # preserve .cpbuild directory to preserve cache and debug
    cnext install --no-cleanup --verbose A1z::Html

    # install the distribution from current directory
    cnext install .

    # install distributions from a cpanfile
    cnext cpanfile .
    cnext cpanfile ~/my-custom.cpanfile

    # Getting a repository / distribution name for a module
    cnext get-repo Simple::Accessor

    # Clone a distribution to investigate / patch in a SHELL session
    cnext look Simple-Accessor

    # Only run unit tests without installing any distributions
    cnext test Simple-Accessor
    # Run test for the distribution in the current directory
    cnext test .

    cnext --version
    cnext --help

Run C<cnext -h> or C<perldoc cnext> for more options.

=head1 DESCRIPTION

This repository provides the `cnext` client to install Perl modules without using PAUSE.
This is using the `next-cpan` GitHub repositories indexed by `next-indexes`

L<https://ix.cnext.us|https://ix.cnext.us>

Rather than using distribution tarball from PAUSE itself, `play` is relying on GitHub infrastructure to download distributions.

The repo `next-indexes` host some index files which can be consumed to download and install most Perl modules.

`cnext` is the recommended CPAN client using these indexes and GitHub repositories.
You can read more about cnext client on the L<cnext website cnext.us|https://cnext.us>.

=head1 INSTALLATION

=head2 Installing to system perl

This is using cnext to install itself.

    curl -sL https://git.io/cnext | perl - self-install
    cnext --version

Or if you are not using root

    sudo curl -sL https://git.io/cnext | perl - self-install

You can also select where you want to install the script using installdirs

    curl -sL https://git.io/cnext | perl - self-install --installdirs=site  # this is the default
    curl -sL https://git.io/cnext | perl - self-install --installdirs=perl
    curl -sL https://git.io/cnext | perl - self-install --installdirs=vendor


=head2 Local installation

You can also download and install cnext to any custom location.

   curl -fsSL --compressed http://get.cnext.us > cnext
   chmod +x cnext
   ./cnext --version

=head1 How to use cnext

=head2 Install a Perl Module

   # install a single module
   cnext A1z::Html
   cnext install A1z::Html
   cnext install --verbose A1z::Html

   # install multiple modules
   cnext First::Module Second::Module ...

=head2 Install a Perl distribution

You could use either a module name or a distribution name.

   # install a single distribution
   cnext A1z-Html
   cnext install A1z-Html
   cnext install --verbose A1z-Html

   # install multiple modules
   cnext First-Distribution Second-Distribution

   # install a custom version
   cnext A1z-Html@0.04

   # install a trial version
   cnext Devel-PPPort@3.57_02

=head2 Mix Perl modules and distributions

   cnext Module::Name Distribution-Name ...

=head2 Install Perl Modules from a cpanfile

    # by default use ./cpanfile
    cnext cpanfile
    cnext cpanfile .
    cnext cpanfile ~/cpanfile.custom

    # use one or more cpanfiles
    cnext cpanfile ~/cpanfile.1 ~/cpanfile.2 ...

    # set some feature with cpanfile
    cnext cpanfile --feature one --feature two

    # set some types/phases
    cnext cpanfile --with-requires --with-build --with-runtime --with-test

    # shortcut to enable all
    cnext cpanfile --with-all

=head2 Install a development or TRIAL version

   # install a trial version
   cnext Devel-PPPort@3.57_02

=head2 Install a module from a custom repository

   cnext --from-tarball ./path-to/custom.tar.gz
   # where :owner, :repository and :sha are replaced with the accurate values
   cnext --from-tarball https://github.com/:owner/:repository/archive/:sha.tar.gz

   cnext --from-tarball -d https://github.com/next-cpan/A1z-Html/archive/p5.tar.gz

=head2 Install one distribution to a custom directory

By default modules are install to the current @INC, but you can specify a custom directory
where to install these modules using -L.

   cnext -L ~/vendor Simple-Accessor

=head2 Set destination

You can setup the installdir destination you are targetting.
Possible values are: perl, site, vendor (default: site)

                                   INSTALLDIRS set to
                             perl        site          vendor

                   PERLPREFIX      SITEPREFIX          VENDORPREFIX
    INST_ARCHLIB   INSTALLARCHLIB  INSTALLSITEARCH     INSTALLVENDORARCH
    INST_LIB       INSTALLPRIVLIB  INSTALLSITELIB      INSTALLVENDORLIB
    INST_BIN       INSTALLBIN      INSTALLSITEBIN      INSTALLVENDORBIN
    INST_SCRIPT    INSTALLSCRIPT   INSTALLSITESCRIPT   INSTALLVENDORSCRIPT
    INST_MAN1DIR   INSTALLMAN1DIR  INSTALLSITEMAN1DIR  INSTALLVENDORMAN1DIR
    INST_MAN3DIR   INSTALLMAN3DIR  INSTALLSITEMAN3DIR  INSTALLVENDORMAN3DIR

Sample usages:

    cnext install A1z-Html                     # install to site directories by default
    cnext install --installdir=site   A1z-Html  # site is the default
    cnext install --installdir=vendor A1z-Html
    cnext install --installdir=perl   A1z-Html

=head2 Checking a repository

This will clone and open a SHELL in a temporary directory,
removed once you exit the session.

  cnext look A1z::Html
  cnext look A1z-Html

=head2 Testing a distribution

You can test a distribution without installing it.

  cnext test Your-Distribution
  cnext test -v Your-Distribution # with some verbose output
  cnext test -d Your-Distribution # with some debug output

You can also test a distribution described by the BUILD.json in the current directory.

  cnext test .

=head1 USAGE

  cnext [ACTION] [OPTIONS] [ARGS]

=head2 ACTIONS

      install             default action to install distributions
      cpanfile            install dependencies from a cpanfile
      fromtarabll         install a distribution from a tarball
      selfupdate          selfupdate cnext binary
      selfinstall         selfinstall the binary
      help                display this documentation
      look                Clones & opens the distribution with your SHELL

=head2 OPTIONS

=head2 Generic options

       --no-cleanup         preserve the .cpbuild directory
   -v, --verbose            Turns on chatty output
   -d, --debug              enable --verbose and display some additional informations
       --show-progress --no-show-progress
                            show progress, default: on
       --refresh            force refresh the index files
       --color, --no-color  turn on/off color output, default: on
       --test               run test cases, default: on
   -n, --no-test
       --reinstall          reinstall the distribution(s)/module(s) even if you already have the latest version installed
                            do not apply to dependencies
       --cache-dir, --cache specify an alternate cache directory (default: ~/.cnext)
       --no-check-signature disable signature check (default: on)

       --configure-timeout  Timeout for configuring a distibution  (default: 60)
       --build-timeout      Timeout for building a distribution    (default: 3600)
       --test-timeout       Timeout for running tests              (default: 1800)
       --install-timeout    Timeout forinstalling files            (default: 60)
       use a value of '0' to disable a timeout
   -L, --local-lib DIR      Specify the install base directory to install all modules.
       --installdir TYPE    Set installation destination, possible values are perl, site, vendor (default:site)

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

All dependencies are listed in a cpanfile, you can install them using App::cpanm

        cpanm --installdeps .

=head2 Build the fatpack version

=head1 Known issues

Probably a lot at this point this is still in active development.

=head1 TODO

=over 4

=item * [ ] setup GitHub pages

=item * [ ] write some pod/doc

=item * [ ] write some tests

=item * [ ] prefer a quick file read/scan?

=item * [ ] log output to file

=item * [ ] check builder type play for cnext, Build.PL and Makefile.PL...

=item * [ ] look at AcePerl and Acme BUILD.PL - configure_requires

=item * [ ] look

=item * [ ] support for share directories

=item * [ ] support for script [shebang]

=back

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

- Matt S. Trout (mst) & Shadowcat System for their contribution
on self-reading a script using Filter::Util::Call
which is used by self-install instead of downloading it twice.

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
