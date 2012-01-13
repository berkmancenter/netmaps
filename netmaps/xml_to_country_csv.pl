#!/usr/bin/perl -w

use strict;
use Getopt::Long;
use AsnGraph;
use AdPlannerCountryReport;
use List::Util qw(max min sum);
use List::MoreUtils qw(after after_incl);
use List::Uniq ':all';
use Locale::Country qw(code2country);
use Readonly;
use Perl6::Say;
use XML::LibXML  1.70;
use Data::Dumper;

 
my $get_relationship_name = {
    -1 => 'customer',
    0  => 'peer',
    1  => 'provider',
    2  => 'sibling',
};

my $_xml_output_file = 'results.xml';

my $_output_dir = 'results';

sub main
{

    my $xml_file = '';
    my $country_code = '';

    GetOptions( 'xml_file=s' => \$xml_file, 'country_code=s' => \$country_code )
      or die "USAGE: make_asn_graph.pl [ --graph_viz_output | --text_output ]\n";

    unless ( $xml_file && $country_code )
    {
        print STDERR "USAGE: xml_to_country_csv --xml_file --country_code\n";
        exit;
    }

    $country_code = uc($country_code);

    my $dom = XML::LibXML->load_xml(
				    location => $xml_file
				   );

    die "Error opening xml file $xml_file:\n $@" unless $dom;

    my $xpath = '/asn_results/country[@country_code=' . "'$country_code']";
    die "country code not found $country_code" unless $dom->exists($xpath);
    $xpath = "$xpath/summary/as";
    die "country has not AS's" unless $dom->exists($xpath);
    my @AS_nodes;
    @AS_nodes = $dom->findnodes($xpath);

    my $node_list = [];
    foreach my $AS_node (@AS_nodes)
    {
        my @AS_attributes = $AS_node->nonBlankChildNodes();
	my $attribute_hash = {};
	foreach my $AS_attribute (@AS_attributes)
	{
	    $attribute_hash->{$AS_attribute->nodeName} = $AS_attribute->textContent;
	}

	push @{$node_list} , $attribute_hash;
    }

    my @node_types  = uniq (grep {defined($_) } (map { $_->{type} } @{$node_list}));

    my $node_type_ip_count = {};
    foreach my $node_type (@node_types)
    {
      my $ip_count = sum (map {$_->{direct_ips} } (grep {$_->{type} eq $node_type } @{$node_list}));
      $node_type_ip_count->{$node_type} = $ip_count;
    }

    foreach my $node (@{$node_list})
    {
        #TODO need better way to avoid div by zero
        eval { 
	  $node->{percent_direct_ips_type} = $node->{direct_ips}/$node_type_ip_count->{$node->{type}}*100.0;
	}
    }

    Readonly my $banded_fields => [ qw (actual_monitorable_ips customers downstream_ips effective_monitorable_ips percent_monitorable total_connections)];

    $node_list = [ sort { ($a->{type} cmp $b->{type}) || ($b->{direct_ips} <=> $a->{direct_ips}) } @{$node_list} ];

    foreach my $node (@{$node_list})
    {
        #say Dumper($node);
        foreach my $banded_field (@{$banded_fields})
	{
	    #say "$banded_field";
	    #say $node->{$banded_field};
	    delete ($node->{$banded_field});
	    #say $node->{$banded_field};
	}
    }

    my @header_fields = (sort @{[uniq ( map { keys %{$_}} @{$node_list} )]});

    my $csv = Class::CSV->new(
    fields         => [@header_fields],
			    );

    foreach my $node (@{$node_list})
    {
       $csv->add_line($node);
    }

    say join ",", @header_fields;
    $csv->print();
}


main();
