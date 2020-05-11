package App::cplay::Search::Result;

use App::cplay::std;       # import strict, warnings & features
use App::cplay::Logger;    # import all

use Simple::Accessor qw{_modules _repositories};

sub _build__modules      { {} }
sub _build__repositories { {} }

sub add_module ( $self, $name ) {
    $self->_modules->{$name} = 1;
    return;
}

sub add_repository ( $self, $name ) {
    $self->_repositories->{$name} = 1;
    return;
}

sub list_modules($self) {
    return [ sort keys %{ $self->_modules } ];
}

sub list_repositories($self) {
    return [ sort keys %{ $self->_repositories } ];
}

1;
