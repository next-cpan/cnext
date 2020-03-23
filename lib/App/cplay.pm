package App::cplay;

our $VERSION = "0.0001";

1;

## __CPLAY_POD_MARKER__

=encoding utf8

=head1 NAME

App::cplay -  CPAN client using pause-play indexes

=head1 SYNOPSIS

    # install one ore more distribution

    cplay Cwd
    cplay Cwd File::Copy

    cplay install Cwd
    cplay install Cwd File::Copy

    # install distributions from a cpanfile

    cplay cpanfile

    cplay --version
    cplay --help

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
