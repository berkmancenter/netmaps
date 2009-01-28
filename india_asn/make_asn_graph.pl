#!/usr/bin/perl -w

use strict;
use List::MoreUtils qw(uniq);
use Net::Abuse::Utils qw( :all );
use GraphViz;
use Getopt::Long;

sub main
{

    my $graph_viz_output = '';
    my $text_output = '';

    GetOptions ('graph_viz_output' => \$graph_viz_output, 'text_output' => \$text_output) or die"USAGE: make_asn_graph.pl [ --graph_viz_output | --text_output ]\n"  ;

    if ( $graph_viz_output && $text_output) 
    {
        print STDERR "USAGE: make_asn_graph.pl [ --graph_viz_output | --text_output ]\n";
        exit;
    }

    if (! $graph_viz_output && ! $text_output)
    {
        $text_output = 1;
    }

    my $asns = {};

    while (<>)
    {
        if (/^#/)
        {
            next;

            #skip comment lines
        }

        my ( $asn1, $asn2, $relationship ) = split;

        #    print get_asn_country($asn2);

        #    print "\n";

        if ( $relationship == -1 )
        {
            push @{ $asns->{$asn2}->{customers} }, $asn1;
        }
        elsif ( $relationship == 0 )
        {
            push @{ $asns->{$asn2}->{peers} }, $asn1;
        }
        elsif ( $relationship == 1 )
        {
            push @{ $asns->{$asn2}->{providers} }, $asn1;
        }
        elsif ( $relationship == 2 )
        {
            push @{ $asns->{$asn2}->{siblings} }, $asn1;
        }
        else
        {
            die "Invalid relationship value: $relationship";
        }
    }

    #    print_asn_graph($asns);

    if ($text_output) 
    {
        print_connections_per_asn($asns);
    }
    else
    {
        die unless $graph_viz_output;
        print_graphviz($asns);
    }
}

sub total_connections
{
    my ($asn) = @_;

    my $ret = 0;
    foreach my $field (qw (customers peers))
    {
        if ( defined( $asn->{$field} ) )
        {
            $ret += uniq @{ $asn->{$field} };
        }
    }

    return $ret;
}

sub print_connections_per_asn
{
    my ($asns) = @_;

    foreach my $key ( reverse sort { total_connections( $asns->{$a} ) <=> total_connections( $asns->{$b} ) } keys(%$asns) )
    {
        print "\tTotal downstream connections for AS$key: " . total_connections( $asns->{$key} ) . "\n";
        foreach my $field (qw (customers peers providers siblings))
        {
            if ( defined( $asns->{$key}->{$field} ) )
            {
                print "\t\t $field: " . ( join ", ", @{ $asns->{$key}->{$field} } ) . "\n";
            }
        }
    }
}

sub print_asn_graph
{
    my ($asns) = @_;

    foreach my $key ( keys(%$asns) )
    {
        print "AS$key: \n";
        foreach my $field (qw (customers peers providers siblings))
        {
            if ( defined( $asns->{$key}->{$field} ) )
            {
                print "\t\t $field: " . ( join ", ", @{ $asns->{$key}->{$field} } ) . "\n";
            }
        }
    }
}

sub print_graphviz
{
    my $g = GraphViz->new( layout => 'twopi' , ratio => 'auto');

    my ($asns) = @_;

    foreach my $key ( keys(%$asns) )
    {
        foreach my $field (qw  (customers peers))
        {

            #            $g->add_node($key, label => $key);
            if ( defined( $asns->{$key}->{$field} ) )
            {
                foreach my $child ( @{ $asns->{$key}->{$field} } )
                {
                    $g->add_edge( $key => $child );

                    #                print "\t\t $field: " . (join ", " , @{$asns->{$key}->{$field}}) . "\n";
                }
            }
        }
    }

    print $g->as_canon;
}
main();
