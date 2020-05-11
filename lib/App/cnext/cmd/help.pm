package App::cnext::cmd::help;

use App::cnext::std;

use Pod::Text ();

sub run ( $self, @argv ) {

    my $out;
    open my $fh, ">", \$out;

    my $f = $INC{'App/cnext.pm'};
    $f = $0 unless -e $f;

    Pod::Text->new->parse_from_file( $f, $fh );

    if ( defined $out ) {
        $out =~ s/^[ ]{6}/    /mg;
        print STDERR $out;
    }

    return 0;
}

1;
