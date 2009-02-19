package AsnGraph;

use strict;
use List::MoreUtils qw(uniq);
use List::Pairwise qw (grepp);
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
    foreach my $field (qw (customers peers))
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

sub print_graphviz
{

    my ($self) = @_;

    my $g = GraphViz->new( layout => 'twopi', ratio => 'auto', overlap => 'scale' );

    my $asns = $self->{asn_nodes};

    foreach my $key ( sort keys(%$asns) )
    {
        foreach my $field (qw  (customer peer))
        {
            foreach my $child ( uniq sort { $a->get_as_number() cmp $b->get_as_number() }
                @{ $asns->{$key}->get_nodes_for_relationship($field) } )
            {
                $g->add_edge( $key => $child->get_as_number() );

                #                        print "\t\t $field:$key " . $child->get_as_number(). "\n";
            }
        }
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

    foreach my $key ( reverse sort { _total_connections( $asns->{$a} ) <=> _total_connections( $asns->{$b} ) } keys(%$asns) )
    {
        print "\tTotal downstream connections for AS$key: " . _total_connections( $asns->{$key} ) . "\n";
        foreach my $field (qw (customers peers providers siblings))
        {
            if ( defined( $asns->{$key}->{$field} ) )
            {
                print "\t\t $field: " . ( join ", ", @{ $asns->{$key}->{$field} } ) . "\n";
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
