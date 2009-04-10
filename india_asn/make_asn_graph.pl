#!/usr/bin/perl -w

use strict;
use Getopt::Long;
use AsnGraph;
use List::Util qw(max min);
use Locale::Country qw(code2country);

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

    #$asn_graph->print_connections_per_asn($asns);

    #exit;

    my @country_codes = @{$asn_graph->get_country_codes()};

    @country_codes = grep {$_ eq 'IN' } @country_codes;


    for my $country_code (@country_codes)
    {
        my $asn_sub_graph = $asn_graph->get_country_specific_sub_graph($country_code);
        
        #    print_asn_graph($asns);
        print "Country: $country_code\n";
        if ($text_output)
        {
            $asn_sub_graph->print_connections_per_asn($asns);
        }
        else
        {
            my $graph_size =  $asn_sub_graph->get_as_nodes_count;
            die unless $graph_viz_output;
            my $g = $asn_sub_graph->print_graphviz();

            my $country_name = code2country($country_code);
            die unless $g->as_svg("graphs/asn-$country_name-$country_code.svg");
            die unless $g->as_text("graphs/asn-$country_name-$country_code.dot");
            print "finished country: '$country_name - $country_code'\n";
        }
    }
}

sub find_max_printable_graph_size
{
    my ($asn_sub_graph, $country_code ) = @_;
    my $graph_size =  $asn_sub_graph->get_as_nodes_count;
    while ($graph_size <= $asn_sub_graph->get_as_nodes_count)
    {
        my $g = $asn_sub_graph->print_graphviz($graph_size);
        die unless $g->as_png("graphs/asn-". code2country($country_code). "-$country_code-$graph_size-nodes.png");
        print "finished country: ".code2country($country_code) ."-'$country_code' graph_size: $graph_size \n";
        last if ($graph_size == $asn_sub_graph->get_as_nodes_count);
        
        $graph_size *= 2;
        $graph_size  = min($graph_size, $asn_sub_graph->get_as_nodes_count);
    }
    
}

main();
