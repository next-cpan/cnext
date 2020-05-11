package App::cnext::Roles::JSON;

use App::cnext::std;    # import strict, warnings & features

use JSON::PP ();

use Simple::Accessor qw{json};

sub _build_json($self) {
    return JSON::PP->new->utf8->relaxed->allow_nonref;
}

1;
