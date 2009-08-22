use strict;
use warnings;

use Fcntl qw/SEEK_SET/;
use Getopt::Long;

use Data::Dumper;


=head1 load_config

load config from file / defaults
TODO getopts to force options

=cut
sub load_config() {
	my %return = ();
	
	my $config_file =  "~/.mdbackuprc";

	# setup conf using command line arguments
	GetOptions(\%return, qw/
		config=s
		rsync-options=s@   backup-to=s
		include-paths=s@   exclude-paths=s@
		include-query=s    exclude-query=s	
	/);
	
	# lazy split using comma for rsync options
	foreach (("rsync-options")) {
		next unless ref $return{$_};
		$return{$_} = [ split /,/, $return{$_}->[0] ];
	}
	
	# was config given as part of the command line ?
	$return{config} ||= $config_file;
	$config_file = glob(delete $return{config});
	
	my $strconf = undef;
	
	# Try to read config file, otherwise revert to internal defaults
	if ( -f $config_file && -r _ ) {
		open CONF, $config_file;
		$strconf = join "", <CONF>;
		close CONF;
	} else {
		# print STDERR "Can't open config file $config_file, revert to defaults\n";
		# Rewind data handle after reading, in case we'll need to read it again
		my $origin = tell(DATA);
		$strconf = join "", <DATA>;
		seek(DATA, $origin, SEEK_SET);
	}
	
	# Remove inline comments
	$strconf =~ s/(?<!\\)\s+#.*//gm;

	# and unescape the non-comments #
	$strconf =~ s/\\#/#/gm;

	# Simple scalars, allow empty values with "varname = "
	while ( $strconf =~ /^[\040\t]*([^#\@\s]+?)[\040\t]*=[\040\t]*(.*?)[\040\t]*$/gm  ) {
		next if defined($return{$1});
		
		$return{$1} = $2;
	}

	# Arrays
	while ( $strconf =~ /\@(\S+?)\s*=\s*\((.*?)(?<!\\)\)/gs ) {
		next if defined($return{$1});
		
	    my @values =
	    # 3. then unescape spaces and parenthesis
	    map { s/\\([ )])/$1/g; $_ }
	    # 2. remove empty matches
	    grep { length }
	    # 1. split using non-escaped whitespaces
	    split /(?<!\\)\s+/s, $2;

	    $return{$1} = \@values
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