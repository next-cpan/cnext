package App::cplay::Logger;    # stolen from App::cpm::Logger

use App::cplay::std;

use List::Util 'max';

use Exporter 'import';

our @EXPORT    = qw{OK DONE FAIL ERROR WARN INFO DEBUG FATAL};
our @EXPORT_OK = ( @EXPORT, qw(fetch resolve install configure) );

our $COLOR;
our $VERBOSE;
our $DEBUG;
our $SHOW_PROGRESS;

BEGIN {
    $COLOR = 1 if -t STDIN;
}

use constant COLOR_RED    => 31;
use constant COLOR_GREEN  => 32;
use constant COLOR_YELLOW => 33;
use constant COLOR_BLUE   => 34;
use constant COLOR_PURPLE => 35;
use constant COLOR_CYAN   => 36;
use constant COLOR_WHITE  => 7;

my %color = (
    resolve   => COLOR_YELLOW,
    fetch     => COLOR_BLUE,
    configure => COLOR_PURPLE,
    install   => COLOR_CYAN,
    FAIL      => COLOR_RED,
    ERROR     => COLOR_RED,      # maybe merge with FAIL ?
    FATAL     => COLOR_RED,
    DONE      => COLOR_GREEN,
    OK        => COLOR_GREEN,
    WARN      => COLOR_YELLOW,
    INFO      => COLOR_GREEN,
    DEBUG     => COLOR_WHITE,
);

sub new ( $class, @args ) {
    return bless {@args}, $class;
}

sub log ( $self_or_class, %options ) {

    my $type    = $options{type} || "";
    my $message = $options{message};
    chomp $message;

    my $optional      = $options{optional} ? " ($options{optional})" : "";
    my $result        = $options{result};
    my $is_color      = ref $self_or_class ? $self_or_class->{color} : $COLOR;
    my $verbose       = ref $self_or_class ? $self_or_class->{verbose} : $VERBOSE;
    my $show_progress = ref $self_or_class ? $self_or_class->{show_progress} : $SHOW_PROGRESS;

    if ( !$result && $DEBUG ) {
        my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) = localtime(time);
        $year += 1900;
        $mon++;
        $result = sprintf(
            '[%04d-%02d-%02d %02d:%02d:%02d]',    # .
            $year, $mon, $mday,                   # .
            $hour, $min, $sec,                    # .
        );
    }
    $result //= '';

    if ($is_color) {
        $type   = "\e[$color{$type}m$type\e[m"     if $type   && $color{$type};
        $result = "\e[$color{$result}m$result\e[m" if $result && $color{$result};
        $optional = "\e[1;37m$optional\e[m" if $optional;
    }

    my $r = $show_progress ? "\r" : "";
    if ($verbose) {

        # type -> 5 + 9 + 3
        $type = $is_color && $type ? sprintf( "%-17s", $type ) : sprintf( "%-9s", $type || "" );
        warn $r . sprintf "%s %s %s%s\n", $result, $type, $message, $optional;
    }
    else {
        warn $r . join( " ", map { defined $_ ? $_ : () } $result, $type, $message . $optional ) . "\n";
    }

    return;
}

# only informations with errors displayed when not using --verbose
sub OK ( $msg, @args ) {

    # always displayed
    return __PACKAGE__->log( type => 'OK', message => $msg, @args );
}

sub DONE ( $msg, @args ) {
    return unless $VERBOSE;
    return __PACKAGE__->log( type => 'DONE', message => $msg, @args );
}

sub DEBUG ( $msg, @args ) {
    return unless $DEBUG;
    return __PACKAGE__->log( type => 'DEBUG', message => $msg, @args );
}

sub FAIL ( $msg, @args ) {
    return __PACKAGE__->log( type => 'FAIL', message => $msg, @args );
}

sub ERROR ( $msg, @args ) {
    return __PACKAGE__->log( type => 'ERROR', message => $msg, @args );
}

sub FATAL ( $msg, @args ) {
    __PACKAGE__->log( type => 'FATAL', message => $msg, @args );
    die $msg;
}

sub WARN ( $msg, @args ) {
    return unless $VERBOSE;
    return __PACKAGE__->log( type => 'WARN', message => $msg, @args );
}

sub INFO ( $msg, @args ) {
    return unless $VERBOSE;
    return __PACKAGE__->log( type => 'INFO', message => $msg, @args );
}

sub fetch ( $msg, @args ) {
    return unless $VERBOSE;
    return __PACKAGE__->log( type => 'fetch', message => $msg, @args );
}

sub resolve ( $msg, @args ) {
    return unless $VERBOSE;
    return __PACKAGE__->log( type => 'resolve', message => $msg, @args );
}

sub configure ( $msg, @args ) {
    return unless $VERBOSE;
    return __PACKAGE__->log( type => 'configure', message => $msg, @args );
}

sub install ( $msg, @args ) {
    return unless $VERBOSE;
    return __PACKAGE__->log( type => 'install', message => $msg, @args );
}

1;

=pod

    use App::cplay::Logger; # DONE INFO FAIL WARN imported

    INFO( "One information" );
    FAIL( "This just failed" );
    WARN( "This is a warning" );

    use App::cplay::Logger qw{resolve fetch configure install};

    resolve( "Resolving something" );
    fetch( "Fetching something" );
    configure( "configuring something" );
    install( "installing something" );

    DONE( "This is now done" );
    DONE( "This is now done", optional => 'xyz' );

    App::cplay::Logger->log(result => "INFO", type => 'DONE', message => 'this is a message');
    App::cplay::Logger->log(result => "INFO", type => 'FAIL', message => 'this is a message');
    App::cplay::Logger->log(result => "INFO", type => 'WARN', message => 'this is a message');
    App::cplay::Logger->log(result => "INFO", type => 'resolve', message => 'this is a message');
    App::cplay::Logger->log(result => "INFO", type => 'fetch', message => 'this is a message');
    App::cplay::Logger->log(result => "INFO", type => 'configure', message => 'this is a message');
    App::cplay::Logger->log(result => "INFO", type => 'install', message => 'this is a message');

=cut
