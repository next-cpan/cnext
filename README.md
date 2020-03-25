# NAME

App::cplay -  CPAN client using pause-play indexes

# SYNOPSIS

```perl
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

...

# How to use cplay

## Install a Perl Module

```
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
cplay cpanfile .
cplay cpanfile ~/path-to/my-custom.cpanfile
```

## Install a development or TRIAL version

```
# install a trial version
cplay Devel::PPPort@3.57_02
cplay Devel-PPPort@3.57_02
```

## Install a module from a custom repository

```
cplay --from-tarball ./path-to/custom.tar.gz
# where :owner, :repository and :sha are replaced with the accurate values
cplay --from-tarball https://github.com/:owner/:repository/archive/:sha.tar.gz
```

# Available options when installing a distribution

```
--no-cleanup     preserve the .cpbuild directory
--verbose        display more output
--debug
```

# Developer guide

## Install dependencies

## Build the fatpack version

# Known issues

Probably a lot at this point this is still in active development.

# TODO

- \[ \] setup GitHub pages
- \[ \] support for cpanfiles
- \[ \] write some pod/doc
- \[ \] write some tests
- \[ \] download the .idx tarball rather than the files themselves
- \[ \] check the .idx signature
- \[ \] purge .idx older than X hours
- \[ \] prefer a quick file read/scan?
- \[ \] log output to file
- \[ \] improve IPC::run3 and isolate it to its own module
- \[ \] ability to download trial version    Module@1.1\_0001
- \[ \] ability to download a custom version Module@1.3
- \[ \] better detection of make / gmake
- \[ \] check tarball signature

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
