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

    cplay Distribution

Run C<cplay -h> or C<perldoc cplay> for more options.

=head1 DESCRIPTION

....

=head1 INSTALLATION

....

=head2 Package management system

...

=head2 Installing to system perl

...

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

L<CPAN> L<CPANPLUS> L<pip> L<App::cpm> L<App:cpanminus>

=cut

## __CPLAY_POD_MARKER__

__END__

TODO

- support for cpanfile
- support for sudo
