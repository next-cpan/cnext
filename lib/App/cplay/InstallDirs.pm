package App::cplay::InstallDirs;

use App::cplay::std;

use App::cplay::Logger;    # import all

use Config;

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
    die 'Invalid type ' . ( $v // 'undef' );
}

1;
