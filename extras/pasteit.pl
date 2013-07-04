#!/usr/bin/env perl

=head1 NAME

pasteit.pl - Perl command line utility for posting new moshes

=head1 DESCRIPTION

Allows a developer to directly post a new mosh using the contents of a file, or
from STDIN on the command line. Prints the URL of the newly created mosh upon
completion.

This can also be used for pasting directly from Vim (having symlinked this
script to somewhere in your path):

:'<,'>w !pasteit [options]

Ie. Select a block in Visual mode, and hit colon, and add the w !<linkname>

(or just colon, w ,,, to paste the whole file!)

Default parameters are contained within a config file that will be created upon
first use. The values within this config file should be changed before using
this utility.

Please note: This utility will hang waiting for STDIN to close if you don't
supply a filename when not redirecting something to it's STDIN.

=head1 SYNOPSIS

    % cat /etc/groups | pasteit
    http://spinal-tap-code-mosh/3c9ac412f2

    % pasteit /etc/groups
    http://spinal-tap-code-mosh/3c9ac412f2


    # Ovverride defaults
    % cat /etc/groups | pasteit --title "Everyone knows what it is"
    http://spinal-tap-code-mosh/3c9ac412f2

    % cat /etc/groups | pasteit --name nobody
    http://spinal-tap-code-mosh/3c9ac412f2

    % cat script.pl | pasteit --syntax perl --name Bert
    http://spinal-tap-code-mosh/3c9ac412f2


    # Announce via IRC
    % cat /etc/groups | pasteit --irc channelname
    http://spinal-tap-code-mosh/3c9ac412f2

=head1 CONFIG

This utility reads it's configuration parameters from the ~/.pasteitrc config
file.

A config file will be created if one isn't found in this location and no further
action will be taken, allowing you to edit the config file to your desired
defaults.

The default config file is YAML formatted, however as this util uses Perl's
Config::Any, the syntax type can be any supported by Config::Any.
L<https://metacpan.org/module/Config::Any>

=head DEPENDENCIES

This utilty requires the following Perl modules to be installed:

=over

=item Config::Any - L<https://metacpan.org/module/Config::Any>

=item FileHandle - L<https://metacpan.org/module/FileHandle>

=item Getopt::Long - L<https://metacpan.org/module/Getopt::Long>

=item JSON - L<https://metacpan.org/module/JSON>

=item LWP::UserAgent - L<https://metacpan.org/module/LWP::UserAgent>

=back

=head1 OPTIONS

The available options are as follows:

=over

=item subject - [ subject | sub | title | t ]

Override the subject line of the new mosh. Takes the default from the config
file.

=item poster - [ poster | p | name | n ]

Override the name of the poster of the new mosh. Takes the default from the
config file.

=item syntax - [ syntax | syn | s ]

Override or set the syntax highlighting for the new mosh. Takes the default from
the config file.

=item url - [ url | u ]

Override the URL that the new mosh will be posted to. This shouldn't be required
as it takes the URL from the config file, but supplied to facilitate easy
posting to another STCM instance.

=item irc - [ irc | i ]

If supplied, the new mosh will be announced in the specified IRC channel. This
will work if the STCM instance has IRC configured and the channel supplied is
one that STCM can announce to.

=back

=cut

use strict;
use Config::Any;
use FileHandle;
use Getopt::Long;
use JSON;
use LWP::UserAgent qw();

my $config_file = "$ENV{HOME}/.pasteitrc";
write_default_config_and_bail() if !-e $config_file;

my $config = Config::Any->load_files({
    files   => [ $config_file ],
    use_ext => 0,
    flatten_to_hash => 1,
});
my %options;
Getopt::Long::GetOptions(
    \%options,
    'poster|p|name|n=s',
    'syntax|syn|s=s',
    'subject|sub|title|t=s',
    'url|u=s',
    'irc|i=s',
    'help|h',
);

# If help was requested...
print_help_and_bail() if $options{help};

# Set up the post params, using the defaults, so we only post allowed params.
# Use the supplied option, or fallback to the default.
my %defaults = %{ $config->{$config_file} };
my %post_data = ();
for my $param (keys %defaults) {
    $post_data{$param} = $options{$param} //= $defaults{$param};
}

# Get the data from the specified filename, or STDIN
my $in_filename = $ARGV[0];
my $input_fh = ($in_filename) ? FileHandle->new($in_filename, 'r') : 'STDIN';
$post_data{data} = join '', <$input_fh>;
$input_fh->close;
die <<NODATA if $post_data{data} eq "\n";
I won't create an empty mosh.
Ensure the file or redirected output contains something.

NODATA

my $stcm_url = delete $post_data{url};
$stcm_url =~ s{/$}{}; # Bin the trailing slash if there is one

my $ua       = LWP::UserAgent->new('perl/pasteit-util');
my $response = $ua->post("$stcm_url/mosh", \%post_data);
if (!$response->is_success) {
    print "Failed to create the mosh. Response code: " . $response->code . "\n";
    exit;
}

# If we pasted, return the URL of the paste.
my $data = JSON->new->decode( $response->decoded_content );
print "$stcm_url/$data->{mosh}{id}\n";

# Lastly, If the --irc option was given, post the mosh to the specified channel
# too. We don't care if this works or not... Just send it "It'll Be Fine" :)
if ($options{irc}) {
    $ua->post(
        "$stcm_url/irc",
        {
            channel => $options{irc},
            mosh    => JSON->new->encode({
                id      => $data->{mosh}{id},
                poster  => $post_data{poster},
                subject => $post_data{subject},
            })
        }
    );
}


sub print_help_and_bail {
    die <<HELP;

Usage: pasteit [options] <filename>
Usage: cat /foo/bar/baz | pasteit [options]

Available options:

    help [ --help | -h ]

        Print this help text and exit.

    subject [ --subject | --sub | --title | -t ]

        Override the subject line of the new mosh. Takes the default from the
        config file.

    poster [ --poster | -p | --name | -n ]

        Override the name of the poster of the new mosh. Takes the default from
        the config file.

    syntax [ --syntax | --syn | -s ]

        Override or set the syntax highlighting for the new mosh. Takes the
        default from the config file.

    url [ --url | -u ]

        Override the URL that the new mosh will be posted to. This shouldn't be
        required as it takes the URL from the config file, but supplied to
        facilitate easy posting to another STCM instance.

    irc [ --irc | -i ]

        If supplied, the new mosh will be announced in the specified IRC channel.
        This will work if the STCM instance has IRC configured and the channel
        supplied is one that STCM can announce to.

HELP
}

sub write_default_config_and_bail {
    my $config_fh = FileHandle->new($config_file, 'w');
    print {$config_fh} <DATA>;
    $config_fh->close;

    die <<CONFIGERROR;

Unable to locate config file.

I've created a YAML syntax file @ $config_file. Please customise it and try
again.

Also, please note that this utility will read any config format that Config::Any
can read. So feel free to replace the file's contents with another format if you
so choose.

CONFIGERROR

}

__DATA__
# YAML Formated generated config for SpinalTapCodeMosh's pasteit command line
# utility.

# URL of your STCM instance.
url: 'http://your-stcm-instance-url-here.com'

# Title of your mosh.
subject: 'From the brain of me'

# Highlighting mode to use - Generally the name of the language you're posting,
# or leave it blank for no highlighting.
syntax: ''

# Your name goes here :)
poster: 'Lars'

