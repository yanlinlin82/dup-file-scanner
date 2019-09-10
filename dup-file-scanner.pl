#!/usr/bin/perl
use strict;
use warnings;

die "Usage: $0 <dir>...\n" unless @ARGV;

sub scan_dir
{
	my ($dir, $hash) = @_;
	opendir my $dh, $dir or die "Cannot open directory '$dir'!\n";
	my @files = grep { $_ ne '.' and $_ ne '..' } readdir($dh);
	close $dh;
	for my $filename (map { $dir . "/" . $_ } @files) {
		if (-d $filename) {
			scan_dir($filename, $hash);
		} else {
			my $file_size = (stat($filename))[7];
			if ($file_size > 1e6) { # process only file size > 10MB
				chomp(my $md5 = `md5sum "$filename" | cut -c1-32`);
				push @{$hash->{$md5}}, $filename;
			}
		}
	}
}

my %hash = ();
for my $dir (@ARGV) {
	die "'$dir' is not a directory!\n" unless -d $dir;
	print STDERR "Scanning '$dir' ...\n";
	scan_dir($dir, \%hash);
}

print "# Duplicated files:\n";
for my $key (keys %hash) {
	if (scalar(@{$hash{$key}}) > 1) {
		print "# ===================\n";
		print "# md5sum: $key\n";
		print "# file count: " . scalar(@{$hash{$key}}) . "\n";
		my $counter = 0;
		print join("\n", map { ++$counter; "# ($counter) $_" } @{$hash{$key}}), "\n";
		for (my $i = 1; $i < scalar(@{$hash{$key}}); ++$i) {
			print "rm -fv \"$hash{$key}->[$i]\"\n";
			print "ln -v \"$hash{$key}->[0]\" \"$hash{$key}->[$i]\"\n";
		}
	}
}
