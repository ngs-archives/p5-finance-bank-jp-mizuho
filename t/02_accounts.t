use strict;
use warnings;
use FindBin;
use lib "$FindBin::RealBin/../lib";
use Test::More;
use Finance::Bank::JP::Mizuho;
use YAML;
use Data::Dumper;

my $config_file = $ENV{MIZUHO_TEST_CONFIG};
my $config = $config_file ? YAML::LoadFile($config_file) : undef;

{
    my $m = Finance::Bank::JP::Mizuho->new;
    $m->parse_accounts(q{
<TR BGCOLOR="#FFFFFF">
    <TD width="30"  align="center"><INPUT TYPE=radio NAME="SelectRadio" value="0"></TD>
    <TD width="150" align="left"><DIV STYLE="font-size:9pt">&nbsp;目黒支店</DIV></TD>
    <TD width="100" align="left"><DIV STYLE="font-size:9pt">&nbsp;普通</DIV></TD>
    <TD width="100" align="center"><DIV STYLE="font-size:9pt">12345678</DIV></TD>
    <TD width="190" align="center"><DIV STYLE="font-size:9pt">2010.08.01&nbsp;～&nbsp;2010.09.01</DIV></TD>
</TR>
<TR BGCOLOR="#E6DFEE">
    <TD width="30"  align="center"><INPUT TYPE=radio NAME="SelectRadio" value="1"></TD>
    <TD width="150" align="left"><DIV STYLE="font-size:9pt">&nbsp;恵比寿支店</DIV></TD>
    <TD width="100" align="left"><DIV STYLE="font-size:9pt">&nbsp;当座</DIV></TD>
    <TD width="100" align="center"><DIV STYLE="font-size:9pt">87654321</DIV></TD>
    <TD width="190" align="center"><DIV STYLE="font-size:9pt">2010.02.01&nbsp;～&nbsp;2010.03.01</DIV></TD>
</TR>
<TR BGCOLOR="#FFFFFF">
    <TD width="30"  align="center"><INPUT TYPE=radio NAME="SelectRadio" value="2"></TD>
    <TD width="150" align="left"><DIV STYLE="font-size:9pt">&nbsp;恵比寿支店</DIV></TD>
    <TD width="100" align="left"><DIV STYLE="font-size:9pt">&nbsp;普通</DIV></TD>
    <TD width="100" align="center"><DIV STYLE="font-size:9pt">10002000</DIV></TD>
    <TD width="190" align="center"><DIV STYLE="font-size:9pt">2010.04.01</DIV></TD>
</TR>
    });
    is_deeply( $m->accounts, [
        {
            branch => '目黒支店',
            type   => '普通',
            radio_value => '0',
            number => '12345678',
            last_downloaded => {
                start => '2010-08-01',
                end   => '2010-09-01',
            },
        },
        {
            branch => '恵比寿支店',
            type   => '当座',
            radio_value => '1',
            number => '87654321',
            last_downloaded => {
                start => '2010-02-01',
                end   => '2010-03-01',
            },
        },
        {
            branch => '恵比寿支店',
            type   => '普通',
            radio_value => '2',
            number => '10002000',
            last_downloaded => {
                start => '2010-04-01',
                end   => '2010-04-01',
            },
        }
    ]);

}

SKIP: {
    skip 'set MIZUHO_TEST_CONFIG to environment variables', 1 unless $config;
    my $m = Finance::Bank::JP::Mizuho->new( %{ $config } );
    eval {
        $m->login;
        ok $m->accounts;
        diag(Dumper($m->accounts));
    };
    $m->logout;
    warn $@ if $@;
    ok !$@;
}

done_testing;


