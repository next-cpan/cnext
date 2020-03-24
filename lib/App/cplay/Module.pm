package App::cplay::Module;

use App::cplay::std;    # import strict, warnings & features
use App::cplay::Logger;

use Exporter 'import';
our @EXPORT    = qw(has_module_version);
our @EXPORT_OK = ( @EXPORT, qw{get_module_version module_updated} );

my %CACHE;              # check if we have a specific version of a module
my %GOT;                # current install version of a module

sub has_module_version ( $module, $version ) {

    # check the global cache
    if ( defined $CACHE{$module} && defined $CACHE{$module}->{$version} ) {
        return $CACHE{$module}->{$version};
    }

    $CACHE{$module} //= {};

    my $has_module  = 0;
    my $got_version = get_module_version($module);

    if ( defined $got_version ) {
        if ( $got_version eq $version ) {

            # got the exact same version
            $has_module = 1;
        }
        else {
            my $version_check = eval qq{ $version > $got_version ? 0 : 1 };
            if ( !defined $version_check ) {
                WARN("module $module version is not numeric: $got_version");
            }
            elsif ($version_check) {
                $has_module = 1;
            }
        }
    }

    DEBUG( "has_module $module >= $version ? $has_module [got " . ( $got_version // '' ) . ']' );

    $CACHE{$module}->{$version} = $has_module;
    return $has_module;
}

# undef => we do not have the module
# 0     => we do not know the version
sub get_module_version( $module ) {

    return $GOT{$module} if defined $GOT{$module};

    my $version;
    my $out = qx|$^X -e 'eval { require $module; 1 } or die; print eval { \$${module}::VERSION } // 0' 2>&1|;

    if ( $? == 0 ) {
        $version = $out;
        chomp $version if $version;
    }

    $GOT{$module} = $version;    # cache the version

    DEBUG( "get_module_version $module = " . ( $version // '' ) );

    return $version;

}

sub module_updated ( $module, $version ) {
    ### FIXME
    ## idea clear the module cache once we have install a module
    ## do this for all provides
}

sub clear_cache {
    %CACHE = ();
    %GOT   = ();
    return;
}

1;

=pod

     has_module_version( 'Simple::Accessor', '1.11' );
     has_module_version( 'Simple::Accessor', '1.0' );
     has_module_version( 'Simple::Accessor', '2.0' );
     has_module_version( 'XFoo', '2.0' );

=cut
