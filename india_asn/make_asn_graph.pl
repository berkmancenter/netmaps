#!/usr/bin/perl -w

use strict;
use Getopt::Long;
use AsnGraph;
use List::Util qw(max min);
use Locale::Country qw(code2country);
use Readonly;
use Image::LibRSVG;

my $get_relationship_name = {
    -1 => 'customer',
    0  => 'peer',
    1  => 'provider',
    2  => 'sibling',
};

my $_xml_output_file = 'results.xml';

my $_output_dir      = 'results';

sub main
{

    my $graph_viz_output = '';
    my $text_output      = '';
    my $xml_output       =  0;

    GetOptions( 'graph_viz_output' => \$graph_viz_output, 'text_output' => \$text_output )
      or die "USAGE: make_asn_graph.pl [ --graph_viz_output | --text_output ]\n";

    if ( $graph_viz_output && $text_output )
    {
        print STDERR "USAGE: make_asn_graph.pl [ --graph_viz_output | --text_output ]\n";
        exit;
    }

    if ( !$graph_viz_output && !$text_output )
    {
        $xml_output = 1;
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

    @country_codes = grep {defined($_) && ($_ ne '') } @country_codes;

    @country_codes = grep { $_ ne 'US' } @country_codes;
    #@country_codes = grep { $_ eq 'EU' } @country_codes;

    #@country_codes = @country_codes[0..10];

    my $doc  = XML::LibXML::Document->new();
    my $root = $doc->createElement('asn_results');

    $doc->setDocumentElement($root);
    
    my $loop_iteration = 0;
    for my $country_code (@country_codes)
    {
        $loop_iteration++;

        my $country_code_is_region = 0;

        my $country_name = code2country($country_code);

        #next unless defined $country_name;

        if (!$country_name or $country_name eq '')
        {
            $country_name ||=  $country_code;
            $country_code_is_region = 1;            
        }

        print "Country: $country_name($country_code)\n";
        my $asn_sub_graph = $asn_graph->get_country_specific_sub_graph($country_code);
        
        if ($xml_output) 
        {
            my $country_element = XML::LibXML::Element->new('country');
            $country_element->setAttribute( 'country_code' , $country_code );
            $country_element->setAttribute( 'country_name' , $country_name);
            $country_element->setAttribute( 'country_code_is_region' , $country_code_is_region);
            $country_element->appendChild($asn_sub_graph->xml_summary());
            $root->appendChild($country_element);
            my $g = $asn_sub_graph->print_graphviz();
            #die unless $g->as_svg($svg_output_file);
            my $svg_to_scale = $g->as_svg;
            die unless $svg_to_scale;
            $svg_to_scale =~ s/<svg width=".*" height=".*"/<svg width="100%" height="100%"/;
            $svg_to_scale =~ s/stroke:black;"/stroke:black;stroke-width:20"/g;

            my $output_file_base = "$_output_dir/graphs/asn-$country_name";
            my $svg_output_file = "$output_file_base.svg";
            open(SVGOUTPUTFILE, ">$svg_output_file") || die "Could not create file:$svg_output_file ";
            print SVGOUTPUTFILE $svg_to_scale;
            close(SVGOUTPUTFILE);

            my $rsvg = new Image::LibRSVG();

            $rsvg->convertAtSize($svg_output_file, "$output_file_base.png", 800, 800) || die "Could not convert file to png";

            if (($loop_iteration % 10) == 0)
            {
                print "Dumping current results\n";
                print $doc->toFile( "$_output_dir/$_xml_output_file", 1 );
            }

            #if ($loop_iteration == 11) { exit; }
            
        }
        elsif ($text_output)
        {
            $asn_sub_graph->print_connections_per_asn($asns);
        }
        elsif ($graph_viz_output)
        {
            my $graph_size =  $asn_sub_graph->get_as_nodes_count;
            my $g = $asn_sub_graph->print_graphviz();

            die unless $g->as_svg("graphs/asn-$country_name-$country_code.svg");
            die unless $g->as_text("graphs/asn-$country_name-$country_code.dot");
            print "finished country: '$country_name - $country_code'\n";
        }
        else
        {
            die "SHOULD NOT BE REACHED";
        }
    }
 
    if ($xml_output) 
    {
        print $doc->toFile( "$_output_dir/$_xml_output_file", 1 );
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
