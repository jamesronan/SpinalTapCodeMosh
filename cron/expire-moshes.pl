#!/bin/env perl

#
# Simple script that can be cron'd to expire moshes that are past
# their sell-by date within SpinalTapCodeMosh
#

use strict;
use DBI;
use DateTime;

my %details = (
    dbtype => 'sqlite',

    # If above dbtype is the default SQLite, use this:
    database => 'dbname=./db/moshes.sqlite',

    # For a real DB ie. MySQL, set the dbtype accordingly,
    # comment the above database key, and uncomment these.
#    database => 'moshes',
#    username => 'myusername',
#    password => 'mypassword',
);

my $dbi_resource = "dbi:$details{dbtype}:$details{database}";
my $dbi = DBI->new($dbi_resource, $details{username}, $details{password});

my $dt_now = DateTime->now();
my %dates = (
    2 => $dt_now->

);

my $sth = $dbi->prepare('DELETE FROM moshes WHERE expiry = ? AND created < ?');
for (my ($expiry, $before_date) = each %dates) {
    $sth->execute($expiry, $before_date);
}




