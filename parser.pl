use strict;
use warnings;

use Data::Dumper;

my $string = q|# mdfind queries
include-query = kMDItemFinderComment = 'backup'w    
exclude-query = kMDItemFinderComment = 'nobckup'w

dummy = dumb # This is an inline comment, must be preceded by a space 

# Where am I?
backup-to = /Volumes/Backup\ HD/XXXXXX-CHANGEME

# Paths to include that aren't found by mdfind
@include-paths = ()

# Paths to exclude that aren't found by mdfind
@exclude-paths = (
	/Users/*/Library/Caches

    # Spaces must be escaped too, see below
    # /Library/Application\ Support
)

@rsync-options = (
	delete progress compress archive recursive
)
|;

my %conf = ();

# Remove inline comments
$string =~ s/(?<!\\)\s+#.*//gm;

# and unescape the non-comments
$string =~ s/\\#/#/gm;

while ( $string =~ /^\s*([^#\@\s]+?)\s*=\s*(.*?)\s*$/gm  ) {
	$conf{$1} = $2;
}

while ( $string =~ /\@(\S+?)\s*=\s*\((.*?)(?<!\\)\)/gs ) {
    my @values = map { s/\\([ )])/$1/g; $_ } grep { length } split /(?<!\\)\s+/s, $2;
    $conf{$1} = [ @values ];
}
print Dumper \%conf;
#print $string;
