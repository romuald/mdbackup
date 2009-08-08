#!/usr/bin/env perl
use strict;
use warnings;
use Data::Dumper;
use File::Temp;


# BASIC CONFIG ------------------------------------------------------
# Backup using Spotlight/Finder comments
my $backup_query = "(kMDItemFinderComment = 'backup'w)";
my $exclude_query = "(kMDItemFinderComment = 'nobckup'w)";

# More paths
my @additional_backups = qw{};
my @additional_excludes = qw{
    /Users/*/Library/Caches
};

#  Remember to backquote spaces ...
my $destination = "/Volumes/Backup\ HD/XXXXXX-CHANGEME";

# END of basic config -----------------------------------------------

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
my @rsyncopts = qw/delete progress compress archive recursive/;

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