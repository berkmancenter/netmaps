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
    my ($self, $as_number) = @_;

    if (!defined ($self->{asn_nodes}->{$as_number} ) )
    {
        $self->{asn_nodes}->{$as_number} = AS->new($as_number);
    }

    return  $self->{asn_nodes}->{$as_number};
}

sub print_graphviz
{

    my ($self) = @_;

    my $g = GraphViz->new( layout => 'twopi', ratio => 'auto' );

    my $asns = $self->{asn_nodes};

    foreach my $key ( keys(%$asns) )
    {
        foreach my $field (qw  (customer peer))
        {
            foreach my $child ( @{$asns->{$key}->get_nodes_for_relationship($field)}  )
            {
                $g->add_edge( $key => $child->get_as_number() );

        #                        print "\t\t $field:$key " . $child->get_as_number(). "\n";
            }
        }
    }

    print $g->as_canon;
}

sub print_asn_graph
{
    my ($self) = @_;

    my $asns = $self->{asn_tree};

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

sub print_connections_per_asn
{
    my ($self) = @_;

    my $asns = $self->{asn_tree};

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

# sub get_country_specific_sub_graph
# {
#     my ($self, $country_code) = @_;

#     my $asns = $self->{asn_tree};

#     my %country_specific_asns = grepp { (AsnUtils::get_asn_country_code($a) eq $country_code) } %{$asns};

#     %country_specific_asns = mapp { $a => _remove_asn_outside_of_country($b, $country_code) }  %country_specific_asns;

#     my $ret = AsnGraph->new();

#     $ret->{asn_tree} = \%country_specific_asns;

#     return $ret;
# }

1;
