package AS;

use strict;
use List::MoreUtils qw(uniq none any);
use List::Util qw(first sum);
use List::Pairwise qw (grepp);
use GraphViz;
use Carp;
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

    $self->{ as_number } = $as_number;

    foreach my $relationship_name ( values %{ $get_relationship_name } )
    {
        $self->{ $relationship_name } = [];
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
    my ( $self ) = @_;

    my $customers = $self->get_customers();
    my $providers = $self->get_providers();
    print "\$providers " . join( ", ", @{ $providers } ) . "\n";
    my @intersection = get_intersection( $customers, $providers );
    print "intersection " . Dumper( \@intersection );
    map { bless \$_ } @intersection;

    return \@intersection;
}

sub _list_contains
{
    ( my $value, my $list ) = @_;

    print "_list_contains $value ";

    my $ret = any { $_ eq $value } @{ $list };

    print $ret? "true\n" : "false\n";
    return $ret;
}

sub purge_from_customer_list
{
    ( my $self, my $other_as ) = @_;

    my $providers = $self->get_customers();

    my $i = 0;
    while ( $i < scalar( @{ $providers } ) )
    {
        if ( $providers->[ $i ] == $other_as )
        {
            print "Purging " . $other_as->get_as_number() . "from " . $self->get_as_number() . "\n";
            splice( @{ $providers }, $i );
        }
        else
        {
            $i++;
        }
    }

}

sub mark_effective_peers
{
    my ( $self ) = @_;

    my $effective_peers = $self->find_effective_peers();

    #no peers to mark
    return if ( scalar( @{ $self->find_effective_peers } ) == 0 );

    print "ASN: " . $self->get_as_number() . "\n";

    my $customers = $self->get_customers();
    my $providers = $self->get_providers();

    print 'effective_peers ' . join( ", ", map { $_->get_as_number } @{ $effective_peers } ) . "\n";

    #my $lc1 = List::Compare->new($customers, $effective_peers);
    $customers = [ grep { !_list_contains( $_, $effective_peers ) } @{ $customers } ];

    $self->{ customer } = $customers;

    #print 'providers ' . join (", ", @{$providers}) . "\n";
    my $lc2 = List::Compare->new( $providers, $effective_peers );

    $providers = [ grep { !_list_contains( $_, $effective_peers ) } @{ $providers } ];

    #$providers= $lc2->get_Lonly_ref;
    #print 'providers ' . join (", ", @{$providers}) . "\n";
    $self->{ provider } = $providers;
    $providers = $self->get_providers();

    #print 'providers ' . join (", ", @{$providers}) . "\n";

    foreach my $peer ( @{ $effective_peers } )
    {
        $self->add_relationship( $peer, 'peer' );
    }

    $effective_peers = $self->find_effective_peers();
    die 'Error effective_peers not empty ' . join( ", ", @{ $effective_peers } ) . "\n"
      unless scalar( @{ $effective_peers } ) == 0;
}

sub get_country_code
{
    my ( $self ) = @_;

    return AsnUtils::get_asn_country_code( $self->{ as_number } );
}

sub is_rest_of_world
{
    my ( $self ) = @_;

    return $self->get_as_number eq AS::get_rest_of_the_world_name();
}

sub only_connects_to_rest_of_world
{
    my ( $self ) = @_;

    #print Dumper($self);
    #print Dumper(get_relationship_types());
    #print grep {! $_->is_rest_of_world } map { @{$self->get_nodes_for_relationship($_)} } get_relationship_types();
    #print "\n";
    return none { !$_->is_rest_of_world } map { @{ $self->get_nodes_for_relationship( $_ ) } } get_relationship_types();
}

sub get_as_number
{
    my ( $self ) = @_;

    return $self->{ as_number };
}

sub add_relationship
{
    my ( $self, $other_as, $relationship_name ) = @_;

    # my  = $get_relationship_name->{$relationship_type};
    # die "Invalid relationship_type: $relationship_type" unless defined($relationship_name);
    die unless grep { $_ eq $relationship_name } values %{ $get_relationship_name };

    push @{ $self->{ $relationship_name } }, $other_as;

    if ( $relationship_name ne 'provider' )
    {

        #todo
        #weaken($other_as);
    }
}

sub get_relationship_types
{
    my ( $self ) = @_;

    return values %{ $get_relationship_name };
}

sub get_nodes_for_relationship
{
    my ( $self, $relationship_name ) = @_;

    die "Invalid relationship_name: '$relationship_name'"
      unless grep { $_ eq $relationship_name } values %{ $get_relationship_name };

    return $self->{ $relationship_name };
}

