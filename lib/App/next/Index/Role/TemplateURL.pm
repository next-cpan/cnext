package App::cplay::Index::Role::TemplateURL;

use App::cplay::std;    # import strict, warnings & features
use App::cplay::Logger;

use File::Basename qw(basename);

use Simple::Accessor qw{template_url};

sub _build_template_url($self) {    # fast parse version

    FATAL("'file' is not defined") unless defined $self->file && length $self->file;

    my $basename = basename( $self->file );

    open( my $fh, '<:utf8', $self->file ) or die "Cannot open $basename: $!";

    my $columns = {};
    my $ix      = 0;

    my $description;
    while ( my $line = <$fh> ) {
        next unless $line =~ m{^\s*"template_url"};
        if ( $line =~ m{"template_url"\s*:\s*["'](.+)["']\s*,} ) {
            return $1;
        }
        last;
    }

    FATAL("Cannot read template_url from $basename");

    return;
}

1;
