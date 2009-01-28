#!/usr/bin/perl -w

use strict;
use List::MoreUtils qw(uniq);

my $trace_route_list;

my $tr_list = [];
my @tr_lists;

my $prev_line = "";
my $prev_dest = "";

while (<>)
{
    if (/^traceroute/)
    {
        $tr_list = [];
        /to.(([\d\.])+)/ || die $_;
        $prev_dest = $1;

        #      push @{$tr_list}, $1;
        push @tr_lists, $tr_list;

        if ( $prev_line =~ /(\[AS\d+?\])/ )
        {
            print "$prev_dest: $prev_line";
        }

        # parse traceroute header
    }
    elsif (/^\s*\d+/)
    {

        # parse hope string
        if (/(\[AS\d+?\])/)
        {
            push @{$tr_list}, $1;
        }
    }
    elsif (/^connect: Invalid argument/)
    {

    }
    else
    {
        die "Invalid string: $_";
    }
    $prev_line = $_;
}

#exit;

my $total_trs = 0;

my %as_numbers;

foreach my $list (@tr_lists)
{
    if ( @{$list} >= 5 )
    {
        $total_trs++;
        $as_numbers{ $list->[-1] }++;

        #    foreach my $as_number (uniq (@{$list})) {
        #      $as_numbers{$as_number}++;
        #    }

    }
}

foreach my $key ( reverse sort { $as_numbers{$a} <=> $as_numbers{$b} } keys %as_numbers )
{
    print "$key:\t$as_numbers{$key} (" . $as_numbers{$key} / $total_trs * 100.0 . "%)\n";
}
