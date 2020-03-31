package App::cplay::Installer::Command;

use App::cplay::std;    # import strict, warnings & features
use App::cplay::Logger;

use App::cplay::Timeout ();

use Simple::Accessor qw{type txt cmd timeout};

use App::cplay::IPC ();

sub _build_type       { 'install' }
sub _build_txt($self) { $self->cmd }
sub _build_cmd        { FATAL("cmd not defined for Command") }
sub _build_timeout    { 0 }

sub run($self) {
    my $type = $self->type;

    my $log_type = App::cplay::Logger->can($type) or FATAL("Unknown helper to log $type");
    $log_type->( "running " . $self->txt );

    my ( $status, $out, $err );
    my $todo = sub { ( $status, $out, $err ) = App::cplay::IPC::run3( $self->cmd ) };

    if ( $self->timeout ) {
        App::cplay::Timeout->new(
            message => q[Reach timeout while running ] . $self->txt,
            timeout => $self->timeout,
        )->run($todo);
    }
    else {
        $todo->();
    }

    if ( $status != 0 ) {
        ERROR( "Fail to run " . $self->txt );
        WARN($out)  if defined $out;
        ERROR($err) if defined $err;
        return;
    }

    $out //= '';
    DEBUG( $self->txt . " output:\n$out" );

    return 1;
}

1;
