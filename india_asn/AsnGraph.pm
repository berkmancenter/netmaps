package AsnGraph;

use strict;
use List::MoreUtils qw(uniq);
use List::Pairwise qw (grepp);
use List::Util qw (sum);
use GraphViz;
use AsnUtils;
use AS;
use Graph;
use Carp;
use AsnTaxonomyClass;
use List::Compare;
use XML::LibXML;
use Data::Dumper;

# MODULES

# CONSTANTS

# max number of pages the handler will download for a single story

# STATICS

my $_as_class_color = {
    abstained => 'grey',
    comp      => 'yellow',
    edu       => 'orange',
    ix        => 'purple',
    nic       => 'green',
    t1        => 'red',
    t2        => 'blue',
};

my $_dont_check_for_cycles = 1;

# METHODS

sub new
{
    my ($class) = @_;

    my $self = {};

    $self->{asn_nodes} = {};
    bless( $self, $class );

    $self->_clear_cached_property_stats();
    return $self;
}

my $_asn_cache = {};

sub _clear_cached_property_stats
{
    my ($self) = @_;
    $self->{_verified_acyclic} = 0;
    undef( $self->{_total_ips} );
    undef( $self->{_country_as_nodes_count} );
}

sub get_as_node
{
    my ( $self, $as_number ) = @_;

    if ( !defined( $self->{asn_nodes}->{$as_number} ) )
    {
        $self->{asn_nodes}->{$as_number} = AS->new($as_number);
        $self->_clear_cached_property_stats;
    }

    return $self->{asn_nodes}->{$as_number};
}

sub get_country_as_nodes_count
{
    my ($self) = @_;
    my $asns = $self->{asn_nodes};
    if ( !defined( $self->{_country_as_nodes_count} ) )
    {
        $self->{_country_as_nodes_count} = scalar( grep { !$_->is_rest_of_world() } values %{$asns} );
    }

    return $self->{_country_as_nodes_count};
}

sub _get_total_ips
{
    my ($self) = @_;
    my $asns = $self->{asn_nodes};

    if ( !defined( $self->{_total_ips} ) )
    {
        $self->{_total_ips} = sum map { $_->get_asn_ip_address_count() } values %{$asns};
    }

    return $self->{_total_ips};
}

sub print_graphviz
{

    my ( $self, $max_parent_nodes ) = @_;

    my $g = GraphViz->new(
        layout  => 'twopi',
        ratio   => 'auto',
        overlap => 'scale'
    );

    my $asns = $self->{asn_nodes};

    my $parent_nodes_processed = 0;

    foreach my $key ( sort keys(%$asns) )
    {
        if ( defined($max_parent_nodes) && ( $parent_nodes_processed > $max_parent_nodes ) )
        {
            return $g;
        }
        foreach my $field (qw  (customer peer))
        {
            foreach my $child ( uniq sort { $a->get_as_number() cmp $b->get_as_number() }
                @{ $asns->{$key}->get_nodes_for_relationship($field) } )
            {
                if ( ( !$child->is_rest_of_world() ) && ( !$child->only_connects_to_rest_of_world() ) )
                {
                    $g->add_edge( $key => $child->get_as_number() );
                }
                else
                {
                    print "Skipping link $key -> " . $child->get_as_number() . "\n";
                }

                #                        print "\t\t $field:$key " . $child->get_as_number(). "\n";
            }
        }

        $parent_nodes_processed++;
    }

    foreach my $asn_key ( @{ $g->{NODELIST} } )
    {

        #print "$asn_key\n";
        #if ( ( $asns->{$asn_key}->total_connections ) > 2 )
        {
            $g->add_node( $asn_key, label => $asns->{$asn_key}->get_graph_label( _get_total_ips() ) );
        }

        my $as_class = AsnTaxonomyClass::get_asn_taxonomy_class($asn_key);

        my $color;

        if ( !defined($as_class) )
        {
            $color = 'white';
        }
        else
        {
            $color = $_as_class_color->{$as_class};
        }

        $g->add_node( $asn_key, fillcolor => $color, style => 'filled' );
    }

    return $g;
}

