package App::cnext::InstallDirs;

use App::cnext::std;

use App::cnext::Logger;    # import all
use App::cnext::IPC;

use Config;
use File::Path;
use File::Spec;            # CORE

use Umask::Local ();       # fatpacked

use Simple::Accessor qw{
  type

  arch
  lib
  bin
  script
  man1
  man3
};

=pod

https://metacpan.org/pod/ExtUtils::MakeMaker#make-install


                               INSTALLDIRS set to
                         perl        site          vendor
 
               PERLPREFIX      SITEPREFIX          VENDORPREFIX
INST_ARCHLIB   INSTALLARCHLIB  INSTALLSITEARCH     INSTALLVENDORARCH
INST_LIB       INSTALLPRIVLIB  INSTALLSITELIB      INSTALLVENDORLIB
INST_BIN       INSTALLBIN      INSTALLSITEBIN      INSTALLVENDORBIN
INST_SCRIPT    INSTALLSCRIPT   INSTALLSITESCRIPT   INSTALLVENDORSCRIPT
INST_MAN1DIR   INSTALLMAN1DIR  INSTALLSITEMAN1DIR  INSTALLVENDORMAN1DIR
INST_MAN3DIR   INSTALLMAN3DIR  INSTALLSITEMAN3DIR  INSTALLVENDORMAN3DIR

=cut

my $IX = { arch => 0, lib => 1, bin => 2, script => 3, man1 => 4, man3 => 5 };

my $MAP = {
    perl => [
        qw{
          installarchlib
          installprivlib
          installbin
          installscript
          installman1dir
          installman3dir
          }
    ],
    site => [
        qw{
          installsitearch
          installsitelib
          installsitebin
          installsitescript
          installsiteman1dir
          installsiteman3dir
          }
    ],
    vendor => [
        qw{
          installvendorarch
          installvendorlib
          installvendorbin
          installvendorscript
          installvendorman1dir
          installvendorman3dir
          }
    ],

};

sub _get_config {    # allow to mock Config in unit tests
    return \%Config;
}

sub build ( $self, %options ) {

    my $type = delete $options{type} // 'site';
    $self->type($type);

    if ( scalar keys %options ) {
        die q[Too many arguments to new: ] . join( ', ', sort keys %options );
    }

    # auto setup
    my $cfg = _get_config();
    foreach my $k ( keys %$IX ) {
        my $name = $MAP->{$type}->[ $IX->{$k} ];
        $self->{$k} = $cfg->{$name};

        #$self->{$k} = undef if !$self->{$k}; # set undef
        #if ( $k !~ m{^man} ) { # only die if dir is missing and not a man dir
        #  $self->{$k} or die qq['$name' not set in Config];
        #}
    }

    return $self;
}

sub _validate_type ( $self, $v ) {
    return 1 if defined $v && defined $MAP->{$v};
    FATAL( 'Invalid type ' . ( $v // 'undef' ) );
}

sub create_if_missing ( $self, $dir ) {
    FATAL("dir is not defined") unless defined $dir && length $dir;

    return 2 if -d $dir;

    DEBUG("Creating missing directory: $dir");
    File::Path::make_path( $dir, { chmod => 0755, verbose => 0 } )
      or FATAL("Fail to create $dir");

    return 1;
}

sub adjust_perl_shebang ( $self, $file, $perl = $^X ) {
    my $shebang;

    # have a sneak peak first
    open( my $input, '<', $file ) or do { WARN("Fail to open $file"); return };

    $shebang = readline $input;
    chomp $shebang if defined $shebang;
    my $original_shebang = $shebang;

    # adjust the shebang line
    return
      unless $shebang =~ s{^#![/\w\.\-_]*\s*perl\s*$}{#!$perl}
      || $shebang =~ s{^#![/\w\.]*\s*perl\s+(-.*)$}{#!$perl $1};

    return if $original_shebang eq $shebang;

    my $content;
    {
        local $/;
        $content = readline $input;
    }
    close $input;

    # update the content
    open( my $output, '>', $file ) or do { WARN("Fail to open $file for writing"); return };
    print {$output} $shebang . "\n";
    print {$output} $content;
    close $output;

    return 1;
}

sub install_to_bin ( $self, $file, $basename = undef, $perl = $^X ) {
    FATAL("File is not defined") unless defined $file && length $file;
    FATAL("Cannot find file $file") unless -f $file;

    $basename //= File::Basename::basename($file);
    my $to_file = File::Spec->catfile( $self->bin, $basename );

    $self->install_file( $file, $to_file, 0755 );

    $self->adjust_perl_shebang( $to_file, $perl )
      and DEBUG("perl shebang adjusted for '$file' to use $perl");

    # FIXME should not be needed
    App::cnext::IPC::run3( [ 'chmod', '+x', $to_file ] ) unless -x $to_file;

    return $to_file;
}

=pod

        $self->installdirs->install_to_lib(  
          'share/file',
          'auto/share/dist/Dist-Sample/file'
        );

=cut

sub install_to_lib ( $self, $from_file, $to_file ) {

    if ( $to_file =~ m{^/} ) {
        FATAL("to_file cannot start with a '/', need a relative path: $to_file");
    }

    return $self->install_file( $from_file, File::Spec->catfile( $self->lib, $to_file ) );
}

sub install_file ( $self, $from_file, $to_file, $perms = undef ) {

    # sanity check
    if ( $to_file =~ m{/$} ) {
        FATAL("to_file cannot be a folder name, path should not end by '/': $to_file");
    }

    if ( -d $to_file ) {
        FATAL("Cannot install file, a directory already exists: $to_file");
    }

    my $destination_directory = File::Basename::dirname($to_file);
    $self->create_if_missing($destination_directory);

    my $umask;
    $umask = Umask::Local->new( $perms ^ 07777 ) if defined $perms;

    DEBUG("cp $from_file $to_file");
    File::Copy::copy( $from_file, $to_file );

    if ( !-f $to_file ) {
        FATAL("Failed to copy file $to_file");
    }

    if ( -s _ != -s $from_file ) {

        # give it a second chance
        unlink($to_file) or FATAL("Failed to update file $to_file - $!");
        File::Copy::copy( $from_file, $to_file );
        if ( !-f $to_file && -s _ != -s $from_file ) {
            FATAL("Failed to copy file $from_file / $to_file [size mismatch]");
        }
    }

    return;
}

1;
