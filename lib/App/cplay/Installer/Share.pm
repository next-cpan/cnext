package App::cplay::Installer::Share;

use App::cplay::std;

use App::cplay::Logger;    # import all

=pod

=head1 Using share in p5

=head2 share

share/ implies that your files will go to

       /opt/cpanel/perl5/530/site_lib/auto/share/dist/$dist

No delete required, we auto sync files [remove legacy files]

=head2 share-module

share-module/Module-Name implies that your files will go to:

      /opt/cpanel/perl5/530/site_lib/auto/share/module/Module-Name

We enforce if Module-Name is not a provides in the distro.


https://github.com/pause-play/Alien-Saxon

https://metacpan.org/pod/File::ShareDir::Install#install_share

https://docs.google.com/document/d/1JgA0uN3OrpDiPN40m9W7URimmyQ6Q4ma2rEat6m2YY8/edit

=cut

1;
