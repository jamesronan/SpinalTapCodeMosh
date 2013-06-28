package SpinalTapCodeMosh;
use Dancer ':syntax';
use Dancer::Plugin::Database;

use LWP::UserAgent qw();
use Data::UUID;
use HTTP::Status qw(:constants);

our $VERSION = '0.1';

post '/irc' => sub {
    set 'serializer' => 'JSON';
    my %settings  = setting('IRC');
    my $mosh_data = params->{mosh};
    my $server = uri_for('/');

    my $url  = uri_for('/'.$mosh_data->{id});
    my $message = $settings{message};
    $message =~ s/\$url/$url/;
    $message =~ s/\$title/$mosh_data->{subject}/;

    my $ua = LWP::UserAgent->new();
    my $response = $ua->get(
        $settings{url},
        channel => params->{channel},
        message => $message,
    );

    if (!$response->is_success) {
        status 422;
        return halt({ failed => 1 });
    }

    return { ok => 1 };
};

post '/mosh' => sub {
    set 'serializer' => 'JSON';
    my @mosh_fields = qw( data syntax poster subject );
    my %data = map  { $_ => params->{$_} }
               grep { $_ ~~ \@mosh_fields } keys params('body');

    $data{id} = Data::UUID->new->create_str; # We want a unique ID too.
    my $inserted = database->quick_insert('moshes', \%data);

    my $return_data = { created => $inserted };
    if ($inserted) {
        $return_data->{mosh} = \%data;
    } else {
        status HTTP_INTERNAL_SERVER_ERROR;
    }
    return $return_data;
};

get  '/mosh/recent' => sub {
    set 'serializer' => 'JSON';
    my @moshes = database->quick_select(
        'moshes',
        {},
        {
            limit => 20,
            order_by => { desc => 'created' }
        }
    );
    return [ @moshes ];
};

get  '/mosh/:id'    => sub {
    set 'serializer' => 'JSON';
    my $mosh = database->quick_select(
        'moshes',
        {
            id => params->{id}
        }
    );

    if (!$mosh) {
        status HTTP_NOT_FOUND;
        return {};
    }

    return $mosh;
};

any qr{.*} => sub {
    template 'mosh.tt';
};

1;
