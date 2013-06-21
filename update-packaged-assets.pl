#!/usr/bin/env perl

# Minifies all the JS and CSS and packages them up in inidividual files to
# prevent AllTheRequests.

use strict;
use v5.10.1;
use CSS::Minifier;
use JavaScript::Minifier;
use FileHandle;
use String::Random;

my %assets = (
    js  => {
        file     => 'views/js.tt',
        attr     => 'src',
        template => '<script type="text/javascript" src="%s"></script>',
        template_file => 'views/minified-js.tt',
    },
    css => {
        file     => 'views/css.tt',
        attr     => 'href',
        template => '<link rel="stylesheet" type="text/css" href="%s">',
        template_file => 'views/minified-css.tt',
    },
);

# Bin the contents of the public assets dir first.
unlink glob 'public/assets/*';

# For both the CSS and the JS...
for my $asset_type (keys %assets) {
    my $asset_data = $assets{$asset_type};

    my $suffix = String::Random->new->randregex('\w{8}');
    my $minified_asset_filename = "/assets/all-$suffix.$asset_type";
    my $minified_asset_fh = FileHandle->new("public$minified_asset_filename", 'w');

    # Get the list o'files from the template include and minify them into
    # one file.
    my $template_fh = FileHandle->new($asset_data->{file}, 'r');
    line:
    while (my $line = $template_fh->getline) {
        my ($asset_file) = $line =~ /$asset_data->{attr}="(.+?)"/;
        next line if !$asset_file;
        my $asset_fh = FileHandle->new("assets$asset_file", 'r');
        print {$minified_asset_fh} minify_asset($asset_type, $asset_fh);
        $asset_fh->close;
    }
    $minified_asset_fh->close;
    $template_fh->close;

    # Write the tag to the miniifed asset template file.
    my $minified_template_fh
        = FileHandle->new($asset_data->{template_file}, 'w');
    printf {$minified_template_fh}
        $asset_data->{template}, $minified_asset_filename;
    $minified_template_fh->close;
}

sub minify_asset {
    my ($asset_type, $asset_fh) = @_;
    my $minified_asset;

    given ($asset_type) {
        when (/js/) {
            $minified_asset = JavaScript::Minifier::minify(input => $asset_fh);
        }
        when (/css/) {
            $minified_asset = CSS::Minifier::minify(input => $asset_fh);
        }
    };
    return $minified_asset;
}
