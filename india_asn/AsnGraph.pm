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

# MODULES

# CONSTANTS

# max number of pages the handler will download for a single story

# STATICS

my $_as_class_color = {
abstained => 'grey',
comp      => 'yellow',
edu     => 'orange',
ix     => 'purple',
nic     => 'green',
t1     => 'red',
t2     => 'blue',
};

sub _total_connections
{
    my ($asn) = @_;

    my $ret = 0;
    foreach my $field (qw (customer peer))
    {
        if ( defined( $asn->{$field} ) )
        {
            $ret += uniq @{ $asn->{$field} };
        }
    }

    return $ret;
}

# METHODS

sub new
{
    my ($class) = @_;

    my $self = {};

    $self->{asn_nodes} = {};
    bless( $self, $class );

    return $self;
}

my $_asn_cache = {};

sub get_as_node
{
    my ( $self, $as_number ) = @_;

    if ( !defined( $self->{asn_nodes}->{$as_number} ) )
    {
        $self->{asn_nodes}->{$as_number} = AS->new($as_number);
    }

    return $self->{asn_nodes}->{$as_number};
}

sub get_as_nodes_count
{
    my ($self) = @_;
    my $asns = $self->{asn_nodes};

    return scalar (keys %{$asns});
}

sub _get_total_ips
{
    my ($self) = @_;
    my $asns = $self->{asn_nodes};
    
    return sum map { $_->get_asn_ip_address_count() } values %{$asns};
}

