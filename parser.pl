use strict;
use warnings;

use Data::Dumper;

=head1 load_config

load config from file / defaults
TODO getopts to force options

=cut
sub load_config() {
	my %return = ();
	
	my $config_file =  glob("~/.mdbackuprc");
	
	# TODO be able to use a different location using command line
	if ( -f $config_file && -r _ ) {
		open(CONF, $config_file);
	} else {
		*CONF = \*DATA;
	}
	
	my $strconf = join "", <CONF>;
	close(CONF);
		
	# Remove inline comments
	$strconf =~ s/(?<!\\)\s+#.*//gm;

	# and unescape the non-comments #
	$strconf =~ s/\\#/#/gm;

	# Simple scalars, allow empty values with "varname = "
	while ( $strconf =~ /^[\040\t]*([^#\@\s]+?)[\040\t]*=[\040\t]*(.*?)[\040\t]*$/gm  ) {
		$return{$1} = $2;
	}

	# Arrays
	while ( $strconf =~ /\@(\S+?)\s*=\s*\((.*?)(?<!\\)\)/gs ) {
	    my @values =
	    # 3. then unescape spaces and parenthesis
	    map { s/\\([ )])/$1/g; $_ }
	    # 2. remove empty matches
	    grep { length }
	    # 1. split using non-escaped whitespaces
	    split /(?<!\\)\s+/s, $2;

	    $return{$1} = \@values;
	}
	# and no dict yet
	
	return \%return;
}

print Dumper load_config();

__DATA__
# mdfind queries
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