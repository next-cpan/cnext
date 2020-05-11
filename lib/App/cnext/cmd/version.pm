package App::cnext::cmd::version;

use App::cnext::std;

sub run ( $self, @argv ) {

    my $version  = $App::cnext::VERSION;
    my $revision = $App::cnext::REVISION;

    say "cnext $version\@$revision ($0)";

    return;
}

1;
