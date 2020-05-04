package App::cplay::cmd::search;

use App::cplay::std;

use App::cplay::Logger;    # import all
use App::cplay::Installer;

sub run ( $cli, @patterns ) {
    if ( !scalar @patterns ) {
        ERROR("search needs one or more arguments");
        return 1;
    }

    foreach my $pattern (@patterns) {
        INFO("Search results for: $pattern");

        # a.*
        my $lookup = $pattern;
        $lookup =~ s{\Q.*\E}{*}g;
        $lookup =~ s{\Q*\E}{.*}g;

        $lookup =~ s{^\s+}{};
        $lookup =~ s{\s+$}{};

        my $result = $cli->modules_idx->regexp_search($lookup);

        my $repositories = $result->list_repositories;

        my $count_repos = scalar @$repositories;
        if ($count_repos) {
            OK("Found $count_repos respositories matching '$pattern'");
            foreach my $repo (@$repositories) {
                say $repo;
            }
        }

        my $modules = $result->list_modules;

        my $count_modules = scalar @$modules;
        if ($count_modules) {
            OK("Found $count_modules modules matching '$pattern'");
            foreach my $module (@$modules) {
                say $module;
            }
        }

        if ( !$count_modules && !$count_repos ) {
            ERROR("no results found for '$pattern'");
            return 1;
        }

    }

    return 0;
}

1;

__END__
