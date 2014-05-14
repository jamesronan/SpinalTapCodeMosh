package SpinalTapCodeMosh;
use Dancer ':syntax';
use Dancer::Plugin::Database;

use LWP::Simple qw();
use Data::UUID;
use HTTP::Status qw(:constants);
use JSON qw();
use Digest::SHA1 qw();
use URI::Escape qw();

our $VERSION = '0.1';

post '/irc' => sub {
    set 'serializer' => 'JSON';
    my %settings  = %{ setting('IRC') };

    # Prevent this being used if it wasn't configured in the app.
    if (   !%settings
        || !defined($settings{webhook})
        || !defined($settings{linkurl})
        || !defined($settings{message})
        || !defined($settings{channels})
        )
    {
        status HTTP_FORBIDDEN;
        return halt({ not_configured => 1 });
    }

    my %mosh_data = %{ JSON->new->decode(params->{mosh}) };

    my $url  = $settings{linkurl} . '/' . $mosh_data{id};
    my $message = $settings{message};
    $message =~ s/\$url/$url/;
    $message =~ s/\$poster/$mosh_data{poster}/;
    $message =~ s/\$title/$mosh_data{subject}/;

    if (!LWP::Simple::get(
            sprintf '%s?channel=%s&message=%s',
                $settings{webhook}, params->{channel}, URI::Escape::uri_escape($message)
        ))
    {
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

    # We want a unique ID, which isn't as long as a Donkey's cock.
    $data{id}
        = substr Digest::SHA1::sha1_hex( Data::UUID->new->create_str ), 0, 10;
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

# Add a route allowing people to see the content of moshes in it's raw form.
get '/mosh/raw/:id' => sub {
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

    # If we have a mosh, we need to set the content type to text/plain, then
    # dump the mosh out.
    header 'content-type' => 'text/plain';
    return $mosh->{data};
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
