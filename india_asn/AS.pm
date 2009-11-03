package AS;

use strict;
use List::MoreUtils qw(uniq none any);
use List::Util qw(first sum);
use List::Pairwise qw (grepp);
use GraphViz;
use AsnUtils;
use AsnInfo;
use AsnIPCount;
use AsnTaxonomyClass;
use Data::Dumper;
use Scalar::Util qw ( weaken);
use Encode;
use Set::Intersection;
use Readonly;
use Switch 'Perl6';
use enum qw(:MONITORABLE_CALCULATION_ PROPORTIONAL MAXIMAL BIGESTPARENT);

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

sub get_rest_of_the_world_name
{
    Readonly my $_rest_of_the_world_name => "REST_OF_WORLD";
    return $_rest_of_the_world_name;
}

#return the list of nodes that we have both customer and provider relationships with
sub find_effective_peers
{
    my ($self) = @_;

    my $customers = $self->get_customers();
    my $providers = $self->get_providers();
    print "\$providers " . join( ", ", @{$providers} ) . "\n";
    my @intersection = get_intersection( $customers, $providers );
    print "intersection " . Dumper( \@intersection );
    map { bless \$_ } @intersection;

    return \@intersection;
}

sub _list_contains
{
    ( my $value, my $list ) = @_;

    print "_list_contains $value ";

    my $ret = any { $_ eq $value } @{$list};

    print $ret? "true\n" : "false\n";
    return $ret;
}

sub purge_from_customer_list
{
    ( my $self, my $other_as ) = @_;

    my $providers = $self->get_customers();

    my $i = 0;
    while ( $i < scalar( @{$providers} ) )
    {
        if ( $providers->[$i] == $other_as )
        {
            print "Purging " . $other_as->get_as_number() . "from " . $self->get_as_number() . "\n";
            splice( @{$providers}, $i );
        }
        else
        {
            $i++;
        }
    }

}

sub mark_effective_peers
{
    my ($self) = @_;

    my $effective_peers = $self->find_effective_peers();

    #no peers to mark
    return if ( scalar( @{ $self->find_effective_peers } ) == 0 );

    print "ASN: " . $self->get_as_number() . "\n";

    my $customers = $self->get_customers();
    my $providers = $self->get_providers();

    print 'effective_peers ' . join( ", ", map { $_->get_as_number } @{$effective_peers} ) . "\n";

    #my $lc1 = List::Compare->new($customers, $effective_peers);
    $customers = [ grep { !_list_contains( $_, $effective_peers ) } @{$customers} ];

    $self->{customer} = $customers;

    #print 'providers ' . join (", ", @{$providers}) . "\n";
    my $lc2 = List::Compare->new( $providers, $effective_peers );

    $providers = [ grep { !_list_contains( $_, $effective_peers ) } @{$providers} ];

    #$providers= $lc2->get_Lonly_ref;
    #print 'providers ' . join (", ", @{$providers}) . "\n";
    $self->{provider} = $providers;
    $providers = $self->get_providers();

    #print 'providers ' . join (", ", @{$providers}) . "\n";

    foreach my $peer ( @{$effective_peers} )
    {
        $self->add_relationship( $peer, 'peer' );
    }

    $effective_peers = $self->find_effective_peers();
    die 'Error effective_peers not empty ' . join( ", ", @{$effective_peers} ) . "\n"
      unless scalar( @{$effective_peers} ) == 0;
}

sub get_country_code
{
    my ($self) = @_;

    return AsnUtils::get_asn_country_code( $self->{as_number} );
}

sub is_rest_of_world
{
    my ($self) = @_;

    return $self->get_as_number eq AS::get_rest_of_the_world_name();
}

sub only_connects_to_rest_of_world
{
    my ($self) = @_;

    #print Dumper($self);
    #print Dumper(get_relationship_types());
    #print grep {! $_->is_rest_of_world } map { @{$self->get_nodes_for_relationship($_)} } get_relationship_types();
    #print "\n";
    return none { !$_->is_rest_of_world } map { @{ $self->get_nodes_for_relationship($_) } } get_relationship_types();
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

    if ( $relationship_name ne 'provider' )
    {

        #todo
        #weaken($other_as);
    }
}

sub get_relationship_types
{
    my ($self) = @_;

    return values %{$get_relationship_name};
}

sub get_nodes_for_relationship
{
    my ( $self, $relationship_name ) = @_;

    die "Invalid relationship_name: '$relationship_name'"
      unless grep { $_ eq $relationship_name } values %{$get_relationship_name};

    return $self->{$relationship_name};
}

