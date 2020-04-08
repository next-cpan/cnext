#!perl

use FindBin;
use lib $FindBin::Bin . '/../fatlib';

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use Test::MockModule;

use App::cplay::std;
use App::cplay::InstallDirs;

use Config;

is App::cplay::InstallDirs::_get_config, \%Config,
  "_get_config is using Config by default";

my %cfg;
my $mock = Test::MockModule->new('App::cplay::InstallDirs');
$mock->redefine( _get_config => sub { \%cfg } );

%cfg = (
    installarchlib        => '/usr/local/xtra/3rdparty/perl/530/lib/perl5/5.30.0/x86_64-linux-64int',
    installbin            => '/usr/local/xtra/3rdparty/perl/530/bin',
    installhtml1dir       => '',
    installhtml3dir       => '',
    installman1dir        => '',
    installman3dir        => '',
    installprefix         => '/usr/local/xtra/3rdparty/perl/530',
    installprefixexp      => '/usr/local/xtra/3rdparty/perl/530',
    installprivlib        => '/usr/local/xtra/3rdparty/perl/530/lib/perl5/5.30.0',
    installscript         => '/usr/local/xtra/3rdparty/perl/530/bin',
    installsitearch       => '/opt/cpanel/perl5/530/site_lib/x86_64-linux-64int',
    installsitebin        => '/opt/cpanel/perl5/530/bin',
    installsitehtml1dir   => '',
    installsitehtml3dir   => '',
    installsitelib        => '/opt/cpanel/perl5/530/site_lib',
    installsiteman1dir    => '',
    installsiteman3dir    => '',
    installsitescript     => '/opt/cpanel/perl5/530/bin',
    installstyle          => 'lib',
    installusrbinperl     => undef,
    installvendorarch     => '/usr/local/xtra/3rdparty/perl/530/lib/perl5/cpanel_lib/x86_64-linux-64int',
    installvendorbin      => '/usr/local/xtra/3rdparty/perl/530/bin',
    installvendorhtml1dir => '',
    installvendorhtml3dir => '',
    installvendorlib      => '/usr/local/xtra/3rdparty/perl/530/lib/perl5/cpanel_lib',
    installvendorman1dir  => '',
    installvendorman3dir  => '',
    installvendorscript   => '/usr/local/xtra/3rdparty/perl/530/bin',
);

{
    note "App::cplay::InstallDirs->new()";
    my $dirs = App::cplay::InstallDirs->new();
    is $dirs->type, 'site', 'default type is site';
    is $dirs->arch,   $cfg{installsitearch},    'arch';
    is $dirs->lib,    $cfg{installsitelib},     'lib';
    is $dirs->bin,    $cfg{installsitebin},     'bin';
    is $dirs->script, $cfg{installsitescript},  'script';
    is $dirs->man1,   $cfg{installsiteman1dir}, 'man1';
    is $dirs->man3,   $cfg{installsiteman3dir}, 'man3';
}

{
    note "App::cplay::InstallDirs->new( type => 'site' )";
    my $dirs = App::cplay::InstallDirs->new( type => 'site' );
    is $dirs->type, 'site', 'type';
    is $dirs->arch,   $cfg{installsitearch},    'arch';
    is $dirs->lib,    $cfg{installsitelib},     'lib';
    is $dirs->bin,    $cfg{installsitebin},     'bin';
    is $dirs->script, $cfg{installsitescript},  'script';
    is $dirs->man1,   $cfg{installsiteman1dir}, 'man1';
    is $dirs->man3,   $cfg{installsiteman3dir}, 'man3';
}

{
    note "App::cplay::InstallDirs->new( type => 'perl' )";
    my $dirs = App::cplay::InstallDirs->new( type => 'perl' );
    is $dirs->type, 'perl', 'type';
    is $dirs->arch,   $cfg{installarchlib}, 'arch';
    is $dirs->lib,    $cfg{installprivlib}, 'lib';
    is $dirs->bin,    $cfg{installbin},     'bin';
    is $dirs->script, $cfg{installscript},  'script';
    is $dirs->man1,   $cfg{installman1dir}, 'man1';
    is $dirs->man3,   $cfg{installman3dir}, 'man3';

}

{
    note "App::cplay::InstallDirs->new( type => 'vendor' )";
    my $dirs = App::cplay::InstallDirs->new( type => 'vendor' );
    is $dirs->type, 'vendor', 'type';
    is $dirs->arch,   $cfg{installvendorarch},    'arch';
    is $dirs->lib,    $cfg{installvendorlib},     'lib';
    is $dirs->bin,    $cfg{installvendorbin},     'bin';
    is $dirs->script, $cfg{installvendorscript},  'script';
    is $dirs->man1,   $cfg{installvendorman1dir}, 'man1';
    is $dirs->man3,   $cfg{installvendorman3dir}, 'man3';
}

# {
#     delete $cfg{installsitebin};
#     like(
#         dies {
#             App::cplay::InstallDirs->new();
#         },
#         qr/'installsitebin' not set in Config/,
#         "'installsitebin' not set in Config"
#     );
# }

note "Testing some common errors";
{
    like(
        dies {
            App::cplay::InstallDirs->new( type => 'unknown' );
        },
        qr/Invalid type unknown/,
        "App::cplay::InstallDirs->new( type => 'unknown' ) dies"
    );
}

{
    like(
        dies {
            App::cplay::InstallDirs->new(
                type      => 'site',
                something => 'boom'
            );
        },
        qr/Too many arguments to new: something/,
        "type + extra key in new"
    );
}

{
    like(
        dies {
            App::cplay::InstallDirs->new( extra => 'boom' );
        },
        qr/Too many arguments to new: extra/,
        "extra key in new"
    );
}

done_testing;
