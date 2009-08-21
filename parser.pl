use strict;
use warnings;

use Data::Dumper;

my $string = q|# mdfind queries
# Where does backups go ?
backup-to = 

# mdfind include and exclude queries
include-query = kMDItemFinderComment = 'backup'w    
exclude-query = kMDItemFinderComment = 'nobckup'w

# Paths to include that aren't found by mdfind
@include-paths = ()

# Paths to exclude that aren't found by mdfind
@exclude-paths = (
	/Users/*/Library/Caches

    # Spaces in lists must be escaped, see below
    # /Library/Application\ Support
)

# Currently only long options
@rsync-options = (
	delete progress compress archive recursive
)
|;

my %conf = ();

# Remove inline comments
$string =~ s/(?<!\\)\s+#.*//gm;

# and unescape the non-comments #
$string =~ s/\\#/#/gm;

# Simple scalars
while ( $string =~ /^[\040\t]*([^#\@\s]+?)[\040\t]*=[\040\t]*(.*?)[\040\t]*$/gm  ) {
	$conf{$1} = $2;
}

# Arrays
while ( $string =~ /\@(\S+?)\s*=\s*\((.*?)(?<!\\)\)/gs ) {
    my @values =
    # 3. then unescape spaces and parenthesis
    map { s/\\([ )])/$1/g; $_ }
    # 2. remove empty matches
    grep { length }
    # 1. split using non-escaped whitespaces
    split /(?<!\\)\s+/s, $2;

    $conf{$1} = \@values;
}
# and no dict yet

print Dumper \%conf;
#print $string;
