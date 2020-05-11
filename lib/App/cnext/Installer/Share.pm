package App::cnext::Installer::Share;    # Maybe InstallDirs/Share ?

use App::cnext::std;

use App::cnext::Logger;                  # import all

use App::cnext::Helpers qw{is_valid_distribution_name};

use File::Spec;                          # CORE
use Umask::Local ();                     # fatpacked

use Simple::Accessor qw{installdirs BUILD dist_dir};

sub _build_dist_dir( $self ) {
    my $dist = $self->BUILD->name;
    FATAL("Invalid distribution name: '$dist'") unless is_valid_distribution_name($dist);

    return File::Spec->catdir( 'auto', 'share', 'dist', $dist );
}

sub module_dir ( $self, $module ) {
    $module =~ s/::/-/g;
    FATAL("Invalid module name: '$module'") if $module =~ m{\s};

    return File::Spec->catdir( 'auto', 'share', 'module', $module );
}

sub install_share_module($self) {
    return 1 unless -d q[share-module];

    my $has_errors = 0;
    my $wanted     = sub {

        # $File::Find::dir is the current directory name,
        # $_ is the current filename within that directory
        # $File::Find::name is the complete pathname to the file.
        return unless -f $File::Find::name;

        my $destination = $File::Find::name;
        $destination =~ s{^share-module/}{};

        my ( $shared_module, $path ) = split( '/', $destination, 2 );
        if ( !defined $path ) {
            ERROR("Invalid share-module path: $destination");
            ++$has_errors;
            return;
        }

        eval {
            $self->installdirs->install_to_lib(
                $File::Find::name,    # complete pathname to current file
                File::Spec->catfile( $self->module_dir($shared_module), $path )
            );
            1;
        } or ++$has_errors;

        return;
    };

    File::Find::find( { wanted => $wanted, no_chdir => 1 }, 'share-module' );
    return if $has_errors;

    return 1;
}

sub install_share($self) {
    return 1 unless -d q[share];

    my $has_errors = 0;
    my $wanted     = sub {

        # $File::Find::dir is the current directory name,
        # $_ is the current filename within that directory
        # $File::Find::name is the complete pathname to the file.
        return unless -f $File::Find::name;

        my $destination = $File::Find::name;
        $destination =~ s{^share/}{};

        eval {
            $self->installdirs->install_to_lib(
                $File::Find::name,    # complete pathname to current file
                File::Spec->catfile( $self->dist_dir, $destination )
            );
            1;
        } or ++$has_errors;

        return;
    };

    File::Find::find( { wanted => $wanted, no_chdir => 1 }, 'share' );
    return if $has_errors;

    return 1;
}

sub install($self) {    # main entry point

    my $umask = Umask::Local->new(0333);    # r/r/r
    return $self->install_share && $self->install_share_module;
}

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


https://github.com/next-cpan/Alien-Saxon

https://metacpan.org/pod/File::ShareDir::Install#install_share

https://docs.google.com/document/d/1JgA0uN3OrpDiPN40m9W7URimmyQ6Q4ma2rEat6m2YY8/edit

=cut

1;
