package App::cplay::Module;

use App::cplay::std;    # import strict, warnings & features
use App::cplay::Logger;

use App::cplay::IPC;

use Exporter 'import';
our @EXPORT    = qw(has_module_version);
our @EXPORT_OK = ( @EXPORT, qw{get_module_version module_updated} );

my %CACHE;              # check if we have a specific version of a module
my %GOT;                # current install version of a module

sub has_module_version ( $module, $version, $local_lib = undef ) {
    my $IN = _in($local_lib);

    # check the global cache
    if (   defined $CACHE{$module}
        && defined $CACHE{$module}->{$IN}
        && defined $CACHE{$module}->{$IN}->{$version} ) {
        return $CACHE{$module}->{$IN}->{$version};
    }

    $CACHE{$module} //= {};
    $CACHE{$module}->{$IN} //= {};

    my $has_module  = 0;
    my $got_version = get_module_version( $module, $local_lib );

    if ( lc $module eq 'perl' && $version =~ m{^v?(\d+)\.(\d+)\.(\d+)$}ia ) {
        $version = sprintf( "%d.%03d%03d", $1, $2, $3 );
    }

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

    $CACHE{$module}->{$IN}->{$version} = $has_module;
    return $has_module;
}

# undef => we do not have the module
# 0     => we do not know the version
sub get_module_version ( $module, $local_lib = undef ) {
    my $IN = _in($local_lib);

    return $GOT{$module}->{$IN} if defined $GOT{$module} && defined $GOT{$module}->{$IN};
    return "$]"                 if lc $module eq 'perl';                                    # no cache needed

    my $version;

    if ( !defined $local_lib ) {
        my $oneliner = qq|eval { require $module; 1 } or die; print eval { \$${module}::VERSION } // 0|;
        my ( $status, $out, $err ) = App::cplay::IPC::run3( [ $^X, '-e', $oneliner ] );
        if ( $status == 0 ) {
            $version = $out;
            chomp $version if $version;
        }
    }
    else {
        local $ENV{PERL5LIB};    # deactivate the current one

        my $pp = $module;
        $pp =~ s{::}{/}g;
        $pp .= '.pm';

        my $oneliner = <<"EOS";
eval { require $module; 1 } or die; 
die unless \$INC{"$pp"} =~ m{^\Q$local_lib\E}; 
print eval { \$${module}::VERSION } // 0;
EOS
        my ( $status, $out, $err ) = App::cplay::IPC::run3( [ $^X, "-mlocal::lib=--no-create,$local_lib", '-e', $oneliner ] );
        if ( $status == 0 ) {
            $version = $out;
            chomp $version if $version;
        }
    }

    $GOT{$module} //= {};
    $GOT{$module}->{$IN} = $version;    # cache the version

    DEBUG( "get_module_version $module = " . ( $version // '' ) );

    return $version;

}

# could also clear it with local_lib
sub module_updated ( $module, $version, $local_lib = undef ) {
    die("Missing module name") unless defined $module;
    my $IN = _in($local_lib);

    # version can be undef to fake an uninstalled module

    delete $CACHE{$module};
    $GOT{$module} //= {};
    $GOT{$module}->{$IN} = $version;    # cache the version

    return;
}

# where are we searching for this module: returns a key used for the cache
sub _in ( $local_lib = undef ) {
    return $local_lib // 'default';
}

sub clear_module( $module ) {
    delete $CACHE{$module};
    delete $GOT{$module};

    return;
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
