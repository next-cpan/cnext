package App::next::Http;

use App::next::std;    # import strict, warnings & features

use App::next ();

use HTTP::Tinyish;

sub create ( $class, %args ) {

    my @try = $args{prefer} ? @{ $args{prefer} } : qw(HTTPTiny LWP Curl Wget);

    my ( $backend, $tool, $desc );
    for my $try ( map "HTTP::Tinyish::$_", @try ) {
        my $meta = HTTP::Tinyish->configure_backend($try) or next;
        $try->supports("https") or next;
        ($tool) = sort keys %$meta;
        ( $desc = $meta->{$tool} ) =~ s/^(.*?)\n.*/$1/s;
        $backend = $try, last;
    }
    die "Couldn't find HTTP Clients that support https" unless $backend;

    my $http = $backend->new(
        agent      => "App::next/v" . $App::next::VERSION,
        timeout    => 60,
        verify_SSL => 1,
        %args,
    );

    my $keep_alive = exists $args{keep_alive} ? $args{keep_alive} : 1;
    if ( $keep_alive and $backend =~ /LWP$/ ) {
        $http->{ua}->conn_cache( { total_capacity => 1 } );
    }

    return $http;
}

1;
