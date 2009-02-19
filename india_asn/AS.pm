package AS;

use strict;
use List::MoreUtils qw(uniq);
use List::Pairwise qw (grepp);
use GraphViz;
use AsnUtils;

# MODULES

# CONSTANTS

my $get_relationship_name = {
    -1 => 'customer',
    0  => 'peer',
    1  => 'provider',
    2  => 'sibling',
};

# STATICS

# METHODS

sub new
{
    my ( $class, $as_number ) = @_;

    my $self = {};

    $self->{as_number} = $as_number;

    foreach my $relationship_name ( values %{$get_relationship_name} )
    {
        $self->{$relationship_name} = [];
    }
    bless( $self, $class );

    return $self;
}

sub get_country_code
{
    my ($self) = @_;

    return AsnUtils::get_asn_country_code( $self->{as_number} );
}

sub get_as_number
{
    my ($self) = @_;

    return $self->{as_number};
}

sub add_relationship
{
    my ( $self, $other_as, $relationship_name ) = @_;

    # my  = $get_relationship_name->{$relationship_type};
    # die "Invalid relationship_type: $relationship_type" unless defined($relationship_name);
    die unless grep { $_ eq $relationship_name } values %{$get_relationship_name};

    push @{ $self->{$relationship_name} }, $other_as;
}

sub get_relationship_types
{
    my ($self) = @_;

    return values %{$get_relationship_name};
}

sub get_nodes_for_relationship
{
    my ( $self, $relationship_name ) = @_;

    die unless grep { $_ eq $relationship_name } values %{$get_relationship_name};

    return $self->{$relationship_name};
}

1;