sub get_asn_ip_address_count
{
    my ($self) = @_;

    #print STDERR "get_asn_ip_address_count " . $self->{as_number} . "\n";

    return 0 if ( $self->is_rest_of_world );

    if ( !defined( $self->{_asn_ip_address_count} ) )
    {
        my $ret = AsnIPCount::get_ip_address_count_for_asn( $self->{as_number} );

        $ret ||= 0;
        $self->{_asn_ip_address_count} = $ret;
    }

    return $self->{_asn_ip_address_count};
}

sub get_downstream_asns
{
    my ($self) = @_;

    #print STDERR "get_downstream_asns " . $self->{as_number} . "\n";

    return [
        uniq map { $_, @{ $_->get_downstream_asns } }
          grep { !$self->is_rest_of_world } @{ $self->get_customers }
    ];
}

sub get_downstream_ip_address_count
{
    my ($self) = @_;

    return 0 if ( $self->is_rest_of_world );

    my $downstream_asns = $self->get_downstream_asns;

    if ( @{$downstream_asns} == 0 )
    {
        return 0;
    }

    return sum map { $_->get_asn_ip_address_count() } @{$downstream_asns};
}

sub get_customers
{
    my ($self) = @_;

    return $self->get_nodes_for_relationship('customer');
}

sub get_providers
{
    my ($self) = @_;

    return $self->get_nodes_for_relationship('provider');
}

sub number_of_customers
{
    my ($self) = @_;
    return scalar( @{ $self->get_customers } );
}

sub get_provider_with_most_customers
{
    my ($self) = @_;

    return if !defined( $_->get_providers );

    my @providers = @{ $self->get_providers };

    if ( any { $_->is_rest_of_world } @providers )
    {
        return first { $_->is_rest_of_world } @providers;
    }

    my @providers_sorted =
      sort { $a->number_of_customers <=> $b->number_of_customers or $b->get_as_number <=> $a->get_as_number } @providers;

    print $self->get_as_number;
    print "\n";
    print "\t";
    print join "\t\n", ( map { $_->get_as_number . " customers " . $_->number_of_customers } @providers_sorted );
    my $provider_with_most_customers = pop @providers_sorted;

    print "\n";
    print "Provider with most customers: " . $provider_with_most_customers->get_as_number;
    print "\n";
    return $provider_with_most_customers;
}

sub _get_owned_downstream_ip_address_count
{

    my ( $self, $downstream_exclude_list, $monitorable_calculation_type ) = @_;

    return 0 if ( $self->is_rest_of_world );

    my $customers = $self->get_customers;

    return 0 if ( scalar( @{$customers} ) == 0 );

    return $self->get_downstream_ip_address_count() if $monitorable_calculation_type == MONITORABLE_CALCULATION_MAXIMAL;

    my $sum = 0;

    foreach my $customer_asn ( @{$customers} )
    {
        if ( !_is_inlist( $customer_asn, $downstream_exclude_list ) )
        {
            my $customer_owned_ip_count =
              $customer_asn->_get_monitorable_ip_address_count_impl( $downstream_exclude_list,
                $monitorable_calculation_type );

            my $parent_amount;

            given ($monitorable_calculation_type)
            {
                when MONITORABLE_CALCULATION_PROPORTIONAL { $parent_amount = $customer_owned_ip_count / $customer_asn->get_number_of_providers; }
                when MONITORABLE_CALCULATION_MAXIMAL      { $parent_amount = $customer_owned_ip_count; }
                when MONITORABLE_CALCULATION_BIGESTPARENT
                {
                    if ( $customer_asn->get_provider_with_most_customers == $self )
                    {
                        $parent_amount += $customer_asn->get_min_complexity_monitorable_ip_address_count();
                    }
                    else
                    {
                        $parent_amount = 0;
                    }
                }
                default { die "illegal calculation_type $_"; }
            }
            
            $sum += $parent_amount;
        }
        else
        {

            #print "Not double counting " . $customer_asn->get_as_number() . "\n";
        }
    }

    return $sum;
}

sub _get_monitorable_ip_address_count_impl
{
    my ( $self, $downstream_exclude_list, $monitorable_calculation_type ) = @_;

    my $ret =
      $self->get_asn_ip_address_count() +
      $self->_get_owned_downstream_ip_address_count( $downstream_exclude_list, $monitorable_calculation_type );

    return $ret;
}

sub get_monitorable_ip_address_count
{
    my ($self, $downstream_exclude_list ) = @_;

    return $self->_get_monitorable_ip_address_count_impl( $downstream_exclude_list  , MONITORABLE_CALCULATION_MAXIMAL);
}

sub get_effective_monitorable_ip_address_count
{
    my ( $self, $downstream_exclude_list ) = @_;

    return $self->_get_monitorable_ip_address_count_impl($downstream_exclude_list, MONITORABLE_CALCULATION_PROPORTIONAL);
}

