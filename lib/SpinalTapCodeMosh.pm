package SpinalTapCodeMosh;
use Dancer ':syntax';
use Dancer::Plugin::Database;

use Data::UUID;
use HTTP::Status qw(:constants);

our $VERSION = '0.1';

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
