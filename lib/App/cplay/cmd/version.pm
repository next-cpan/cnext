package App::cplay::cmd::version;

use App::cplay::std;

sub run ( $self, @argv ) {

    my $version  = $App::cplay::VERSION;
    my $revision = $App::cplay::REVISION;

    say "cplay $version\@$revision ($0)";

    return;
}

1;
