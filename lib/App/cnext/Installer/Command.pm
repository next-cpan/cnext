package App::cnext::Installer::Command;

use App::cnext::std;    # import strict, warnings & features
use App::cnext::Logger;

use App::cnext::Timeout ();

use Simple::Accessor qw{txt cmd timeout env log_level};

use App::cnext::IPC ();

# maybe consider using Command::Runner

sub _build_log_level { 'install' }
sub _build_cmd       { FATAL("cmd not defined for Command") }
sub _build_timeout   { 0 }
sub _build_env       { {} }

sub _build_txt($self) {
    return $self->cmd unless ref $self->cmd;

    return join( ' ', @{ $self->cmd } );
}

sub run($self) {
    my $log_level = $self->log_level;

    my $log_type = App::cnext::Logger->can($log_level) or FATAL("Unknown helper to log $log_level");
    $log_type->( "running " . $self->txt );

    my ( $status, $out, $err );
    my $todo = sub { ( $status, $out, $err ) = App::cnext::IPC::run3( $self->cmd, $self->log_level ) };

    local %ENV = ( %ENV, %{ $self->env } );

    if ( $self->timeout ) {
        App::cnext::Timeout->new(
            message => q[Reach timeout while running ] . $self->txt,
            timeout => $self->timeout,
        )->run($todo);
    }
    else {
        $todo->();
    }

    if ( $status != 0 ) {
        ERROR( "Fail to run " . $self->txt );
        return;
    }

    return 1;
}

1;
