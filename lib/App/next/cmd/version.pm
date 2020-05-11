package App::next::cmd::version;

use App::next::std;

sub run ( $self, @argv ) {

    my $version  = $App::next::VERSION;
    my $revision = $App::next::REVISION;

    say "cnext $version\@$revision ($0)";

    return;
}

1;
