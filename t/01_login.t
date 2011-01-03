use strict;
use warnings;
use FindBin;
use lib "$FindBin::RealBin/../lib";
use Test::More;
use Finance::Bank::JP::Mizuho;
use YAML;
use Data::Dumper;

my $m = Finance::Bank::JP::Mizuho->new( account_id => '12345678' );
my $config_file = $ENV{MIZUHO_TEST_CONFIG};
my $config = $config_file ? YAML::LoadFile($config_file) : undef;

SKIP: {
    is $m->account_id, '12345678';

    is $m->form1_action(
        qq{<FORM action="https://mydomain.tld/path/to/app.do" name="FORM1" onSubmit="doSomething();return false;">
            HOGEHOGE
        </FORM>}),
        'https://mydomain.tld/path/to/app.do',
        'form1_action';

    skip 'offline', 2;
    
    like
        $m->login_url1,
        qr{^https://web\d*.ib.mizuhobank.co.jp/servlet/mib\?xtr=Emf00000$},
        'login url 1';

    like
        $m->login_url2,
        qr{https://web\d*\.ib\.mizuhobank\.co\.jp:443/servlet/mib\?xtr=Emf00100&NLS=JP},
        'login url 2';
}
{
    is
        $m->parse_question(
            q{
                <TR>
                    <TD width="200" align="right"><DIV style="font-size:9pt">質問：</DIV></TD> 
                    <TD width="390" align="left"><DIV style="font-size:9pt">母親の誕生日はいつですか（例：５月１４日）</DIV></TD> 
                </TR>
            }),
            '母親の誕生日はいつですか（例：５月１４日）',
            'parse_question';
}
SKIP: {
    skip 'set MIZUHO_TEST_CONFIG to environment variables', 1 unless $config;
    $m->logout;
    $m = Finance::Bank::JP::Mizuho->new( %{ $config } );
    
    
    warn Dumper($config);
    ok 1;
    $m->question1;
    $m->logout;
}

done_testing;


