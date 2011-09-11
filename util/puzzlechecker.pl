#!/usr/bin/perl

use ClosedTree;

my $in;
my $fh;

open($fh, "<../resources/input.txt") || die;

$in = <$fh>;
$in = <$fh>;

while(<$fh>)
{
	chomp();
	my $ct = new ClosedTree($_);
	my $error = 0;
	
	my $lines;
	
	print "$ct->{X} / $ct->{Y}\n";
	
	for(my $c = 0; $c < $ct->{Length}; $c++)
	{
		my $val_str = $ct->{Tree}->{$c}->{val_str};
		$lines .= "[$val_str]";
		$lines .= "\n" if($c % $ct->{X} == $ct->{X} - 1);
	}
	
	print "$lines\n\n";
	
}
