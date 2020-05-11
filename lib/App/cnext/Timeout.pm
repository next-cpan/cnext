package App::cnext::Timeout;

use App::cnext::std;    # import strict, warnings & features
use App::cnext::Logger;

use Simple::Accessor qw{timeout message prevsig};

sub run ( $self, $code ) {

    local $SIG{'ALRM'} = sub { FATAL $self->message; die };

    alarm( $self->timeout );
    my @out = $code->();
    alarm(0);

    return @out;
}

1;
