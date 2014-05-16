#!/usr/bin/env perl

#
# Simple script that can be cron'd to expire moshes that are past
# their sell-by date within SpinalTapCodeMosh
#

use strict;
use DBI;
use DateTime;

my %details = (
    dbtype => 'SQLite',

    # If above dbtype is the default SQLite, use this:
    database => 'dbname=/path/to/stcm/db/mosh.sqlite',

    # For a real DB ie. MySQL, set the dbtype accordingly,
    # comment the above database key, and uncomment these.
#    database => 'spinaltapcodemosh',
#    username => 'myusername',
#    password => 'mypassword',
);

my $dbi_resource = "dbi:$details{dbtype}:$details{database}";
my $dbi = DBI->connect($dbi_resource, $details{username}, $details{password})
    or die("Unable to connect to DB: " . $DBI::errstr);

my %dates = (
    2 => date_previous( months => 1 ),
    3 => date_previous( weeks  => 1 ),
    4 => date_previous( days   => 1 ),
    5 => date_previous( hours  => 1 ),
);

my $sth = $dbi->prepare('DELETE FROM moshes WHERE expiry = ? AND created < ?')
    or die("Unable to prepare statement: " . $dbi->errstr);
while (my ($expiry, $before_date) = each(%dates)) {
    $sth->execute($expiry, $before_date)
        or die("Failed to execute statement: " . $sth->errstr);
}

sub date_previous {
    return sprintf "%s %s",
        DateTime->now( time_zone => 'local' )->subtract(@_)->ymd,
        DateTime->now( time_zone => 'local' )->subtract(@_)->hms;
}


