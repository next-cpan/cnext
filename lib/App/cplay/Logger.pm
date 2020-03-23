package App::cplay::Logger;    # stolen from App::cpm::Logger

use App::cplay::std;

use List::Util 'max';

our $COLOR;
our $VERBOSE;
our $SHOW_PROGRESS;

use constant COLOR_RED    => 31;
use constant COLOR_GREEN  => 32;
use constant COLOR_YELLOW => 33;
use constant COLOR_BLUE   => 34;
use constant COLOR_PURPLE => 35;
use constant COLOR_CYAN   => 36;

my %color = (
    resolve   => COLOR_YELLOW,
    fetch     => COLOR_BLUE,
    configure => COLOR_PURPLE,
    install   => COLOR_CYAN,
    FAIL      => COLOR_RED,
    DONE      => COLOR_GREEN,
    WARN      => COLOR_YELLOW,
    INFO      => COLOR_GREEN,
);

sub new ( $class, @args ) {
    return bless {@args}, $class;
}

sub log ( $self, %options ) {

    my $type    = $options{type} || "";
    my $message = $options{message};
    chomp $message;

    my $optional      = $options{optional} ? " ($options{optional})" : "";
    my $result        = $options{result};
    my $is_color      = ref $self ? $self->{color} : $COLOR;
    my $verbose       = ref $self ? $self->{verbose} : $VERBOSE;
    my $show_progress = ref $self ? $self->{show_progress} : $SHOW_PROGRESS;

    if ( !$result ) {
        my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) = localtime(time);
        $year += 1900;
        $mon++;
        $result = sprintf(
            '[%04d-%02d-%02d %02d:%02d:%02d]',    # .
            $year, $mon, $mday,                   # .
            $hour, $min, $sec,                    # .
        );
    }

    if ($is_color) {
        $type   = "\e[$color{$type}m$type\e[m"     if $type   && $color{$type};
        $result = "\e[$color{$result}m$result\e[m" if $result && $color{$result};
        $optional = "\e[1;37m$optional\e[m" if $optional;
    }

    my $r = $show_progress ? "\r" : "";
    if ($verbose) {

        # type -> 5 + 9 + 3
        $type = $is_color && $type ? sprintf( "%-17s", $type ) : sprintf( "%-9s", $type || "" );
        warn $r . sprintf "%d %s %s %s%s\n", $options{pid} || $$, $result, $type, $message, $optional;
    }
    else {
        warn $r . join( " ", $result, $type ? $type : (), $message . $optional ) . "\n";
    }

    return;
}

sub DONE ( $self_or_class, $msg, @args ) {
    return $self_or_class->log( type => 'DONE', message => $msg, @args );
}

sub FAIL ( $self_or_class, $msg, @args ) {
    return $self_or_class->log( type => 'FAIL', message => $msg, @args );
}

sub WARN ( $self_or_class, $msg, @args ) {
    return $self_or_class->log( type => 'WARN', message => $msg, @args );
}

sub INFO ( $self_or_class, $msg, @args ) {
    return $self_or_class->log( type => 'INFO', message => $msg, @args );
}

sub fetch ( $self_or_class, $msg, @args ) {
    return $self_or_class->log( type => 'fetch', message => $msg, @args );
}

sub resolve ( $self_or_class, $msg, @args ) {
    return $self_or_class->log( type => 'resolve', message => $msg, @args );
}

sub configure ( $self_or_class, $msg, @args ) {
    return $self_or_class->log( type => 'configure', message => $msg, @args );
}

sub install ( $self_or_class, $msg, @args ) {
    return $self_or_class->log( type => '', message => $msg, @args );
}

1;

=pod

    use App::cplay::Logger;

    #App::cplay::Logger->INFO( "One information" );
    App::cplay::Logger->FAIL( "This just failed" );
    App::cplay::Logger->WARN( "This is a warning" );
    App::cplay::Logger->resolve( "Resolving something" );
    App::cplay::Logger->fetch( "Fetching something" );
    App::cplay::Logger->fetch( "configuring something" );
    App::cplay::Logger->fetch( "installing something" );

    App::cplay::Logger->DONE( "This is now done" );
    App::cplay::Logger->DONE( "This is now done", optional => 'xyz' );

    App::cplay::Logger->log(result => "INFO", type => 'DONE', message => 'this is a message');
    App::cplay::Logger->log(result => "INFO", type => 'FAIL', message => 'this is a message');
    App::cplay::Logger->log(result => "INFO", type => 'WARN', message => 'this is a message');
    App::cplay::Logger->log(result => "INFO", type => 'resolve', message => 'this is a message');
    App::cplay::Logger->log(result => "INFO", type => 'fetch', message => 'this is a message');
    App::cplay::Logger->log(result => "INFO", type => 'configure', message => 'this is a message');
    App::cplay::Logger->log(result => "INFO", type => 'install', message => 'this is a message');

=cut