sub print_graphviz
{

    my ($self, $max_parent_nodes) = @_;

    my $g = GraphViz->new( layout => 'twopi', 
ratio => 'auto', overlap => 'scale' 
);

    my $asns = $self->{asn_nodes};

    my $parent_nodes_processed = 0;

    foreach my $key ( sort keys(%$asns) )
    {
        if (defined($max_parent_nodes) && ($parent_nodes_processed > $max_parent_nodes))
        {
            return $g;
        }
        foreach my $field (qw  (customer peer))
        {
            foreach my $child ( uniq sort { $a->get_as_number() cmp $b->get_as_number() }
                @{ $asns->{$key}->get_nodes_for_relationship($field) } )
            {
                if ( (!$child->is_rest_of_world()) && (! $child->only_connects_to_rest_of_world()) ) {
                    $g->add_edge( $key => $child->get_as_number() );
                }
                else
                {
                    print "Skipping link $key -> " .  $child->get_as_number() . "\n";
                }
                #                        print "\t\t $field:$key " . $child->get_as_number(). "\n";
            }
        }

        $parent_nodes_processed++;
    }

    foreach my $asn_key (@{$g->{NODELIST}} )
    {
        #print "$asn_key\n";
        #if ( _total_connections( $asns->{$asn_key} ) > 2 )
        {
            $g->add_node($asn_key, label => $asns->{$asn_key}->get_graph_label() );
        }
        
        my $as_class = AsnTaxonomyClass::get_asn_taxonomy_class($asn_key);

        my $color;

        if (!defined($as_class) )
        {
            $color = 'white';
        }
        else
        {
            $color = $_as_class_color->{$as_class};
        }

        $g->add_node($asn_key, fillcolor => $color, style => 'filled');
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
                if (! $asns->{$key}->is_rest_of_world && !$child->is_rest_of_world) 
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
    
    my @country_list = uniq  map {$_->get_country_code()} values %{$asns};

    @country_list = sort @country_list;

    return \@country_list
}

sub die_if_cyclic
{
    my ($self) = @_;

    my $g = $self->_get_graph_object();

    die "Graph is cyclic: " . join (" , " , $g->find_a_cycle()) if ($g->has_a_cycle() );

    #print "Graph is not cyclic\n";
    
}

#Return the top 10 Asns plus any ASNs that can monitor 90% of the countries IPs
sub _get_top_country_asns
{
    my ($self) = @_;
    my $asns = $self->{asn_nodes};

    $self->die_if_cyclic();

    my @asn_keys = reverse sort { $asns->{$a}->get_monitorable_ip_address_count() <=>  $asns->{$b}->get_monitorable_ip_address_count() } keys(%$asns) ;
    if (scalar(@asn_keys) > 9)
    {
        @asn_keys = @asn_keys[0..9];
    }

    my $total_ips = $self->_get_total_ips();

    my @ninety_percent_monitoring_asns = grep {($asns->{$_}->get_monitorable_ip_address_count()/$total_ips) >= 0.9} keys (%$asns);

    my $lca = List::Compare->new('-u', '-a', \@asn_keys, \@ninety_percent_monitoring_asns);

    my @top_asn_keys = $lca->get_union();

    @top_asn_keys = reverse sort { $asns->{$a}->get_monitorable_ip_address_count() <=>  $asns->{$b}->get_monitorable_ip_address_count() }  @top_asn_keys;

    return \@top_asn_keys;
}

sub get_asn_information_as_hash
{
    (my $asn) = @_;
    my $ret = {};

    die unless defined $asn;

    $ret->{direct_ips} =  $asn->get_asn_ip_address_count();
    $ret->{downstream_ips} = $asn->get_downstream_ip_address_count();
    $ret->{monitorable_ips} = $asn->get_monitorable_ip_address_count();

    return $ret;
}

sub print_connections_per_asn
{
    my ($self) = @_;

    my $asns = $self->{asn_nodes};

    my $total_ips = $self->_get_total_ips();

    print "ASN graph has $total_ips total ips\n";

    $self->die_if_cyclic();

    my @asn_keys = @{$self->_get_top_country_asns};

    foreach my $key (  @asn_keys )
    {
        my $asn_name = (AsnUtils::get_asn_whois_info($key))->{name};
        print "Total downstream connections for AS$key ($asn_name): " . _total_connections( $asns->{$key} )  . "\n";
        if ($key ne 'REST_OF_WORLD') 
        {
            my $asn_info = get_asn_information_as_hash($asns->{$key});

            print "\tDirect IPs for AS$key: " . $asn_info->{direct_ips} . "\n";
            print "\tDownstream IPs for AS$key: " . $asn_info->{downstream_ips} . "\n";
            print "\tMonitorable IPs for AS$key: " . $asn_info->{monitorable_ips} . "\n";
            print "\tPercent of all total IPs monitorable: " . $asn_info->{monitorable_ips}/ $total_ips *100.0 . "\n";
            print "\n";

#             print "\tDirect IPs for AS$key: " . $asns->{$key}->get_asn_ip_address_count() . "\n";
#             print "\tDownstream IPs for AS$key: " . $asns->{$key}->get_downstream_ip_address_count() . "\n";
#             print "\tMonitorable IPs for AS$key: " . $asns->{$key}->get_monitorable_ip_address_count() . "\n";
#             print "\tPercent of all total IPs monitorable: " . $asns->{$key}->get_monitorable_ip_address_count()/ $total_ips *100.0 . "\n";
#             print "\n";
        }

         foreach my $field (qw (customer peer provider sibling))
         {
             if ( defined( $asns->{$key}->{$field} ) )
             {
                 print "\t\t $field: " . ( join ", ", map {$_->get_as_number()} @{ $asns->{$key}->{$field} } ) . "\n";
             }
         }
    }
}

# sub _remove_asns_outside_of_country
# {
#     my ($asn, $country_code) = @_;

#     foreach my $relationship_type (keys %{$asn} )
#     {
#         $asn->{$relationship_type} = \ grep { AsnUtils::get_asn_country_code($_) eq $country_code} @{$asn->{$relationship_type}};
#         if (scalar(@{$asn->{$relationship_type} == 0) ) )
#         {
#             delete ($asn->{$relationship_type});
#         }
#     }
# }

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
    my ($asn, $country_code) = @_;

    return  defined ($asn->get_country_code) && $asn->get_country_code eq $country_code
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
