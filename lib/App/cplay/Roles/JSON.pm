package App::cplay::Roles::JSON;

use App::cplay::std;    # import strict, warnings & features

use JSON::PP ();

use Simple::Accessor qw{json};

sub _build_json($self) {
    return JSON::PP->new->utf8->relaxed->allow_nonref;
}

1;
