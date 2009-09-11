#!/usr/bin/env perl
# vim: et ts=4 sw=4

use strict;
use warnings;
use Data::Dumper;
use File::Temp;
use Fcntl qw/SEEK_SET/;
use Getopt::Long;

use constant CONFPATH => "~/.mdbackuprc";

sub strdata() {
	# Rewind data handle after reading, in case we'll need to read it again
	my $origin = tell(DATA);
	my $strconf = join "", <DATA>;
	seek(DATA, $origin, SEEK_SET);
	
	return $strconf;
}

# START CONFIG ------------------------------------------------------
=head1 get_config

load configuration from
 - command line arguments
 - config file if present / specified

Use the default configuration file if no config file was found

Dies if configuration file was set on command line but does not exists

=cut
sub get_config() {
	my %return = ();
	
	my $config_file =  CONFPATH;

	# setup conf using command line arguments
	GetOptions(\%return, qw/
		config=s
		rsync-options=s@         backup-to=s
		additional-includes=s@   additional-excludes=s@
		include-query=s          exclude-query=s	
	/);
	
	# lazy split using comma for rsync options
	foreach (("rsync-options",)) {
		next unless ref $return{$_};
		$return{$_} = [ split /,/, $return{$_}->[0] ];
	}
	
	# was config given as part of the command line ?
	my $die_on_404 = 0;
	if ( exists $return{config} ) {
		$config_file = delete $return{config};
		$die_on_404 = 1;
	}
	$config_file = glob($config_file);
	
	my $strconf = undef;
	
	# Try to read config file, otherwise revert to internal defaults
	if ( -f $config_file && -r _ ) {
		open CONF, $config_file;
		$strconf = join "", <CONF>;
		close CONF;
	} else {
		die "Can't open configuration file \"$config_file\"" if $die_on_404;
		
		$strconf = strdata();
		
		$return{'-defaults'} = 1;
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

my $config = get_config();

# Backup using Spotlight/Finder comments
my $backup_query = $config->{'include-query'};
my $exclude_query = $config->{'exclude-query'};

# More paths
my @additional_backups = @{ $config->{'additional-includes'} };
my @additional_excludes = @{ $config->{'additional-excludes'} };

#  Remember to backquote spaces ...
my $destination = $config->{'backup-to'};

my @rsyncopts = @{ $config->{'rsync-options'} };

if ( ! $destination && $config->{'-defaults'} && -t ) {
	print
		"No default configuration was found and no destination set.\n",
		"Do your want to copy the default configuration to ",
		CONFPATH, " now? [Y/n] ";
	
	if ( <> =~ /^y/i ) {
		my $data = strdata();
		
		open WRITECONF, ">" . glob(CONFPATH);
		print WRITECONF strdata();
		close WRITECONF;
		
		print "Done, pleaseset up the backup destination in ",
			CONFPATH, " and restart me afterwards\n";
		exit 1;
	}
}

if ( ! $destination ) {
	print STDERR "No backup destination set, I won't start rsync\n";
	exit 1;
}

# END of basic config -----------------------------------------------

# XXX remove / document somewhere else
# You can backup using Finder labels (disabled)
if ( 0 ) {
    # Those are the default values.
    # Didn't find where the actual labels are stored
    my %finder_labels = (
        None => 0,
        Gray => 1,
        Green => 2,
        Purple => 3,
        Blue => 4,
        Yellow => 5,
        Red => 6,
        Orange => 7,
    );
    $backup_query = "(kMDItemFSLabel = '$finder_labels{Green}')";
    $exclude_query = "(kMDItemFSLabel = '$finder_labels{Gray}')";
}


my $rsynccmd = "rsync";

# Very basic sanity checks -- or not
#$backup_query =~ s/$_/\\$_/ foreach (qw/" ` $/);

my @to_backup;
my @to_exclude;

open(FD, "mdfind \"$backup_query\"|");
push @to_backup, <FD>;
close(FD);

open(FD, "mdfind \"$exclude_query\"|");
push @to_exclude, <FD>;
close(FD);

# Remove trailling \n if needed
chop(@to_backup);
chop(@to_exclude);

push @to_backup, @additional_backups;
push @to_exclude, @additional_excludes;

print "Will backup to: $destination\n";
print "Will backup:\n", join( "\n", @to_backup);
print "\n\nWill exclude:\n", join( "\n", @to_exclude);
print "\n\n";

# Terminal, ask for confirmation
if ( -t ) {
    local $| = 1;
    print "Continue? [Y/n] ";    
    exit unless <> =~ /^y/i;
}

my $tmp_include = File::Temp->new(
    TEMPLATE => "rsync-include-XXXX",
    SUFFIX => ".txt",
    TMPDIR => 1
);

my $tmp_exclude = File::Temp->new(
    TEMPLATE => "rsync-exclude-XXXX",
    SUFFIX => ".txt",
    TMPDIR => 1
);

print $tmp_include join( "\n", @to_backup), "\n";
$tmp_include->flush();

print $tmp_exclude join( "\n", @to_exclude), "\n";
$tmp_exclude->flush();

my @rsyncargs = map { "--$_" } @rsyncopts;

push @rsyncargs, '--files-from=' . $tmp_include->filename;
push @rsyncargs, '--exclude-from=' . $tmp_exclude->filename;
push @rsyncargs, "/"; # source
push @rsyncargs, $destination;

print "$rsynccmd ", join( " ", @rsyncargs), "\n";

system($rsynccmd, @rsyncargs);

# Below is the default configuration file
__DATA__
# mdfind queries
# Where does backups go ?
backup-to = 

# mdfind include and exclude queries
include-query = kMDItemFinderComment = 'backup'w    
exclude-query = kMDItemFinderComment = 'nobckup'w

# Paths to include that aren't found by mdfind
@additional-includes = ()

# Paths to exclude that aren't found by mdfind
@additional-excludes = (
	/Users/*/Library/Caches

    # Spaces in lists must be escaped, see below
    # /Library/Application\ Support
)

# Currently only long options
@rsync-options = (
	delete progress compress archive recursive
)

