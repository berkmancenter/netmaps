package AsnGraph;

use strict;
use List::MoreUtils qw(uniq);
use GraphViz;

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

    $self->{asn_tree} = {};
    bless( $self, $class );

    return $self;
}

sub add_relationship
{
    my ( $self, $asn1, $asn2, $relationship ) = @_;

    my $asns = $self->{asn_tree};

    if ( $relationship == -1 )
    {
        push @{ $asns->{$asn2}->{customers} }, $asn1;
    }
    elsif ( $relationship == 0 )
    {
        push @{ $asns->{$asn2}->{peers} }, $asn1;
    }
    elsif ( $relationship == 1 )
    {
        push @{ $asns->{$asn2}->{providers} }, $asn1;
    }
    elsif ( $relationship == 2 )
    {
        push @{ $asns->{$asn2}->{siblings} }, $asn1;
    }
    else
    {
        die "Invalid relationship value: $relationship";
    }
}

sub print_graphviz
{

    my ($self) = @_;

    my $g = GraphViz->new( layout => 'twopi', ratio => 'auto' );

    my $asns = $self->{asn_tree};

    foreach my $key ( keys(%$asns) )
    {
        foreach my $field (qw  (customers peers))
        {

            #            $g->add_node($key, label => $key);
            if ( defined( $asns->{$key}->{$field} ) )
            {
                foreach my $child ( @{ $asns->{$key}->{$field} } )
                {
                    $g->add_edge( $key => $child );

                    #                print "\t\t $field: " . (join ", " , @{$asns->{$key}->{$field}}) . "\n";
                }
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

1;