#TODO this has too much cut & paste we need to DRY up the code
#TODO combine the get_*_monitorable_ip_address_methods
sub get_min_complexity_monitorable_ip_address_count
{
    my ($self, $downstream_exclude_list) = @_;

    return $self->_get_monitorable_ip_address_count_impl($downstream_exclude_list, MONITORABLE_CALCULATION_BIGESTPARENT);
}

sub get_number_of_providers
{
    my ($self) = @_;

    return scalar( @{ $self->{provider} } );
}

sub _is_inlist
{
    my ( $val, $list ) = @_;

    return 0 if ( !defined($list) || ( scalar( @{$list} ) == 0 ) );

    #print "val: $val\n";
    #print "list: $list->[0]\n";

    return any { $_->get_as_number() eq $val->get_as_number() } @{$list};
}

sub _my_exclude
{
    my ( $list1, $list2 ) = @_;

    my @ret = grep { !_is_inlist( $_, $list2 ) } $list1;

    #@ret = map {bless $_ , "AS"} @ret;
    return \@ret;
}

sub get_graph_label
{

    my ( $self, $total_country_ips ) = @_;

    my $asn_number = $self->get_as_number;

    my $ret;

    if ( !$self->is_rest_of_world() )
    {
        $ret = "AS$asn_number";
        my $stats = $self->get_statistics();

        $ret .= "\n";

        #my $asn_name = AsnUtils::get_asn_whois_info($asn_number)->{name};
        my $asn_name = $stats->{organization_name};
        $ret .= "$asn_name\n";
        if ( defined( $stats->{type} ) )
        {
            $ret .= "Type: " . $stats->{type} . "\n";
        }
        $ret .= "Direct IPs: " . $stats->{direct_ips} . "\n";
        $ret .= "Downstream IPs: " . $stats->{downstream_ips} . "\n";
        $ret .= "Monitorable IPs: " . $stats->{effective_monitorable_ips} . "\n";
        if ( defined($total_country_ips) )
        {
            $ret .= "Can monitor " . $self->get_monitorable_ip_address_count() / $total_country_ips * 100.0 . "% of country";
        }
    }
    else
    {
        my $ten_spaces = '           ';
        my $header =
"$ten_spaces\n$ten_spaces\n$ten_spaces\n$ten_spaces\n$ten_spaces\n$ten_spaces\n$ten_spaces\n$ten_spaces\n$ten_spaces\n$ten_spaces\n$ten_spaces\n$ten_spaces\n$ten_spaces\n$ten_spaces\n$ten_spaces\n$ten_spaces\n";
        my $footer =
"$ten_spaces\n$ten_spaces\n$ten_spaces\n$ten_spaces\n$ten_spaces\n$ten_spaces\n$ten_spaces\n$ten_spaces\n$ten_spaces\n$ten_spaces\n$ten_spaces\n$ten_spaces\n$ten_spaces\n$ten_spaces\n$ten_spaces\n$ten_spaces\n";
        $ret =
".$header.$ten_spaces$ten_spaces$ten_spaces$ten_spaces$ten_spaces$ten_spaces$ten_spaces$ten_spaces REST OF THE WORLD$ten_spaces$ten_spaces$ten_spaces$ten_spaces$ten_spaces$ten_spaces$ten_spaces$ten_spaces.$footer.";
    }

    return $ret;
}

sub total_connections
{
    my ($self) = @_;

    my $ret = 0;
    foreach my $field (qw (customer peer))
    {
        if ( defined( $self->{$field} ) )
        {
            $ret += uniq @{ $self->{$field} };
        }
    }

    return $ret;
}

sub get_statistics
{
    ( my $asn ) = @_;
    my $ret = {};

    die unless defined $asn;

    if ( !defined( $asn->{_statistics} ) )
    {
        $ret->{total_connections}         = $asn->total_connections();
        $ret->{direct_ips}                = $asn->get_asn_ip_address_count();
        $ret->{downstream_ips}            = $asn->get_downstream_ip_address_count();
        $ret->{actual_monitorable_ips}    = $asn->get_monitorable_ip_address_count();
        $ret->{effective_monitorable_ips} = $asn->get_effective_monitorable_ip_address_count();
        $ret->{asn}                       = $asn->get_as_number();
        $ret->{organization_name}         = encode( "utf8", AsnInfo::get_asn_organization_description( $ret->{asn} ) || "" );
        $ret->{customers}                 = join ",", map { $_->get_as_number() } @{ $asn->get_customers() };
        $ret->{type}                      = AsnTaxonomyClass::get_asn_taxonomy_class( $asn->get_as_number() ) || 'unknown';
        $asn->{_statistics}               = $ret;

    }

    return $asn->{_statistics};
}

1;