sub get_asn_ip_address_count
{
    my ( $self ) = @_;

    #print STDERR "get_asn_ip_address_count " . $self->{as_number} . "\n";

    return 0 if ( $self->is_rest_of_world );

    if ( !defined( $self->{ _asn_ip_address_count } ) )
    {
        my $ret = AsnIPCount::get_ip_address_count_for_asn( $self->{ as_number } );

        $ret ||= 0;
        $self->{ _asn_ip_address_count } = $ret;
    }

    return $self->{ _asn_ip_address_count };
}

sub get_downstream_asns
{
    my ( $self ) = @_;

    #print STDERR "get_downstream_asns " . $self->{as_number} . "\n";

    return [
        uniq map { $_, @{ $_->get_downstream_asns } }
          grep { !$self->is_rest_of_world } @{ $self->get_customers }
    ];
}

sub get_downstream_ip_address_count
{
    my ( $self ) = @_;

    return 0 if ( $self->is_rest_of_world );

    my $downstream_asns = $self->get_downstream_asns;

    if ( @{ $downstream_asns } == 0 )
    {
        return 0;
    }

    return sum map { $_->get_asn_ip_address_count() } @{ $downstream_asns };
}

sub get_customers
{
    my ( $self ) = @_;

    return $self->get_nodes_for_relationship( 'customer' );
}

sub get_providers
{
    my ( $self ) = @_;

    return $self->get_nodes_for_relationship( 'provider' );
}

sub number_of_customers
{
    my ( $self ) = @_;
    return scalar( @{ $self->get_customers } );
}

sub get_provider_with_most_customers
{
    my ( $self ) = @_;

    return if !defined( $self->get_providers );

    my @providers = @{ $self->get_providers };

    if ( any { $_->is_rest_of_world } @providers )
    {
        return first { $_->is_rest_of_world } @providers;
    }

    my @providers_sorted =
      sort { $a->number_of_customers <=> $b->number_of_customers or $b->get_as_number <=> $a->get_as_number } @providers;

    #     print $self->get_as_number;
    #     print "\n";
    #     print "\t";
    #     print join "\t\n", ( map { $_->get_as_number . " customers " . $_->number_of_customers } @providers_sorted );
    my $provider_with_most_customers = pop @providers_sorted;

    #     print "\n";
    #     print "Provider with most customers: " . $provider_with_most_customers->get_as_number;
    #     print "\n";
    return $provider_with_most_customers;
}

