use strict;
use warnings;
use inc::Module::Install;
use Module::Install::ReadmeFromPod;

all_from      'lib/Finance/Bank/JP/Mizuho.pm';
# readme_from   'lib/Finance/Bank/JP/Mizuho.pm';

requires      'Carp';
requires      'DateTime';
requires      'Encode';
requires      'Finance::OFX::Parse::Simple';
requires      'HTTP::Cookies';
requires      'IO::Socket::SSL';
requires      'LWP::UserAgent';

test_requires 'Config::Pit';
test_requires 'FindBin';
test_requires 'Test::More';


WriteAll;