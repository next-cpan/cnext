package App::cplay::Helpers;

use App::cplay::std;    # import strict, warnings & features

use Config;
use File::Which ();
use App::cplay::Logger;

use Exporter 'import';
our @EXPORT_OK = qw(read_file zip);

sub read_file($file) {
    local $/;

    open( my $fh, '<:utf8', $file )
      or die "Fail to open file: $! " . join( ' ', ( caller(1) )[ 0, 1, 2, 3 ] ) . "\n";
    return readline($fh);
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

1;
