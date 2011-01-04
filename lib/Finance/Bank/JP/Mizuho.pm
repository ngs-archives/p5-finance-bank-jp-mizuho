package Finance::Bank::JP::Mizuho;

use strict;

use Data::Dumper;
use Date::Parse;
use Encode;
use HTTP::Cookies;
use LWP::UserAgent;

our $VERSION = '0.01';

use constant USER_AGENT => 'Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1)';
use constant START_URL  => 'http://www.mizuhobank.co.jp/direct/start.html';
use constant ENCODING   => 'shift_jis';

sub new {
    my $class = shift;
    my $self = bless { @_ }, $class;
    $self;
}

sub ua {
    shift->{ua} ||= LWP::UserAgent->new(
        agent => USER_AGENT,
        cookie_jar => HTTP::Cookies->new,
        max_redirect => 0,
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
    $self->{host} = shift if @_;
    return $self->{host} if $self->{host};
    $self->{host} || 'web.ib.mizuhobank.co.jp'
}

sub login_url1 { 'https://'. shift->host .'/servlet/mib?xtr=Emf00000' }
sub logout_url { 'https://'. shift->host . ':443/servlet/mib?xtr=EmfLogOff&NLS=JP' }
sub list_url   { 'https://'. shift->host . '/servlet/mib?xtr=Emf04610&NLS=JP' }

sub login_url2 {
    my $self = shift;
    my $action = $self->form1_action($self->get_content($self->login_url1));
    my $res = $self->ua->post( $action, [
        pm_fp => '',
        KeiyakuNo => $self->account_id,
        Next => encode(ENCODING,' 次 へ '),
    ]);
    my $url = $res->header('location');
    ( my $host = $url ) =~ s%^https://([^/\:]+).*%$1%;
    $self->host($host);
    $url;
}

sub login {
    my $self = shift;
    my $url = $self->login_url2;
    ($url=~m{xtr=Emf00005}) ?
        $self->_login($url) :
        $self->_question($url);
}

sub _question {
    my ($self,$url) = @_;
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
    die 'Login failure' unless $dest;
    if($dest eq $url) {
        $self->_question($url);
    } else {
        $self->_login($dest);
    }
}

sub _login {
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
}

sub parse_question {
    my ($self,$content) = @_;
    ( my $q = $content ) =~ s%.*<TD width="200" align="right"><DIV style="font-size:9pt">.+[^\n\r]*[\n\r].*<DIV[^>]*>([^<]+)<.*|.*(:?[\r\n]?)%$1%ig;
    $q
}

sub parse_accounts {
    my ($self,$content) = @_;
    $content =~ s/[\s"\r\n\t]//g;
    my $re = 
        q{<TDwidth=30[^>]*><INPUT.*NAME=SelectRadio.*value=(\d+)[^>]*></TD>}.
        q{<TDwidth=150[^>]*><DIV[^>]*>&nbsp;([^<]+)</DIV></TD>}.
        q{<TDwidth=100[^>]*><DIV[^>]*>&nbsp;([^<]+)</DIV></TD>}.
        q{<TDwidth=100[^>]*><DIV[^>]*>(\d+)</DIV></TD>}.
        q{<TDwidth=190[^>]*><DIV[^>]*>([^<]+)</DIV></TD>};

    my @tr = split /TR><TR/ig, $content;
    my @accounts = ();
    my $tfmt = '%Y.%m.%d';
    foreach my $t (@tr) {
        if($t =~ /$re/i) {
            my $obj = {
                radio_value => $1,
                branch => $2,
                type   => $3,
                number => $4,
            };
            my $d = $5;
            my ($start, $end);
            if( $d =~ /(\d{4})\.(\d{2})\.(\d{2})[^\d]+(\d{4})\.(\d{2})\.(\d{2})/ ) {
                $start = sprintf('%04d-%02d-%02d',$1,$2,$3);
                $end = sprintf('%04d-%02d-%02d',$4,$5,$6);
            } elsif( $d =~ /(\d{4})\.(\d{2})\.(\d{2})/ ) {
                $start = sprintf('%04d-%02d-%02d',$1,$2,$3);
            }
            $end ||= $start;
            $obj->{last_downloaded} = {
                start => $start,
                end => $end,
            } if($start && $end);
            push @accounts, $obj;
        }
    }
    $self->{accounts} = [@accounts];
}

sub accounts {
    my $self = shift;
    return $self->{accounts} if $self->{accounts};
    $self->parse_accounts( $self->get_content( $self->list_url ) );
}

sub get_content {
    my ($self,$url) = @_;
    my $res = $self->ua->get($url);
    decode(ENCODING,$res->content);
}

sub logout {
    my $self = shift;
    return unless $self->logged_in;
    my $res = $self->ua->get($self->logout_url);
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
