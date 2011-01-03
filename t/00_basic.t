use strict;
use warnings;
use FindBin;
use lib "$FindBin::RealBin/../lib";
use Test::More;

BEGIN { use_ok 'Finance::Bank::JP::Mizuho' }

{
    ok ( Finance::Bank::JP::Mizuho->new, 'new' );
}

done_testing;

