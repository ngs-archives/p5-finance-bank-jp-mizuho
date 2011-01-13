use strict;
use warnings;
use FindBin;
use lib "$FindBin::RealBin/../lib";
use Test::More;
use Config::Pit;
use Data::Dumper;

my $config;

BEGIN {
    my $config_name = $ENV{MIZUHO_TEST_CONFIG} || 'web.ib.mizuhobank.co.jp';
    $config = pit_get($config_name);
    plan skip_all => 'No config' unless $config && $config->{consumer_id};
    use_ok 'Finance::Bank::JP::Mizuho';
}

{
    my $m = Finance::Bank::JP::Mizuho->new(%$config);
    
    $m->login or plan skip_all => 'Login failure';
    
    like $m->host, qr{^web\d*\.ib\.mizuhobank\.co\.jp$}, 'host';
    ok @{ $m->accounts }, 'number accounts is larger than 0';
    
    ok $m->get_raw_ofx( $m->accounts->[0], $m->SAME_AS_LAST ), 'Raw OFX';
    is ref $m->get_ofx( $m->accounts->[0], $m->SAME_AS_LAST ), 'ARRAY', 'OFS is ARRAY';
    
    $m->logout;
}

done_testing;