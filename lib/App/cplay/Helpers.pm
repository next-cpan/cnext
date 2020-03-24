package App::cplay::Helpers;

use App::cplay::std;    # import strict, warnings & features

use Exporter 'import';
our @EXPORT_OK = qw(read_file zip);

sub read_file($file) {
    local $/;
    open( my $fh, '<:utf8', $file ) or die "Fail to open file: $!";
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

1;
