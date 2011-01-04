use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Finance::Bank::JP::Mizuho',
    AUTHOR              => q{Atsushi Nagase <ngs@cpan.org>},
    VERSION_FROM        => 'lib/Finance/Bank/JP/Mizuho.pm',
    ABSTRACT_FROM       => 'lib/Finance/Bank/JP/Mizuho.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002 ? ('LICENSE' => 'perl') : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Date::Parse' => 0,
        'Encode' => 0,
        'HTTP::Cookies' => 0,
        'IO::Socket::SSL' => 0,
        'LWP::UserAgent' => 0,
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Finance-Bank-JP-Mizuho-*' },
);
