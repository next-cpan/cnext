package App::next::Signature;

use App::next::std;    # import strict, warnings & features

use App::next::Logger;

use Digest::Perl::MD5;    # fatpack in

use Exporter 'import';

our @EXPORT    = qw{check_signature};
our @EXPORT_OK = @EXPORT;

sub check_signature ( $file, $expect ) {
    return unless -e $file && defined $expect;

    open( my $fh, '<:utf8', $file ) or die "Cannot open file $file: $!";

    my $ctx = _get_ctx();
    $ctx->addfile($fh);

    return $ctx->hexdigest eq $expect;
}

sub _get_ctx {
    state $warn_once;

    # try using the XS version if possible
    if ( eval q{require Digest::MD5; 1 } ) {
        return Digest::MD5->new;
    }

    if ( !$warn_once ) {
        $warn_once = 1;
        WARN("Consider installing Digest::MD5, using Digest::Perl::MD5");
    }

    return Digest::Perl::MD5->new;
}

1;
