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

## Package management system

...

## Installing to system perl

```
curl -L https://cplay.us | perl - App::cplay
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

```
    --no-cleanup         preserve the .cpbuild directory
-v, --verbose            display more output
-d, --debug              enable --verbose and display some additional informations
    --refresh            force refresh the index files
    --color, --no-color  turn on/off color output, default: on
    --test, --no-test    run test cases, default: on
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
- \[X\] support for cpanfiles
- \[ \] write some pod/doc
- \[ \] write some tests
- \[ \] download the .idx tarball rather than the files themselves
- \[X\] check the .idx version
- \[X\] purge .idx older than X hours
- \[ \] prefer a quick file read/scan?
- \[ \] log output to file
- \[ \] improve IPC::run3 and isolate it to its own module
- \[X\] ability to download trial version    Module@1.1\_0001
- \[X\] ability to download a custom version Module@1.3
- \[X\] better detection of make / gmake
- \[ \] check tarball signature
- \[X\] option to disable tests
- \[ \] check builder type play for cplay, Build.PL and Makefile.PL...
- \[X\] check builder\_API\_version = 1
- \[ \] look at AcePerl and Acme BUILD.PL - configure\_requires
- \[ \] test default to t/\*.t if not there
- \[ \] find best location for .cpbuild root \[local dir or home dir, ... \]
- \[X\] not @version for a module, only for a distro
- \[ \] cplay::Index cannot find version in file bug
- \[ \] implement timeouts

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
