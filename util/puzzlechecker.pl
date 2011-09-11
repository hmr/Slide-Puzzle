#!/usr/bin/perl

use ClosedTree;

my $in;
my $fh;

open($fh, "<../resources.input.txt") || die;

$in = <$fh>;
$in = <$fh>;

while(<$fh>)
{
	chomp();
	my $ct = new ClosedTree($_);
	my $error = 0;
	
	for(my $c = 0; $c < $ct-{Length}; $c++)
	{
		my $val_str = $ct->{$c}->{val_str};
	}
	
}
