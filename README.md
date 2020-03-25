# Introduction

This repository provides the `cplay` client to install Perl modules without using PAUSE.
This is using the `pause-play` GitHub repositories indexed by `pause-index`

[https://pause-play.github.io/pause-index/](https://pause-play.github.io/pause-index/)

Rather than using distribution tarball from PAUSE itself, `play` is relying on GitHub infrastructure to download distributions.

The repo `pause-index` host some index files which can be consumed to download and install most Perl modules.

`cplay` is the recommended CPAN client using these indexes and GitHub repositories.
You can read more about cplay client on the [cplay website](https://pause-play.github.io/cplay/).

# How to install cplay

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

You can provide to the install command a mix of modules or distributions
```
	cplay Module::Name Distribution-Name ...
```

## Install Perl Modules from a cpanfile

```
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

# Developer guide

## Install dependencies

## Build the fatpack version

# See Also

Also consider using traditional CPAN Clients, relying on PAUSE index:

- [cplay](https://pause-play.github.io/cplay/) - CPAN client using pause-play indexes
- cpan
- [App::cpanminus](https://metacpan.org/pod/App::cpanminus) - get, unpack, build and install modules from CPAN
- [App::cpm](https://metacpan.org/pod/App::cpm) - a fast CPAN moduler installer

# Known issues

# TODO

- [ ] setup GitHub pages
- [ ] support for cpanfiles
- [ ] write some pod/doc
- [ ] write some tests
- [ ] download the .idx tarball rather than the files themselves
- [ ] check the .idx signature
- [ ] purge .idx older than X hours
- [ ] prefer a quick file read/scan?
- [ ] log output to file
- [ ] improve IPC::run3 and isolate it to its own module
- [ ] ability to download trial version    Module@1.1_0001
- [ ] ability to download a custom version Module@1.3
- [ ] better detection of make / gmake
- [ ] check tarball signature
