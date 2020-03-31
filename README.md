# NAME

App::cplay -  CPAN client using pause-play indexes

# SYNOPSIS

```perl
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
```

Run `cplay -h` or `perldoc cplay` for more options.

# DESCRIPTION

This repository provides the \`cplay\` client to install Perl modules without using PAUSE.
This is using the \`pause-play\` GitHub repositories indexed by \`pause-index\`

\[https://pause-play.github.io/pause-index/\](https://pause-play.github.io/pause-index/)

Rather than using distribution tarball from PAUSE itself, \`play\` is relying on GitHub infrastructure to download distributions.

The repo \`pause-index\` host some index files which can be consumed to download and install most Perl modules.

\`cplay\` is the recommended CPAN client using these indexes and GitHub repositories.
You can read more about cplay client on the \[cplay website\](https://pause-play.github.io/cplay/).

# INSTALLATION

## Installing to system perl

This is using cplay to install itself.

```perl
curl -L https://github.com/pause-play/cplay/raw/master/cplay | perl - App::cplay
curl -L https://git.io/cplay | perl - App::cplay
```

## Local installation

```perl
curl -fsSL --compressed https://github.com/pause-play/cplay/raw/master/cplay > cplay
chmod +x cplay
./cplay --version
```

# How to use cplay

## Install a Perl Module

```
# install a single module
cplay A1z::Html
cplay install A1z::Html
cplay install --verbose A1z::Html

# install multiple modules
cplay First::Module Second::Module ...
```

## Install a Perl distribution

You could use either a module name or a distribution name.

```
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
```

## Mix Perl modules and distributions

```
cplay Module::Name Distribution-Name ...
```

## Install Perl Modules from a cpanfile

```perl
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
```

## Install a development or TRIAL version

```
# install a trial version
cplay Devel-PPPort@3.57_02
```

## Install a module from a custom repository

```
cplay --from-tarball ./path-to/custom.tar.gz
# where :owner, :repository and :sha are replaced with the accurate values
cplay --from-tarball https://github.com/:owner/:repository/archive/:sha.tar.gz
```

# OPTIONS

## Generic options

```perl
    --no-cleanup         preserve the .cpbuild directory
-v, --verbose            Turns on chatty output
-d, --debug              enable --verbose and display some additional informations
    --show-progress --no-show-progress
                         show progress, default: on      
    --refresh            force refresh the index files
    --color, --no-color  turn on/off color output, default: on
    --test, --no-test    run test cases, default: on
    --reinstall          reinstall the distribution(s)/module(s) even if you already have the latest version installed
                         do not apply to dependencies
    --cache-dir, --cache specify an alternate cache directory (default: ~/.cplay)
    --no-check-signature disable signature check (default: on)

    --configure-timeout  Timeout for configuring a distibution  (default: 60)
    --build-timeout      Timeout for building a distribution    (default: 3600)
    --test-timeout       Timeout for running tests              (default: 1800)
    --install-timeout    Timeout forinstalling files            (default: 60)
    use a value of '0' to disable a timeout
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

## Build the fatpack version

# Known issues

Probably a lot at this point this is still in active development.

# TODO

- \[ \] setup GitHub pages
- \[ \] write some pod/doc
- \[ \] write some tests
- \[ \] prefer a quick file read/scan?
- \[ \] log output to file
- \[ \] check builder type play for cplay, Build.PL and Makefile.PL...
- \[ \] look at AcePerl and Acme BUILD.PL - configure\_requires
- \[ \] test default to t/\*.t if not there

# DEPENDENCIES

...

# QUESTIONS

## Something?

Answer

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

....

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
