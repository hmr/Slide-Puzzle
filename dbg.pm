#!/usr/bin/perl

package dbg;

sub dprint($)
{
	my $msg = shift;
	if($DBG == 1)
	{
		print STDERR $msg,"\n";
	}
}

1;
