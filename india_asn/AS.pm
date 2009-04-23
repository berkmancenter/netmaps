package AS;

use strict;
use List::MoreUtils qw(uniq none any);
use List::Util qw(sum);
use List::Pairwise qw (grepp);
use GraphViz;
use AsnUtils;
use AsnInfo;
use AsnIPCount;
use AsnTaxonomyClass;
use Data::Dumper;
use Scalar::Util qw ( weaken);
use Encode;

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

sub is_rest_of_world
{
    my ($self) = @_;

    return $self->get_as_number eq 'REST_OF_WORLD';
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

    return 0 if ( $self->{as_number} eq 'REST_OF_WORLD' );

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
          grep { $self->{as_number} ne 'REST_OF_WORLD' } @{ $self->get_customers }
    ];
}

sub get_downstream_ip_address_count
{
    my ($self) = @_;

    return 0 if ( $self->{as_number} eq 'REST_OF_WORLD' );

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

sub get_monitorable_ip_address_count
{
    my ($self) = @_;

    if ( !defined( $self->{_monitorable_ips} ) )
    {
        $self->{_monitorable_ips} = $self->get_asn_ip_address_count() + $self->get_downstream_ip_address_count();
    }

    return $self->{_monitorable_ips};
}

sub get_effective_monitorable_ip_address_count
{
    my ( $self, $downstream_exclude_list ) = @_;

    #todo decide on caching and make work with $downstream_exclude_list
    #if (!defined($self->{_effective_monitorable_ips}))
    {
        $self->{_effective_monitorable_ips} =
          $self->get_asn_ip_address_count() +
          $self->get_effective_monitorable_downstream_ip_address_count($downstream_exclude_list);
    }

    return $self->{_effective_monitorable_ips};
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

sub get_effective_monitorable_downstream_ip_address_count
{

    my ( $self, $downstream_exclude_list ) = @_;

    return 0 if ( $self->{as_number} eq 'REST_OF_WORLD' );

    my $customers = $self->get_customers;

    return 0 if ( scalar( @{$customers} ) == 0 );

    my $sum = 0;

    foreach my $customer_asn ( @{$customers} )
    {
        if ( !_is_inlist( $customer_asn, $downstream_exclude_list ) )
        {
            $sum +=
              $customer_asn->get_effective_monitorable_ip_address_count($downstream_exclude_list) /
              $customer_asn->get_number_of_providers;
        }
        else
        {

            #print "Not double counting " . $customer_asn->get_as_number() . "\n";
        }
    }

    return $sum;

    ##todo the code below should work but it doesn't
    if ( defined($downstream_exclude_list) && scalar( @{$downstream_exclude_list} ) )
    {

        #print Dumper ($customers->[0]);
        print "All customers\n";
        print join ", ", map { ref $_ } @{$customers};
        print "\n";
        my $lca = List::Compare->new( $customers, $downstream_exclude_list );

        #$customers = $lca->get_Lonly_ref;
        $customers = _my_exclude( $customers, $downstream_exclude_list );

        #$customers = \ @temp;

        print "Customers after exclude\n";
        print join ", ", map { ref $_ } @{$customers};
        print "\n";

        #print Dumper ($customers->[0]);
        return 0 if ( scalar( @{$customers} ) == 0 );
    }

    return sum map { ( $_->get_effective_monitorable_ip_address_count / $_->get_number_of_providers ) } @{$customers};
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