sub _get_graph_object
{
    my ($self) = @_;

    #print STDERR "Start _get_graph_object\n";

    my $g = Graph->new;

    my $asns = $self->{asn_nodes};

    my $parent_nodes_processed = 0;

    foreach my $key ( sort keys(%$asns) )
    {
        foreach my $field (qw  (customer))
        {
            foreach my $child ( uniq sort { $a->get_as_number() cmp $b->get_as_number() }
                @{ $asns->{$key}->get_nodes_for_relationship($field) } )
            {
                if ( !$asns->{$key}->is_rest_of_world && !$child->is_rest_of_world )
                {
                    $g->add_edge( $key, $child->get_as_number() );
                }
            }
        }

        $parent_nodes_processed++;
    }

    #print STDERR "Finish _get_graph_object\n";

    return $g;
}

sub print_asn_graph
{
    my ($self) = @_;

    my $asns = $self->{asn_nodes};

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

sub get_country_codes
{
    my ($self) = @_;

    my $asns = $self->{asn_nodes};

    my @country_list = uniq grep { defined($_) } map { $_->get_country_code() } values %{$asns};

    @country_list = sort @country_list;

    return \@country_list;
}

sub die_if_cyclic
{
    my ($self) = @_;

    if ($_dont_check_for_cycles)
    {
        return;
    }

    return if ( $self->{_verified_acyclic} );

    print "Checking whether graph is acyclic...\n";
    my $g = $self->_get_graph_object();

    die "Graph is cyclic: " . join( " , ", $g->find_a_cycle() ) if ( $g->has_a_cycle() );

    $self->{_verified_acyclic} = 1;

    #print "Graph is not cyclic\n";

}

sub _sort_by_monitoring
{
    my ( $self, $asn_names ) = @_;
    my $asns = $self->{asn_nodes};

    $self->die_if_cyclic();

    my @ret =
      reverse
      sort { $asns->{$a}->get_effective_monitorable_ip_address_count() <=> $asns->{$b}->get_effective_monitorable_ip_address_count() }
      @{$asn_names};

    return @ret;
}

sub _get_asn_names_sorted_by_monitoring
{
    my ($self) = @_;
    my $asns = $self->{asn_nodes};

    $self->die_if_cyclic();
    my @ret = $self->_sort_by_monitoring( [ keys %{$asns} ] );

    @ret = grep { !$asns->{$_}->is_rest_of_world() } @ret;
    return @ret;
}

sub _get_asns_monitorable_by_list
{
    my ( $self, $asn_list ) = @_;
    my $asns = $self->{asn_nodes};

    $asn_list = [ grep { defined($_) } @{$asn_list} ];

    #     print "_get_asns_monitorable_by_list\n";
    #  print "asn_list $asn_list\n";
    #     print Dumper($asn_list);
    #     print "\n";
    #     print "asn_list: " . (join ", ", @{$asn_list}) . "\n";
    my @monitorable_asn_objects = map { ( @{ $asns->{$_}->get_downstream_asns } ) } @{$asn_list};
    my @monitorable_asns        = map { $_->get_as_number } @monitorable_asn_objects;
    push @monitorable_asns, @{$asn_list};
    @monitorable_asns = uniq grep { defined($_) } @monitorable_asns;
    return \@monitorable_asns;
}

sub get_ips_in_asn_list
{
    my ( $self, $asn_list ) = @_;
    my $asns = $self->{asn_nodes};

    #      print "Self $self\n";
    #      print "asn_list $asn_list\n";
    #      print Dumper($asn_list);
    #      print "asn_list: " . (join ", ", @{$asn_list}) . "\n";
    return sum map { $asns->{$_}->get_asn_ip_address_count() } @{$asn_list};
}

sub get_percent_controlled_by_list
{
    my ( $self, $asn_list ) = @_;
    my $asns = $self->{asn_nodes};

#    my $asn_list_monitorable = $self->_get_asns_monitorable_by_list($asn_list);
#    my $ips_monitorable = $self->get_ips_in_asn_list($asn_list_monitorable);

    my @asn_object_list = map { $asns->{$_} } @{$asn_list}; 
    #make sure we don't double count
    my $ips_monitorable = sum map {$asns->{$_}->get_effective_monitorable_ip_address_count(\@asn_object_list) } @{$asn_list};

    return $ips_monitorable / $self->_get_total_ips * 100;
}

#old code that assumed that an ASN could monitor 100 of it's customers' networks
sub get_asns_controlling_ninty_percent_indirectly
{
    my ($self) = @_;

    my @asns = $self->_get_asn_names_sorted_by_monitoring();

    my $asn                = shift @asns;
    my @ninty_percent_list = ($asn);

    while ( $self->get_percent_controlled_by_list( \@ninty_percent_list ) < 90.0 )
    {

        #Get asns not already monitorable by our list
        my $monitorable_asns = $self->_get_asns_monitorable_by_list( \@ninty_percent_list );
        my $lca = List::Compare->new( '-u', '-a', \@asns, $monitorable_asns );
        @asns = $lca->get_unique;

        @asns = $self->_sort_by_monitoring( \@asns );

        #add the asn that monitors the most ASNs to the list
        die if ( scalar(@asns) == 0 );
        $asn = shift @asns;
        push @ninty_percent_list, $asn;

        #print " while (\n";
    }

    return \@ninty_percent_list;
}

sub get_asns_controlling_ninty_percent
{
    my ($self) = @_;

    my @asns = $self->_get_asn_names_sorted_by_monitoring();

    my $asn                = shift @asns;
    my @ninty_percent_list = ($asn);

    while ( $self->get_percent_controlled_by_list( \@ninty_percent_list ) < 90.0 )
    {
#         #Get asns not already monitorable by our list
#         my $monitorable_asns = $self->_get_asns_monitorable_by_list( \@ninty_percent_list );
#         my $lca = List::Compare->new( '-u', '-a', \@asns, $monitorable_asns );
#         @asns = $lca->get_unique;

#         @asns = $self->_sort_by_monitoring( \@asns )
#            ;

        #add the asn that monitors the most ASNs to the list
        die if ( scalar(@asns) == 0 );
        $asn = shift @asns;
        push @ninty_percent_list, $asn;

        #print " while (\n";
    }

    return \@ninty_percent_list;
}

#Return the top 10 Asns plus any ASNs that can monitor 90% of the countries IPs
sub _get_top_country_asns
{
    my ($self) = @_;
    my $asns = $self->{asn_nodes};

    $self->die_if_cyclic();

    my @asn_keys = $self->_get_asn_names_sorted_by_monitoring;

    keys(%$asns);
    if ( scalar(@asn_keys) > 9 )
    {
        @asn_keys = @asn_keys[ 0 .. 9 ];
    }

    my $total_ips = $self->_get_total_ips();

    my @ninety_percent_monitoring_asns =
      grep { ( $asns->{$_}->get_effective_monitorable_ip_address_count() / $total_ips ) >= 0.9 } keys(%$asns);

    my $lca = List::Compare->new( '-u', '-a', \@asn_keys, \@ninety_percent_monitoring_asns );

    my @top_asn_keys = $lca->get_union();

    @top_asn_keys = grep { !$asns->{$_}->is_rest_of_world() } @top_asn_keys;

    @top_asn_keys =
      reverse
      sort { $asns->{$a}->get_effective_monitorable_ip_address_count() <=> $asns->{$b}->get_effective_monitorable_ip_address_count() }
      @top_asn_keys;

    return \@top_asn_keys;
}

sub print_connections_per_asn
{
    my ($self) = @_;

    my $asns = $self->{asn_nodes};

    my $total_ips = $self->_get_total_ips();

    die "Could unget total ips" unless defined($total_ips);
    print "ASN graph has $total_ips total ips\n";

    $self->die_if_cyclic();

    my @asn_keys = @{ $self->_get_top_country_asns };

    foreach my $key (@asn_keys)
    {
        my $asn_info = $asns->{$key}->get_statistics();

        #my $asn_name = (AsnUtils::get_asn_whois_info($key))->{name};
        #my $asn_name = ( AsnTaxonomyClass::get_asn_organization_description($key) );
        print
"Total downstream connections for AS$asn_info->{asn} ($asn_info->{organization_name}): $asn_info->{total_connections}\n";
        if ( $key ne 'REST_OF_WORLD' )
        {

            print "\tDirect IPs for AS$key: " . $asn_info->{direct_ips} . "\n";
            print "\tDownstream IPs for AS$key: " . $asn_info->{downstream_ips} . "\n";
            print "\tMonitorable IPs for AS$key: " . $asn_info->{monitorable_ips} . "\n";
            print "\tPercent of all total IPs monitorable: " . $asn_info->{monitorable_ips} / $total_ips * 100.0 . "\n";
            print "\n";
        }

        foreach my $field (qw (customer peer provider sibling))
        {
            if ( defined( $asns->{$key}->{$field} ) )
            {
                print "\t\t $field: " . ( join ", ", map { $_->get_as_number() } @{ $asns->{$key}->{$field} } ) . "\n";
            }
        }
    }
}

sub get_complexity
{
    my ($self) = @_;

    my $asns = $self->{asn_nodes};

    my $sum_monitorable_ips = sum map { $_->get_effective_monitorable_ip_address_count() } values %{$asns};

    #exclude rest_of_world node
    my $total_isps = scalar(keys %{$asns} ) - 1;

    my $total_ips =  $self->_get_total_ips();

    return $total_ips*$sum_monitorable_ips/$total_ips;
}

sub xml_summary
{
    my ($self) = @_;

    my $xml_graph = XML::LibXML::Element->new('summary');

    my $asns = $self->{asn_nodes};

    my $total_ips = $self->_get_total_ips();

    die "Could not get total ips" unless defined($total_ips);

    $xml_graph->appendTextChild( 'total_ips',  $total_ips );
    $xml_graph->appendTextChild( 'total_asns', $self->get_country_as_nodes_count() );
    $xml_graph->appendTextChild( 'complexity', $self->get_complexity );

    $self->die_if_cyclic();

    my $ninety_percent_control_asns = $self->get_asns_controlling_ninty_percent();

    my $ninty_percent_list_xml = XML::LibXML::Element->new('ninty_percent_asns');

    $ninty_percent_list_xml->setAttribute( 'count', scalar( @{$ninety_percent_control_asns} ) );

    $ninty_percent_list_xml->appendText( join ", ", @{$ninety_percent_control_asns} );

    $xml_graph->appendChild($ninty_percent_list_xml);

    my @asn_keys = @{ $self->_get_top_country_asns };

    foreach my $key (@asn_keys)
    {
        my $asn_info = $asns->{$key}->get_statistics();

        my $asn_xml = XML::LibXML::Element->new('as');

        foreach my $attrib_key ( sort keys %{$asn_info} )
        {
            $asn_xml->appendTextChild( $attrib_key, $asn_info->{$attrib_key} );
        }

        $asn_xml->appendTextChild( 'percent_monitorable', $asn_info->{monitorable_ips} / $total_ips * 100.0 );

        $xml_graph->appendChild($asn_xml);
    }

    return $xml_graph;
}

sub get_as_node_or_rest_of_world_node
{
    my ( $self, $asn, $country_code ) = @_;

    confess unless defined($country_code);
    if ( defined( $asn->get_country_code() ) && ( $asn->get_country_code() eq $country_code ) )
    {
        return $self->get_as_node( $asn->get_as_number );
    }
    else
    {
        return $self->get_as_node("REST_OF_WORLD");
    }
}

sub _asn_equals_country_code
{
    my ( $asn, $country_code ) = @_;

    return defined( $asn->get_country_code ) && $asn->get_country_code eq $country_code;
}

#creates a new graph based on the old graph expect that all nodes not in country are replaced with rest_of_the_world
# We are creating new AS class objects for each of the nodes in the old graph bc/ we need to modify relationship lists.
# The newly created AS node objects are "owned" by the new graph
sub get_country_specific_sub_graph
{
    my ( $self, $country_code ) = @_;

    my $ret = AsnGraph->new();

    my $asns = $self->{asn_nodes};
    foreach my $old_asn ( values %{$asns} )
    {

        #create a new asn node for the new graph for node that weren't in the country replace them with rest_of_world_node
        #next unless _asn_equals_country_code($old_asn, $country_code);

        my $new_asn = $ret->get_as_node_or_rest_of_world_node( $old_asn, $country_code );

        foreach my $relationship_type ( $old_asn->get_relationship_types() )
        {
            my @rel_list =
              map { $ret->get_as_node_or_rest_of_world_node( $_, $country_code ) }

              #grep {_asn_equals_country_code($_, $country_code) }
              @{ $old_asn->{$relationship_type} };
            @rel_list = uniq @rel_list;
            push @{ $new_asn->{$relationship_type} }, @rel_list;
            $new_asn->{$relationship_type} = [ uniq @{ $new_asn->{$relationship_type} } ];

    # $new_asn->{$relationship_type} = [ grep {$_->get_as_number  ne'REST_OF_WORLD'}   @{ $new_asn->{$relationship_type} } ];
        }
    }

    return $ret;
}

1;
