package AsnGraph;

use strict;
use List::MoreUtils qw(uniq);
use List::Pairwise qw (grepp);
use List::Util qw (sum);
use GraphViz;
use AsnUtils;
use AS;

# MODULES

# CONSTANTS

# max number of pages the handler will download for a single story

# STATICS

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
                $g->add_edge( $key => $child->get_as_number() );

                #                        print "\t\t $field:$key " . $child->get_as_number(). "\n";
            }
        }

        $parent_nodes_processed++;
    }

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
    
    my @country_list = uniq (sort (map {$_->get_country_code()} values %{$asns}));
    
    return \@country_list
}

sub print_connections_per_asn
{
    my ($self) = @_;

    my $asns = $self->{asn_nodes};

    my $total_ips = $self->_get_total_ips();

    print "ASN graph has $total_ips total ips\n";

    foreach my $key ( reverse sort { $asns->{$a}->get_monitorable_ip_address_count() <=>  $asns->{$b}->get_monitorable_ip_address_count() } keys(%$asns) )
    {
        print "\tTotal downstream connections for AS$key: " . _total_connections( $asns->{$key} )  . "\n";
        if ($key ne 'REST_OF_WORLD') 
        {
            print "\tDirect IPs for AS$key: " . $asns->{$key}->get_asn_ip_address_count() . "\n";
            print "\tDownstream IPs for AS$key: " . $asns->{$key}->get_downstream_ip_address_count() . "\n";
            print "\tMonitorable IPs for AS$key: " . $asns->{$key}->get_monitorable_ip_address_count() . "\n";
            print "\tPercent of all total IPs monitorable: " . $asns->{$key}->get_monitorable_ip_address_count()/ $total_ips *100.0 . "\n";
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

    if ( defined( $asn->get_country_code() ) && ( $asn->get_country_code() eq $country_code ) )
    {
        return $self->get_as_node( $asn->get_as_number );
    }
    else
    {
        return $self->get_as_node("REST_OF_WORLD");
    }
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
        my $new_asn = $ret->get_as_node_or_rest_of_world_node( $old_asn, $country_code );

        foreach my $relationship_type ( $old_asn->get_relationship_types() )
        {
            my @rel_list =
              map { $ret->get_as_node_or_rest_of_world_node( $_, $country_code ) } @{ $old_asn->{$relationship_type} };
            @rel_list = uniq @rel_list;
            push @{ $new_asn->{$relationship_type} }, @rel_list;
            $new_asn->{$relationship_type} = [ uniq @{ $new_asn->{$relationship_type} } ];
        }
    }

    return $ret;
}

1;
