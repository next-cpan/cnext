package App::cplay::Helpers;

use App::cplay::std;    # import strict, warnings & features

use Config;
use File::Which ();
use App::cplay::Logger;

use Exporter 'import';
our @EXPORT_OK = qw(read_file zip write_file is_fatpacked update_shebang);

sub read_file ( $file, $mode = ':utf8' ) {
    local $/;

    open( my $fh, '<' . $mode, $file )
      or die "Fail to open file: $! " . join( ' ', ( caller(1) )[ 0, 1, 2, 3 ] ) . "\n";

    return readline($fh);
}

sub is_fatpacked() {
    return unless my $ref = ref $INC{'App/cplay/cmd/selfinstall.pm'};
    return $ref =~ m{^FatPacked} ? 1 : 0;
}

sub write_file ( $file, $content, $mode = ':utf8' ) {
    open( my $fh, '>' . $mode, $file )
      or die "Fail to open file: $! " . join( ' ', ( caller(1) )[ 0, 1, 2, 3 ] ) . "\n";

    print {$fh} $content;

    return;
}

sub zip : prototype(\@\@;\@\@\@\@\@\@\@\@\@\@\@\@\@\@\@\@\@\@\@\@\@\@\@\@\@\@\@\@\@\@) {
    my $max = -1;
    $max < $#$_ && ( $max = $#$_ ) foreach @_;
    map {
        my $ix = $_;
        map $_->[$ix], @_;
    } 0 .. $max;
}

sub make_binary {
    my @lookup = ( $Config{make}, qw{make gmake} );
    foreach my $bin (@lookup) {
        next unless $bin;
        my $path = File::Which::which( $Config{make} );
        next unless -x $path;
        no warnings 'redefine';
        *make_binary = sub { $path };
        return $path;
    }

    FATAL("Cannot find make binary");
}

sub prove_binary {
    my $prove;
    my @prefixes = qw{bin installbin sitebin vendorbin};

    foreach my $prefix (@prefixes) {
        next unless $Config{$prefix};
        $prove = $Config{$prefix} . '/prove';
        last if -x $prove;
    }

    if ( !-x $prove ) {
        my $perldoc = $^X . "doc";    # perldoc
        $prove = qx{$perldoc -l prove};
        $prove = undef if $? != 0;

        #$prove = File::Which::which( $Config{sitebin} );
    }

    if ( defined $prove && -x $prove ) {
        no warnings 'redefine';
        *prove_binary = sub { $prove };
        return $prove;
    }

    FATAL("Cannot find 'prove' binary");
}

sub update_shebang($file) {
    return unless defined $file && -f $file;

    open( my $input, '<', $file )
      or die "Fail to open file: $! " . join( ' ', ( caller(1) )[ 0, 1, 2, 3 ] ) . "\n";

    my $output_file = "$file.tmp";
    open( my $output, '>', $output_file )
      or die "Fail to open file: $! " . join( ' ', ( caller(1) )[ 0, 1, 2, 3 ] ) . "\n";

    my $c = 0;
    while ( my $line = <$input> ) {
        if ( ++$c == 1 && $line =~ m{^#!.*perl} ) {
            $line = qq[#!$^X];    # update the shebang line
        }

        print {$output} $line;
    }

    return;
}

1;
