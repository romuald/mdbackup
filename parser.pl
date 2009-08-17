use strict;
use warnings;

my $string = q|
# mdfind queries
include-query = kMDItemFinderComment = 'backup'w
exclude-query = kMDItemFinderComment = 'nobckup'w

# Where am I?
backup-to = /Volumes/Backup\ HD/XXXXXX-CHANGEME

@include-paths = ()
@exclude-paths = (
	/Users/*/Library/Caches
)

@rsync-options = (
	delete progress compress archive recursive
)
|;

$string =~ s/^\s*[#]+.*//gm;

while ( $string =~ /^(\w+)\s*=\s*/  ) {
	print $1;
}

print $string;