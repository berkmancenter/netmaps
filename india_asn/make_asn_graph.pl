#!/usr/bin/perl -w

use strict;
use Getopt::Long;
use AsnGraph;

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

        $asn_graph->add_relationship( $asn1, $asn2, $relationship );
    }

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
