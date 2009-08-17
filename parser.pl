use strict;
use warnings;

use Data::Dumper;

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

my %conf = ();

$string =~ s/^\s*[#]+.*//gm;

while ( $string =~ /^([^\@\s]+?)\s*=\s*(.*)/gm  ) {
	$conf{$1} = $2;
}

while ( $string =~ /\@(\S+?)\s*=\s*\((.*?)\)/gs ) {
    my @values = grep { length } split /\s+/s, $2;

    $conf{$1} = [ @values ];
}
print Dumper \%conf;
#print $string;
