package App::next::Installer::Unpacker;

# Based on hhttps://github.com/skaji/cpm/blob/master/lib/App/cpm/Installer/Unpacker.pm

use App::next::std;

use App::next::IPC ();

use File::Basename ();
use File::Temp     ();
use File::Which    ();
use File::pushd;

sub new ( $class, %argv ) {
    my $self = bless \%argv, $class;

    $self->_init_untar;

    return $self;
}

sub unpack ( $self, $file ) {
    my $method = $self->{method}{untar};

    my $dir;
    $dir = pushd( $self->{tmproot} ) if $self->{tmproot};

    return $self->can($method)->( $self, $file );
}

sub _init_untar($self) {
    my $tar = $self->{tar} = File::Which::which('gtar') || File::Which::which("tar");
    if ($tar) {
        my ( $exit, $out, $err ) = App::next::IPC::run3 [ $tar, '--version' ];
        $self->{tar_kind} = $out      =~ /bsdtar/ ? "bsd" : "gnu";
        $self->{tar_bad}  = 1 if $out =~ /GNU.*1\.13/i || $^O eq 'MSWin32' || $^O eq 'solaris' || $^O eq 'hpux';
    }

    if ( $tar and !$self->{tar_bad} ) {
        $self->{method}{untar} = *_untar;
        return if !$self->{_init_all};
    }

    my $gzip  = $self->{gzip}  = File::Which::which("gzip");
    my $bzip2 = $self->{bzip2} = File::Which::which("bzip2");

    if ( $tar && $gzip && $bzip2 ) {
        $self->{method}{untar} = *_untar_bad;
        return if !$self->{_init_all};
    }

    if ( eval { require Archive::Tar } ) {
        $self->{"Archive::Tar"} = Archive::Tar->VERSION;
        $self->{method}{untar} = *_untar_module;
        return if !$self->{_init_all};
    }

    return if $self->{_init_all};
    $self->{method}{untar} = sub { die "There is no backend for untar" };
}

sub _untar ( $self, $file ) {
    my $wantarray = wantarray;

    my ( $exit, $out, $err );
    {
        my $ar = $file =~ /\.bz2$/ ? 'j' : 'z';
        ( $exit, $out, $err ) = App::next::IPC::run3 [ $self->{tar}, "${ar}tf", $file ];
        last if $exit != 0;
        my $root = $self->_find_tarroot( split /\r?\n/, $out );
        ( $exit, $out, $err ) = App::next::IPC::run3 [ $self->{tar}, "${ar}xf", $file, "-o" ];
        return $root if $exit == 0 and -d $root;
    }
    return if !$wantarray;
    return ( undef, $err || $out );
}

sub _untar_bad ( $self, $file ) {
    my $wantarray = wantarray;
    my ( $exit, $out, $err );
    {
        my $ar   = $file =~ /\.bz2$/ ? $self->{bzip2} : $self->{gzip};
        my $temp = File::Temp->new( SUFFIX => '.tar', EXLOCK => 0 );
        ( $exit, $out, $err ) = App::next::IPC::run3 [ $ar, "-dc", $file ], $temp->filename;
        last if $exit != 0;

        # XXX /usr/bin/tar: Cannot connect to C: resolve failed
        my @opt = $^O eq 'MSWin32' && $self->{tar_kind} ne "bsd" ? ('--force-local') : ();
        ( $exit, $out, $err ) = App::next::IPC::run3 [ $self->{tar}, @opt, "-tf", $temp->filename ];
        last if $exit != 0 || !$out;
        my $root = $self->_find_tarroot( split /\r?\n/, $out );
        ( $exit, $out, $err ) = App::next::IPC::run3 [ $self->{tar}, @opt, "-xf", $temp->filename, "-o" ];
        return $root if $exit == 0 and -d $root;
    }
    return if !$wantarray;
    return ( undef, $err || $out );
}

sub _untar_module ( $self, $file ) {
    my $wantarray = wantarray;
    no warnings 'once';
    local $Archive::Tar::WARN = 0;
    my $t = Archive::Tar->new;
    {
        my $ok = $t->read($file);
        last if !$ok;
        my $root = $self->_find_tarroot( $t->list_files );
        my @file = $t->extract;
        return $root if @file and -d $root;
    }
    return if !$wantarray;
    return ( undef, $t->error );
}

sub _find_tarroot ( $self, $root, @others ) {
  FILE: {
        chomp $root;
        $root =~ s!^\./!!;
        $root =~ s{^(.+?)/.*$}{$1};
        if ( !length $root ) {    # archive had ./ as the first entry, so try again
            $root = shift @others;
            redo FILE if $root;
        }
    }
    return $root;
}

1;
