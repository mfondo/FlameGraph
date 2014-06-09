#!/usr/bin/perl -w
#
# Converts java jstack output into flamegraph.pl usable data
# jstack creates thread dumps of java processes - http://docs.oracle.com/javase/7/docs/technotes/tools/share/jstack.html
#
# to analyze multiple jstack files, concatenate them into one file: cat *.jstack* >> all.jstack
#
# USAGE: ./stackcollapse-java-jstack.pl jstackfile > outfile
# 
# 09-June-2014	Mike Friesen	Created this.

use strict;

my %collapsed;

sub remember_stack {
	my ($stack, $count) = @_;
	$collapsed{$stack} += $count;
}

#todo use perl regex instead of this method
sub starts_with {
	my ($str, $toMatchStr) = @_;
	my $toMatchStrLength = length($toMatchStr);
	if(substr($str, 0, $toMatchStrLength) eq $toMatchStr) {
		return 1;
	} else {
		return 0;
	}
}

my $collectingStacks = 0;
my @stack;

foreach (<>) {
	chomp;

	my $frame = $_;
        $frame =~ s/^\s*//;
        $frame =~ s/\+[^+]*$//;

	if ($collectingStacks) {
		if($frame =~ /^\s*$/) {
			remember_stack(join(";", @stack), 1);
                	@stack = ();
			$collectingStacks = 0;
		} else {
			if(starts_with($frame, "at ")) {
				$frame = substr($frame, 3, length($frame));
				unshift @stack, $frame;
			}
		}
	} else {
		if(starts_with($frame, "java.lang.Thread.State")) {
			$collectingStacks = 1;
		}
	}
}

foreach my $k (sort { $a cmp $b } keys %collapsed) {
	next if length($k) < 1;
	printf "$k $collapsed{$k}\n";
}
