#!/usr/bin/perl -w

use strict;
use Getopt::Long;
use AsnGraph;

my $get_relationship_name = {
    -1 => 'customer',
    0  => 'peer',
    1  => 'provider',
    2  => 'sibling',
};

sub main
{

    my $graph_viz_output = '';
    my $text_output      = '';

    GetOptions( 'graph_viz_output' => \$graph_viz_output, 'text_output' => \$text_output )
      or die "USAGE: make_asn_graph.pl [ --graph_viz_output | --text_output ]\n";

    if ( $graph_viz_output && $text_output )
    {
        print STDERR "USAGE: make_asn_graph.pl [ --graph_viz_output | --text_output ]\n";
        exit;
    }

    if ( !$graph_viz_output && !$text_output )
    {
        $text_output = 1;
    }

    my $asn_graph = AsnGraph->new;

    my $asns = {};

    while (<>)
    {
        if (/^#/)
        {
            next;

            #skip comment lines
        }

        my ( $asn1, $asn2, $relationship ) = split;

        my $as1 = $asn_graph->get_as_node($asn1);
        my $as2 = $asn_graph->get_as_node($asn2);
        $as2->add_relationship( $as1, $get_relationship_name->{$relationship} );
    }

    $asn_graph = $asn_graph->get_country_specific_sub_graph("IN");

    #    print_asn_graph($asns);

    if ($text_output)
    {
        $asn_graph->print_connections_per_asn($asns);
    }
    else
    {
        die unless $graph_viz_output;
        $asn_graph->print_graphviz();    #$asns);
    }
}

main();