sub _get_owned_downstream_ip_address_count
{

    my ( $self, $downstream_exclude_list, $monitorable_calculation_type ) = @_;

    return 0 if ( $self->is_rest_of_world );

    my $customers = $self->get_customers;

    return 0 if ( scalar( @{ $customers } ) == 0 );

    #return $self->get_downstream_ip_address_count() if $monitorable_calculation_type == MONITORABLE_CALCULATION_MAXIMAL;

    my $sum = 0;

  LOOP:
    foreach my $customer_asn ( @{ $customers } )
    {
        die unless defined( $customer_asn );

        if ( !_is_inlist( $customer_asn, $downstream_exclude_list ) )
        {
            my $customer_owned_ip_count =
              $customer_asn->_get_monitorable_ip_address_count_impl( $downstream_exclude_list,
                $monitorable_calculation_type );

            my $parent_amount;

            given ( $monitorable_calculation_type )
            {
                when MONITORABLE_CALCULATION_PROPORTIONAL
                {
                    $DB::single = 2 if $customer_asn->get_number_of_providers == 0;
                    $parent_amount = $customer_owned_ip_count / $customer_asn->get_number_of_providers;
                }
                when MONITORABLE_CALCULATION_MAXIMAL
                {
                    push @{ $downstream_exclude_list }, $customer_asn;
                    $parent_amount = $customer_owned_ip_count;
                }
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
                default { die "illegal calculation_type $_"; };
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

sub _get_downstream_asn_hash
{
    my ( $self ) = @_;

    if ( !defined( $self->{ downstream_asn_hash } ) )
    {
        my $downstream_asns = $self->get_downstream_asns();
        my $downstream_asn_hash = { map { $_->get_as_number() => 1 } @$downstream_asns };

        $self->{ downstream_asn_hash } = $downstream_asn_hash;
    }

    return $self->{ downstream_asn_hash };
}

sub _get_monitorable_ip_address_count_empty_list
{

    my ( $self, $monitorable_calculation_type ) = @_;

    if ( !defined( $self->{ _monitorables_ip_count }->{ $monitorable_calculation_type } ) )
    {

        #confess "updating cache";
        #  print "Filling cache\n";
        my $count =
          $self->get_asn_ip_address_count() +
          $self->_get_owned_downstream_ip_address_count( [], $monitorable_calculation_type );

        $self->{ _monitorables_ip_count }->{ $monitorable_calculation_type } = $count;

        print "caching monitorable ip address count for " . $self->get_as_number() . "\n";
    }

    return $self->{ _monitorables_ip_count }->{ $monitorable_calculation_type };
}

sub purge_ip_address_count_cache
{
    my ( $self ) = @_;

    undef( $self->{ _monitorables_ip_count } );

    undef( $self->{ _monitorables_ip_count_ignore_exclude } );
}

sub _get_monitorable_ip_address_count_impl
{
    my ( $self, $downstream_exclude_list, $monitorable_calculation_type ) = @_;

    my $empty_exclude_list = 0;

    die unless defined( $monitorable_calculation_type );

    if ( $monitorable_calculation_type ==  MONITORABLE_CALCULATION_MAXIMAL )
    {
      return $self->get_asn_ip_address_count() +
	$self->_get_owned_downstream_ip_address_count( $downstream_exclude_list, $monitorable_calculation_type );
    }

    print "starting _get_monitorable_ip_address_count_impl " . $self->get_as_number() . "\n";

    if ( !$downstream_exclude_list || ( scalar( @{ $downstream_exclude_list } ) == 0 ) )
    {
        $empty_exclude_list = 1;
    }
    elsif ( ( scalar( @{ $downstream_exclude_list } ) == 1 ) && ( $downstream_exclude_list->[ 0 ] == $self ) )
    {
        $empty_exclude_list = 1;
    }

    if ( $empty_exclude_list )
    {
        return $self->_get_monitorable_ip_address_count_empty_list( $monitorable_calculation_type );
    }

    print "geting downstream asn hash _get_monitorable_ip_address_count_impl " . $self->get_as_number() . "\n";
    my $downstream_asn_hash = $self->_get_downstream_asn_hash();

    #    my $downstream_asns = $self->get_downstream_asns();

    print "got downstream asn hash _get_monitorable_ip_address_count_impl " . $self->get_as_number() . "\n";

    #my $lc = List::Compare->new('-a', $downstream_asns, $downstream_exclude_list);

    #my @overlap = $lc->get_union();

    my $exclude_list_asn_numbers = [ map { $_->get_as_number() } @{ $downstream_exclude_list } ];

    my $downstream_asns_in_exclude_list = [ grep { $downstream_asn_hash->{ $_ } } @{ $exclude_list_asn_numbers } ];

    #    my $downstream_asns_in_exclude_list = any { _list_contains( $_, $downstream_asns ) } @{ $downstream_exclude_list };

    if ( scalar( @$downstream_asns_in_exclude_list ) == 0 )

      #    if ( scalar(@overlap) == 0 )
    {

        print "downstream asns not in exclude list\n";

        #print $self->get_as_number . " " .
        #  Dumper( $downstream_asn_hash ) . " exclude list " . Dumper( $exclude_list_asn_numbers ) .  "\n";

        return $self->_get_monitorable_ip_address_count_empty_list( $monitorable_calculation_type );

        if ( !defined( $self->{ _monitorables_ip_count_ignore_exclude }->{ $monitorable_calculation_type } ) )
        {
            $self->{ _monitorables_ip_count_ignore_exclude }->{ $monitorable_calculation_type } =
              $self->get_asn_ip_address_count() +
              $self->_get_owned_downstream_ip_address_count( $downstream_exclude_list, $monitorable_calculation_type );
        }

        # else
        # {
        #     # my $expected =
        #     #   $self->get_asn_ip_address_count() +
        #     #   $self->_get_owned_downstream_ip_address_count( $downstream_exclude_list, $monitorable_calculation_type );

        #     my $ret = $self->{ _monitorables_ip_count_ignore_exclude }->{ $monitorable_calculation_type };
        #     # if ( $ret != $expected )
        #     # {
        #     #     confess "Cache returns a different value $ret vs $expected ASN " . $self->get_as_number . " " .
        #     #       Dumper( $downstream_asn_hash ) . " exclude list " . Dumper( $exclude_list_asn_numbers );
        #     # }
        # }

        return $self->{ _monitorables_ip_count_ignore_exclude }->{ $monitorable_calculation_type };
    }

    print " _get_monitorable_ip_address_count_impl " . $self->get_as_number . " Not ignoring exclude list\n";

    my $exclude_list_key = join '____', @$downstream_asns_in_exclude_list;

    print "Exclude_list_key: '$exclude_list_key'\n";

    if ( !defined( $self->{ "exclude_list_downstream$monitorable_calculation_type" }->{ $exclude_list_key } ) )
    {
        my $temp =
          $self->get_asn_ip_address_count() +
          $self->_get_owned_downstream_ip_address_count( $downstream_exclude_list, $monitorable_calculation_type );

	$self->{ "exclude_list_downstream$monitorable_calculation_type" }->{ $exclude_list_key } 
	  = $temp;
    }

    return $self->{ "exclude_list_downstream$monitorable_calculation_type" }->{ $exclude_list_key } ;

    my $ret = 
      $self->get_asn_ip_address_count() +
      $self->_get_owned_downstream_ip_address_count( $downstream_exclude_list, $monitorable_calculation_type );

    return $ret;
}

sub get_monitorable_ip_address_count
{
    my ( $self, $downstream_exclude_list ) = @_;

    $downstream_exclude_list = [] if !defined( $downstream_exclude_list );

    my @temp_array = @{ $downstream_exclude_list };

    push( @temp_array, $self );

    return $self->_get_monitorable_ip_address_count_impl( $downstream_exclude_list, MONITORABLE_CALCULATION_MAXIMAL );
}

sub get_effective_monitorable_ip_address_count
{
    my ( $self, $downstream_exclude_list ) = @_;

    return $self->_get_monitorable_ip_address_count_impl( $downstream_exclude_list, MONITORABLE_CALCULATION_PROPORTIONAL );
}

sub get_min_complexity_monitorable_ip_address_count
{
    my ( $self, $downstream_exclude_list ) = @_;

    return $self->_get_monitorable_ip_address_count_impl( $downstream_exclude_list, MONITORABLE_CALCULATION_BIGESTPARENT );
}

sub get_number_of_providers
{
    my ( $self ) = @_;

    return scalar( @{ $self->{ provider } } );
}

sub _is_inlist
{
    my ( $val, $list ) = @_;

    return 0 if ( !defined( $list ) || ( scalar( @{ $list } ) == 0 ) );

    #print "val: $val\n";
    #print "list: $list->[0]\n";

    return any { $_->get_as_number() eq $val->get_as_number() } @{ $list };
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
        my $asn_name = $stats->{ organization_name };
        $ret .= "$asn_name\n";
        if ( defined( $stats->{ type } ) )
        {
            $ret .= "Type: " . $stats->{ type } . "\n";
        }
        $ret .= "Direct IPs: " . $stats->{ direct_ips } . "\n";
        $ret .= "Downstream IPs: " . $stats->{ downstream_ips } . "\n";
        $ret .= "Monitorable IPs: " . $stats->{ effective_monitorable_ips } . "\n";
        if ( defined( $total_country_ips ) )
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
    my ( $self ) = @_;

    my $ret = 0;
    foreach my $field ( qw (customer peer) )
    {
        if ( defined( $self->{ $field } ) )
        {
            $ret += uniq @{ $self->{ $field } };
        }
    }

    return $ret;
}

my $direct_info_only = 0;

sub get_statistics
{
    ( my $asn ) = @_;
    my $ret = {};

    die unless defined $asn;

    if ( !defined( $asn->{ _statistics } ) )
    {
        $ret->{ total_connections } = $asn->total_connections();
        $ret->{ direct_ips }        = $asn->get_asn_ip_address_count();

        unless ( $direct_info_only )
        {
            $ret->{ downstream_ips }            = $asn->get_downstream_ip_address_count();
            $ret->{ effective_monitorable_ips } = $asn->get_effective_monitorable_ip_address_count( undef );
            $ret->{ actual_monitorable_ips }    = $asn->get_monitorable_ip_address_count();
        }
        $ret->{ asn }               = $asn->get_as_number();
        $ret->{ organization_name } = encode( "utf8", AsnInfo::get_asn_organization_description( $ret->{ asn } ) || "" );
        $ret->{ customers }         = join ",", map { $_->get_as_number() } @{ $asn->get_customers() };
        $ret->{ type }              = AsnTaxonomyClass::get_asn_taxonomy_class( $asn->get_as_number() )
          || 'unknown';
        $asn->{ _statistics } = $ret;

    }

    return $asn->{ _statistics };
}

1;
