[![Actions Status](https://github.com/next-cpan/cnext/workflows/unit-tests/badge.svg)](https://github.com/next-cpan/cnext/actions)
[![Actions Status](https://github.com/next-cpan/cnext/workflows/integration/badge.svg)](https://github.com/next-cpan/cnext/actions)
[![Actions Status](https://github.com/next-cpan/cnext/workflows/cnext-fatpack/badge.svg)](https://github.com/next-cpan/cnext/actions)

# NAME

App::cnext -  CPAN client using next-cpan indexes

# SYNOPSIS

```perl
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
```

Run `cnext -h` or `perldoc cnext` for more options.

# DESCRIPTION

This repository provides the \`cnext\` client to install Perl modules without using PAUSE.
This is using the \`next-cpan\` GitHub repositories indexed by \`next-indexes\`

[https://ix.cnext.us](https://ix.cnext.us)

Rather than using distribution tarball from PAUSE itself, \`play\` is relying on GitHub infrastructure to download distributions.

The repo \`next-indexes\` host some index files which can be consumed to download and install most Perl modules.

\`cnext\` is the recommended CPAN client using these indexes and GitHub repositories.
You can read more about cnext client on the [cnext website cnext.us](https://cnext.us).

# INSTALLATION

## Installing to system perl

This is using cnext to install itself.

```
curl -sL https://git.io/cnext | perl - self-install
cnext --version
```

Or if you are not using root

```
sudo curl -sL https://git.io/cnext | perl - self-install
```

You can also select where you want to install the script using installdirs

```
curl -sL https://git.io/cnext | perl - self-install --installdirs=site  # this is the default
curl -sL https://git.io/cnext | perl - self-install --installdirs=perl
curl -sL https://git.io/cnext | perl - self-install --installdirs=vendor
```

## Local installation

You can also download and install cnext to any custom location.

```
curl -fsSL --compressed https://git.io/cnext > cnext
chmod +x cnext
./cnext --version
```

# How to use cnext

## Install a Perl Module

```
# install a single module
cnext A1z::Html
cnext install A1z::Html
cnext install --verbose A1z::Html

# install multiple modules
cnext First::Module Second::Module ...
```

## Install a Perl distribution

You could use either a module name or a distribution name.

```
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
```

## Mix Perl modules and distributions

```
cnext Module::Name Distribution-Name ...
```

## Install Perl Modules from a cpanfile

```perl
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
```

## Install a development or TRIAL version

```
# install a trial version
cnext Devel-PPPort@3.57_02
```

## Install a module from a custom repository

```
cnext --from-tarball ./path-to/custom.tar.gz
# where :owner, :repository and :sha are replaced with the accurate values
cnext --from-tarball https://github.com/:owner/:repository/archive/:sha.tar.gz

cnext --from-tarball -d https://github.com/next-cpan/A1z-Html/archive/p5.tar.gz
```

## Install one distribution to a custom directory

By default modules are install to the current @INC, but you can specify a custom directory
where to install these modules using -L.

```
cnext -L ~/vendor Simple-Accessor
```

## Set destination

You can setup the installdir destination you are targetting.
Possible values are: perl, site, vendor (default: site)

```
                               INSTALLDIRS set to
                         perl        site          vendor

               PERLPREFIX      SITEPREFIX          VENDORPREFIX
INST_ARCHLIB   INSTALLARCHLIB  INSTALLSITEARCH     INSTALLVENDORARCH
INST_LIB       INSTALLPRIVLIB  INSTALLSITELIB      INSTALLVENDORLIB
INST_BIN       INSTALLBIN      INSTALLSITEBIN      INSTALLVENDORBIN
INST_SCRIPT    INSTALLSCRIPT   INSTALLSITESCRIPT   INSTALLVENDORSCRIPT
INST_MAN1DIR   INSTALLMAN1DIR  INSTALLSITEMAN1DIR  INSTALLVENDORMAN1DIR
INST_MAN3DIR   INSTALLMAN3DIR  INSTALLSITEMAN3DIR  INSTALLVENDORMAN3DIR
```

Sample usages:

```
cnext install A1z-Html                     # install to site directories by default
cnext install --installdir=site   A1z-Html  # site is the default
cnext install --installdir=vendor A1z-Html
cnext install --installdir=perl   A1z-Html
```

## Checking a repository

This will clone and open a SHELL in a temporary directory,
removed once you exit the session.

```
cnext look A1z::Html
cnext look A1z-Html
```

## Testing a distribution

You can test a distribution without installing it.

```
cnext test Your-Distribution
cnext test -v Your-Distribution # with some verbose output
cnext test -d Your-Distribution # with some debug output
```

You can also test a distribution described by the BUILD.json in the current directory.

```
cnext test .
```

# USAGE

```
cnext [ACTION] [OPTIONS] [ARGS]
```

## ACTIONS

```
  install             default action to install distributions
  cpanfile            install dependencies from a cpanfile
  fromtarabll         install a distribution from a tarball
  selfupdate          selfupdate cnext binary
  selfinstall         selfinstall the binary
  help                display this documentation
  look                Clones & opens the distribution with your SHELL
```

## OPTIONS

## Generic options

```perl
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
```

## cpanfile options

```perl
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
```

# Developer guide

## Install dependencies

All dependencies are listed in a cpanfile, you can install them using App::cpanm

```
    cpanm --installdeps .
```

## Build the fatpack version

# Known issues

Probably a lot at this point this is still in active development.

# TODO

- \[ \] setup GitHub pages
- \[ \] write some pod/doc
- \[ \] write some tests
- \[ \] prefer a quick file read/scan?
- \[ \] log output to file
- \[ \] check builder type play for cnext, Build.PL and Makefile.PL...
- \[ \] look at AcePerl and Acme BUILD.PL - configure\_requires
- \[ \] look
- \[ \] support for share directories
- \[ \] support for script \[shebang\]

# COPYRIGHT

Copyright 2020 - Nicolas R.

The standalone executable contains the following modules embedded.

- [HTTP::Tiny](https://metacpan.org/pod/HTTP%3A%3ATiny) Copyright 2011 Christian Hansen
- [JSON::PP](https://metacpan.org/pod/JSON%3A%3APP) Copyright 2007-2011 by Makamaka Hannyaharamitu
- [File::pushd](https://metacpan.org/pod/File%3A%3Apushd) Copyright 2012 David Golden
- [parent](https://metacpan.org/pod/parent) Copyright (c) 2007-10 Max Maischein

# LICENSE

This software is licensed under the same terms as Perl.

# CREDITS

## CONTRIBUTORS

Patches and code improvements were contributed by:

...

## ACKNOWLEDGEMENTS

Bug reports, suggestions and feedbacks were sent by, or general
acknowledgement goes to:

\- Matt S. Trout (mst) & Shadowcat System for their contribution
on self-reading a script using Filter::Util::Call
which is used by self-install instead of downloading it twice.

# NO WARRANTY

This software is provided "as-is," without any express or implied
warranty. In no event shall the author be held liable for any damages
arising from the use of the software.

# SEE ALSO

Also consider using traditional CPAN Clients, relying on PAUSE index:

- [App::cpm](https://metacpan.org/pod/App%3A%3Acpm) - a fast CPAN moduler installer
- [App:cpanm](App:cpanm) - get, unpack, build and install modules from CPAN
- [CPAN](https://metacpan.org/pod/CPAN) - the traditional CPAN client
- [CPANPLUS](https://metacpan.org/pod/CPANPLUS)
- [pip](https://metacpan.org/pod/pip)
