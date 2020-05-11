package App::next::cmd::help;

use App::next::std;

use Pod::Text ();

sub run ( $self, @argv ) {

    my $out;
    open my $fh, ">", \$out;

    my $f = $INC{'App/cplay.pm'};
    $f = $0 unless -e $f;

    Pod::Text->new->parse_from_file( $f, $fh );

    if ( defined $out ) {
        $out =~ s/^[ ]{6}/    /mg;
        print STDERR $out;
    }

    return 0;
}

1;
