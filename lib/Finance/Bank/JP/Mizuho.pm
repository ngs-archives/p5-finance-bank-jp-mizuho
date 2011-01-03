package Finance::Bank::JP::Mizuho;

use strict;

use Carp 'croak';
use LWP::UserAgent;
use HTTP::Cookies;
use Data::Dumper;
use Encode;

our $VERSION = '0.01';

use constant USER_AGENT => 'Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1)';
use constant START_URL  => 'http://www.mizuhobank.co.jp/direct/start.html';
use constant ENCODING   => 'shift_jis';

sub fp_version  { q{1} }
sub fp_browser  { q{mozilla/5.0 (macintosh; u; intel mac os x 10_6_5; en-us) applewebkit/534.10 (khtml, like gecko) chrome/8.0.552.231 safari/534.10|5.0 (Macintosh; U; Intel Mac OS X 10_6_5; en-US) AppleWebKit/534.10 (KHTML, like Gecko) Chrome/8.0.552.231 Safari/534.10|MacIntel|en-US} }
sub fp_display  { q{24|1280|800|800} }
sub fp_software { q{} }
sub fp_timezone { q{9} }
sub fp_language { q{lang=en-US|syslang=|userlang=} }
sub fp_java     { q{1} }
sub fp_cookie   { q{1} }

sub device_fingerprint {
    my $self = shift;
    my ($v,$ua,$sc,$sw,$tz,$ln,$jv,$co) = (
        $self->fp_version,
        $self->fp_browser,
        $self->fp_display,
        $self->fp_software,
        $self->fp_timezone,
        $self->fp_language,
        $self->fp_java,
        $self->fp_cookie,
    );
    qq{version=$v&}.
    qq{pm_fpua=$ua&}.
    qq{pm_fpsc=$sc&}.
    qq{pm_fpsw=$sw&}.
    qq{pm_fptz=$tz&}.
    qq{pm_fpln=$ln&}.
    qq{pm_fpjv=$jv&}.
    qq{pm_fpco=$co}
}

sub new {
    my $class = shift;
    my $self = bless { @_ }, $class;
    $self;
}

sub ua {
    shift->{ua} ||= LWP::UserAgent->new(
        agent => USER_AGENT,
        cookie_jar => HTTP::Cookies->new,
    )
}

sub account_id { shift->{account_id} }
sub questions  { shift->{questions}  }
sub password   { shift->{password}   }
sub logged_in  {
    my $self = shift;
    $self->{logged_in} = shift if @_;
    $self->{logged_in};
}

sub host {
    my $self = shift;
    return $self->{host} if $self->{host};
    ( $self->{host} = $self->get_content(START_URL) ) =~ s%.*url=https://([^/]+)(:?[^"]+)".*|.*(:?[\r\n]?)%$1%ig;
    $self->{host}
}

sub login_url1 { 'https://'. shift->host . '/servlet/mib?xtr=Emf00000' }
sub logout_url { 'https://'. shift->host . ':443/servlet/mib?xtr=EmfLogOff&NLS=JP' }

sub login_url2 {
    my $self = shift;
    my $action = $self->form1_action($self->get_content($self->login_url1));
    my $res = $self->ua->post( $action, [
        pm_fp => $self->device_fingerprint,
        KeiyakuNo => $self->account_id,
        Next => encode(ENCODING,' 次 へ '),
    ]);
    $res->header('location');
}

sub question {
    my ($self,$url) = @_;
    $url ||= $self->login_url2;
    if($url=~m{xtr=Emf00005}) {
        $self->login($url);
        return;
    }
    my $content = $self->get_content($url);
    my $action = $self->form1_action($content);
    my $question = $self->parse_question($content);
    die 'Failed to parse question screen' unless $question;
    my $answer = $self->questions->{$question};
    die "No answer for '$question'" unless $answer;
    my $res = $self->ua->post( $action, [
        rskAns => encode(ENCODING, $answer),
        Next => encode(ENCODING,'　次へ　'),
        NLS => 'JP',
        Token => '',
        jsAware => 'on',
        frmScrnID => 'Emf00000',
    ]);
    my $dest = $res->header('location');
    warn $dest;
    die 'Login failure' unless $dest;
    if($dest eq $url) {
        $self->question($url);
    } else {
        $self->login($dest);
    }
}

sub login {
    my ($self,$url) = @_;
    my $content = $self->get_content($url);
    my $action = $self->form1_action($content);
    my $res = $self->ua->post( $action, [
        NLS => 'JP',
        jsAware => 'on',
        pmimg => '0',
        Anshu1No => $self->password,
        login => encode(ENCODING,'　ログイン　'),
    ]);
    my $dest = $res->header('location');
    die 'Login failure' unless $dest;
    $self->logged_in(1);
    my $frame = $self->get_content($dest);
}


sub parse_question {
    my ($self,$content) = @_;
    ( my $q = $content ) =~ s%.*<TD width="200" align="right"><DIV style="font-size:9pt">.+[^\n\r]*[\n\r].*<DIV[^>]*>([^<]+)<.*|.*(:?[\r\n]?)%$1%ig;
    $q
}

sub get_content {
    my ($self,$url) = @_;
    my $res = $self->ua->get($url);
    die $res->status_line unless $res->is_success;
    decode(ENCODING,$res->content);
}

sub logout {
    my $self = shift;
    return unless $self->logged_in;
    my $ua = $self->ua;
    my $res = $ua->get($self->logout_url);
    $ua->cookie_jar->clear;
    $self->logged_in(0);
}

sub form1_action {
    my ($self,$content) = @_;
    my $url;
    ( $url = $content ) =~ s%.*action="([^"]+)"[^\n\r]+name="FORM1".*|.*(:?[\r\n]?)%$1%ig;
    return $url if $url;
    ( $url = $content ) =~ s%.*name="FORM1"[^\n\r]+action="([^"]+)".*|.*(:?[\r\n]?)%$1%ig;
    $url;
}


1
