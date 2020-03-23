package App::cplay::Index::Modules;

use App::cplay::std;    # import strict, warnings & features
use App::cplay::Index;

use Simple::Accessor qw{file cli};

sub build ( $self, %opts ) {

    $self->{file} = App::cplay::Index::get_modules_ix_file( $self->cli );

    return $self;
}

1;
