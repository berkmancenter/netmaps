package AsnGraph;

use strict;
use List::MoreUtils qw(uniq any);
use List::Pairwise qw (grepp);
use List::Util qw (reduce sum max);
use GraphViz;
use AsnUtils;
use AS;
use Graph;
use Carp;
use AsnTaxonomyClass;
use List::Compare;
use XML::LibXML;
use Data::Dumper;
use Perl6::Say;

use enum qw(:MONITORABLE_CALCULATION_ PROPORTIONAL MAXIMAL BIGESTPARENT);

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
    t1        => 'pink',
    t2        => 'blue',
};

my $_dont_check_for_cycles = 0;

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

sub get_as_node_objects
{

  my ($self) = @_;

  my $asns = $self->{asn_nodes};

  return [ values %{$asns} ];
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

    #print Dumper($asns);
    if ( !defined( $self->{_total_ips} ) )
    {
        $self->{_total_ips} = sum map { $_->get_asn_ip_address_count() } values %{$asns};
    }

    return $self->{_total_ips};
}

sub add_edges_to_graph
{
    ( my $asns, my $g, my $show_un_country_connected_nodes, my $max_parent_nodes ) = @_;

    my $total_edges            = 0;
    my $parent_nodes_processed = 0;

    foreach my $key ( sort keys(%$asns) )
    {
        if ( defined($max_parent_nodes) && ( $parent_nodes_processed > $max_parent_nodes ) )
        {
            return $total_edges;
        }
        foreach my $field (qw  (customer peer))
        {
            foreach my $child ( uniq sort { $a->get_as_number() cmp $b->get_as_number() }
                @{ $asns->{$key}->get_nodes_for_relationship($field) } )
            {
                if (   ( !$child->is_rest_of_world() )
                    && ( $show_un_country_connected_nodes || !$child->only_connects_to_rest_of_world() ) )
                {
                    $g->add_edge( $key => $child->get_as_number() );
                    $total_edges++;
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

    return $total_edges;
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

    my $edges = add_edges_to_graph( $asns, $g, 0, $max_parent_nodes );

    if ( $edges == 0 )
    {
        $edges = add_edges_to_graph( $asns, $g, 1, $max_parent_nodes );
        die "Empty graph " if ( $edges == 0 );
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

        if ( defined($as_class) )
        {
            $color = $_as_class_color->{$as_class};
        }
        elsif ( $asns->{$asn_key}->is_rest_of_world() )
        {

            #$self->format_rest_of_world_node($g, $asns->{$asn_key});
            $color = 'red';
        }
        else
        {
            $color = 'white';
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

    my $start_time = time;
    print "Checking whether graph is acyclic... -- $start_time \n";
    my $g = $self->_get_graph_object();

    if ( $g->has_a_cycle() )
    {
        print STDERR "Attempting to fix cyclic graph\n";

        my $asns = $self->{asn_nodes};

        foreach my $asn ( values( %{$asns} ) )
        {

            #$asn->mark_effective_peers();
        }

        #$g = $self->_get_graph_object();

        while ( $g->has_a_cycle() )
        {
            my @cycle = $g->find_a_cycle();

            #All-Pairs Shortest Paths
            my $apsp = $g->APSP_Floyd_Warshall();
            print Dumper($apsp);

            print "Attempting to fix cycle: " . join( ", ", @cycle ) . "\n";
            @cycle = sort {
                $apsp->path_length( $a, AS::get_rest_of_the_world_name() )
                  <=> $apsp->path_length( $b, AS::get_rest_of_the_world_name() )
            } @cycle;

            @cycle = reverse @cycle;

            print "Path Lengths: ";
            say '' . join( ", ", map { "$_ -> " . $apsp->path_length( $_, AS::get_rest_of_the_world_name() ) } @cycle );

            my $asn_to_purge = pop @cycle;
            foreach my $asn_to_purge_from (@cycle)
            {
                $asns->{$asn_to_purge_from}->purge_from_customer_list( $asns->{$asn_to_purge} );
            }
            $g = $self->_get_graph_object();
        }
    }

    $g = $self->_get_graph_object();

    die "Graph is cyclic: " . join( " , ", $g->find_a_cycle() ) if ( $g->has_a_cycle() );

    $self->{_verified_acyclic} = 1;

    my $end_time = time;
    print "Graph is not cyclic -- $end_time\n";
    say "Graph is not cyclic -- total time " . ($end_time-$start_time);
}

sub _sort_by_monitoring
{
    my ( $self, $asn_names, $control_methodology ) = @_;

    my $asns = $self->{asn_nodes};

    $self->die_if_cyclic();

    my @ret =
      reverse
      sort {
        $asns->{$a}->_get_monitorable_ip_address_count_impl(undef, $control_methodology)
          <=> $asns->{$b}->_get_monitorable_ip_address_count_impl(undef, $control_methodology)
              or
                  $a <=> $b
      } @{$asn_names};

    return @ret;
}

sub _get_asn_names_sorted_by_monitoring
{
    my ($self, $control_methodology) = @_;
    my $asns = $self->{asn_nodes};

    $self->die_if_cyclic();
    my @ret = $self->_sort_by_monitoring( [ keys %{$asns} ], $control_methodology );

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

sub _get_percent_controlled_by_list
{
    my ( $self, $asn_list, $control_methodology ) = @_;
    my $asns = $self->{asn_nodes};

    my @asn_object_list = map { $asns->{$_} } @{$asn_list};

    #make sure we don't double count
    my $ips_monitorable =
      sum map { $asns->{$_}->_get_monitorable_ip_address_count_impl( \@asn_object_list, $control_methodology ) } @{$asn_list};

    return $ips_monitorable / $self->_get_total_ips * 100;
}

sub _monitorable_increase_gt
{
    my ($self, $poc_list, $a, $b, $control_methodology) = @_;

    #say "in _monitorable_increase_get";
    #print Dumper ($poc_list);
    #say "a = '$a'";
    #say "b = '$b'";

    my $monitorable_increase_a = $self->_get_percent_controlled_by_list( [ $a, @$poc_list] , $control_methodology);
    my $monitorable_increase_b = $self->_get_percent_controlled_by_list( [ $b, @$poc_list] , $control_methodology);

    if ($monitorable_increase_a > $monitorable_increase_b)
    {
        return 1;
    }
    elsif ($monitorable_increase_a < $monitorable_increase_b)
    {
        return 0;
    }
    else
    {
        return $a > $b;
    }
}

# sub _get_max_monitorable_increase_asn_bak
# {
#     my $self = shift;
#     my $control_methodology = shift;
#     my $ninty_percent_list = shift;
#     my $asns = shift;
#         my $asn = reduce { 
# $self->_monitorable_increase_gt( $ninty_percent_list, $a, $b,  $control_methodology  ) ? $a : $b  } @{$asns};
#     return $asn;    
# }

# sub _get_max_monitorable_increase_asn_map
# {
#     my $self = shift;
#     my $control_methodology = shift;
#     my $ninty_percent_list = shift;
#     my $asns = shift;
#     my ($asn) = map $_->[0],
#     reduce { $a->[1] > $b->[1] ? $a : $b }
#     map [ $_, $self->_get_percent_controlled_by_list( [ @$ninty_percent_list, $_] , $control_methodology) ],
#     @{$asns};

# reduce { 
# $self->_monitorable_increase_gt( $ninty_percent_list, $a, $b,  $control_methodology  ) ? $a : $b  } @{$asns};
#     return $asn;    
# }

sub _get_max_monitorable_increase_asn
{
    my $self = shift;
    my $control_methodology = shift;
    my $ninty_percent_list = shift;
    my $asns = shift;
    my $asn_monitor_percent_increase_mappings = shift;

    my $start_time = time;

    say "Starting _get_max_monitorable_increase_asn -- $start_time";

    say Dumper([ @$ninty_percent_list]);
    my $base_list_controlling_percent = $self->_get_percent_controlled_by_list( [ @$ninty_percent_list] , $control_methodology);

    print "base_list_controlling_percent $base_list_controlling_percent\n";

    print "asn  $asns->[0]\n";

    my $max = $asns->[0];
    my $max_c = $self->_get_percent_controlled_by_list( [ @$ninty_percent_list, $max] , $control_methodology);
    print "max_c  $max_c\n";

    $asn_monitor_percent_increase_mappings->{ $asns->[0] } = $max_c - $base_list_controlling_percent;

    my $total_ips = $self->_get_total_ips();

    for (my $i = 1; $i < scalar(@$asns); $i++)
    {
        # print "i: $i \n";
	# print "asn: " . $asns->[$i] . "\n";

	if ( ! defined ($asn_monitor_percent_increase_mappings->{ $asns->[$i] } ) )
	{
	   $asn_monitor_percent_increase_mappings->{ $asns->[$i] } =  $self->_get_percent_controlled_by_list( [ $asns->[$i]] , $control_methodology);
	}

        my $possible_c = $asn_monitor_percent_increase_mappings->{ $asns->[$i] } + $base_list_controlling_percent;

	# print "possible_c: $possible_c\n";

        next if ($possible_c < $max_c);

        my $c = $self->_get_percent_controlled_by_list( [ @$ninty_percent_list, $asns->[$i]] , $control_methodology);

	# print "c: $c\n";

	$asn_monitor_percent_increase_mappings->{ $asns->[$i] } = $c - $base_list_controlling_percent;

        if ($c > $max_c)
        {
            $max = $asns->[$i];
            $max_c = $c;
        }
    }

    my $end_time = time;

    say "Ending _get_max_monitorable_increase_asn -- $end_time";
    
    say "Total time _get_max_monitorable_increase_asn " . ($end_time-$start_time);

    return $max;    
}


sub _hash_value_compare
{
    my ($a, $b, $hash) = @_;
 
    my $ret =
        ($hash->{$a} <=> $hash->{$b})
              or ($a <=> $b);

    return $ret;
}

sub _get_asns_controlling_ninty_percent
{
    my ($self, $control_methodology) = @_;

    my $start_time = time;
    say "Starting _get_asns_controlling_ninty_percent -- $start_time";
    my $asns = [$self->_get_asn_names_sorted_by_monitoring($control_methodology)];

    my $asn                = shift @$asns;
    my @ninty_percent_list = ($asn);

    my $asn_monitor_percent_increase_mappings = {};

    while ( $self->_get_percent_controlled_by_list( \@ninty_percent_list, $control_methodology ) < 90.0 )
    {
        die if ( scalar(@$asns) == 0 );
        #say Dumper ( $asns);
        my $asn = $self->_get_max_monitorable_increase_asn($control_methodology, \@ninty_percent_list, $asns, $asn_monitor_percent_increase_mappings );

        push @ninty_percent_list, $asn;

        $asns = [grep { $_ != $asn } @$asns];

	say "Resort -- " . time ;
	$asns = [ reverse sort { _hash_value_compare( $a, $b, $asn_monitor_percent_increase_mappings ) } @$asns ];
	say "Done resort -- " . time ;

	say Dumper ( [map { $_ . ' --- ' . $asn_monitor_percent_increase_mappings->{ $_ } }  (@$asns)[0 .. 10] ] );
        #print " while (\n";
    }

    my $end_time = time;

    say "Ending _get_asns_controlling_ninty_percent -- $end_time";
    
    say "Total time  _get_asns_controlling_ninty_percent " . ($end_time-$start_time);
    return \@ninty_percent_list;
}

#Return the top 50 Asns
sub _get_top_country_asns
{
    my ($self) = @_;
    my $asns = $self->{asn_nodes};

    $self->die_if_cyclic();

    my @asn_keys = $self->_get_asn_names_sorted_by_monitoring(MONITORABLE_CALCULATION_PROPORTIONAL);

    keys(%$asns);
    if ( scalar(@asn_keys) > 50 )
    {
        @asn_keys = @asn_keys[ 0 .. 49 ];
    }

    return \@asn_keys;
}

sub print_connections_per_asn
{
    my ($self) = @_;

    my $asns = $self->{asn_nodes};

    my $total_ips = $self->_get_total_ips();

    die "Could not get total ips" unless defined($total_ips);
    print "ASN graph has $total_ips total ips\n";

    $self->die_if_cyclic();

    my @asn_keys = @{ $self->_get_top_country_asns };

    unshift @asn_keys, AS::get_rest_of_the_world_name();

    foreach my $key (@asn_keys)
    {
        my $asn_info = $asns->{$key}->get_statistics();

        #my $asn_name = (AsnUtils::get_asn_whois_info($key))->{name};
        #my $asn_name = ( AsnTaxonomyClass::get_asn_organization_description($key) );
        print
"Total downstream connections for AS$asn_info->{asn} ($asn_info->{organization_name}): $asn_info->{total_connections}\n";

        #if ( $key ne  AS::get_rest_of_the_world_name() )
        {

            print "\tDirect IPs for AS$key: " . $asn_info->{direct_ips} . "\n";
            print "\tDownstream IPs for AS$key: " . $asn_info->{downstream_ips} . "\n";
            print "\tMonitorable IPs for AS$key: " . $asn_info->{effective_monitorable_ips} . "\n";
            print "\tPercent of all total IPs monitorable: "
              . $asn_info->{effective_monitorable_ips} / $total_ips * 100.0 . "\n";
            print "\n";
        }

        foreach my $field (qw (customer peer provider sibling))
        {
            if ( defined( $asns->{$key}->{$field} ) )
            {
                print "\t\t $field: "
                  . (
                    join ", ",
                    map { $_->get_as_number() . " (" . $_->get_statistics->{organization_name} . ") " }
                      @{ $asns->{$key}->{$field} }
                  ) . "\n";
            }
        }
    }
}

sub get_complexity_impl
{
    my ( $self, $sum_monitorable_ips ) = @_;

    #exclude rest_of_world node
    my $asns       = $self->{asn_nodes};
    my $total_isps = scalar( keys %{$asns} ) - 1;

    my $total_ips = $self->_get_total_ips();

    my $ret = $total_isps * $sum_monitorable_ips / $total_ips;

    $ret = $ret / ($total_ips);

    #scale the results.
    $ret *= 100000;
    return $ret;
}

sub get_complexity
{
    my ($self) = @_;

    my $asns = $self->{asn_nodes};

    my $sum_monitorable_ips = sum map { $_->get_effective_monitorable_ip_address_count() } values %{$asns};

    return $self->get_complexity_impl($sum_monitorable_ips);
}

sub get_complexity_max
{
    my ($self) = @_;

    my $asns = $self->{asn_nodes};

    my $sum_monitorable_ips = sum map { $_->get_monitorable_ip_address_count() } values %{$asns};

    return $self->get_complexity_impl($sum_monitorable_ips);
}

sub get_complexity_min
{
    my ($self) = @_;

    my $asns = $self->{asn_nodes};

    my $sum_monitorable_ips = sum map { $_->get_min_complexity_monitorable_ip_address_count() } values %{$asns};

    return $self->get_complexity_impl($sum_monitorable_ips);
}

sub _list_contains
{
    ( my $value, my $list ) = @_;

    return any { $_ eq $value } @{$list};
}

sub get_point_of_control_as_numbers
{
    my ($self) = @_;

    return [ @{ $self->_get_asns_controlling_ninty_percent(MONITORABLE_CALCULATION_PROPORTIONAL) } ];
}

sub _get_ninety_percent_control_list_element
{
    my ($self, $element_name, $control_methodology ) = @_;

    my $ninety_percent_control_asns = $self->_get_asns_controlling_ninty_percent($control_methodology );

    my $ninety_percent_list_xml = XML::LibXML::Element->new($element_name);
    
    $ninety_percent_list_xml->setAttribute( 'count', scalar( @{$ninety_percent_control_asns} ) );
    
    $ninety_percent_list_xml->appendText( join ", ", @{$ninety_percent_control_asns} );

    return $ninety_percent_list_xml;
}

my $direct_info_only = 0;

sub xml_summary
{
    my ($self) = @_;

    my $xml_graph = XML::LibXML::Element->new('summary');

    my $asns = $self->{asn_nodes};

    my $total_ips = $self->_get_total_ips();

    die "Could not get total ips" unless defined($total_ips);

    my $ninety_percent_control_asns = [];

    unless ($direct_info_only) 
    {
      $self->die_if_cyclic();

    $xml_graph->appendTextChild( 'total_ips',      $total_ips );
    $xml_graph->appendTextChild( 'total_asns',     $self->get_country_as_nodes_count() );
    $xml_graph->appendTextChild( 'complexity',     $self->get_complexity );
    #$xml_graph->appendTextChild( 'complexity_max', $self->get_complexity_max );
    #$xml_graph->appendTextChild( 'complexity_min', $self->get_complexity_min );

    #my $ninety_percent_list_xml = $self->_get_ninety_percent_control_list_element('ninty_percent_asns', MONITORABLE_CALCULATION_PROPORTIONAL);


    print "XML_summary Starting _get_asns_controlling_ninty_percent\n";
    unless  ($direct_info_only)
      {
    $ninety_percent_control_asns = $self->_get_asns_controlling_ninty_percent(MONITORABLE_CALCULATION_PROPORTIONAL );
     }
    print "XML_summary finished _get_asns_controlling_ninty_percent\n";

    my $ninety_percent_list_xml = XML::LibXML::Element->new('ninty_percent_asns');
    
    $ninety_percent_list_xml->setAttribute( 'count', scalar( @{$ninety_percent_control_asns} ) );
    
    $ninety_percent_list_xml->appendText( join ", ", @{$ninety_percent_control_asns} );

    $xml_graph->appendChild($ninety_percent_list_xml);

    #my $max_ninety_percent_list_xml = $self->_get_ninety_percent_control_list_element('max_ninty_percent_asns', MONITORABLE_CALCULATION_MAXIMAL);
    #$xml_graph->appendChild($max_ninety_percent_list_xml);

    #my $min_ninety_percent_list_xml = $self->_get_ninety_percent_control_list_element('min_ninty_percent_asns', MONITORABLE_CALCULATION_BIGESTPARENT);
    #$xml_graph->appendChild($min_ninety_percent_list_xml);
    }

    my @asn_keys = keys %{$asns};

    unless ($direct_info_only)
      {
    @asn_keys = $self->_get_asn_names_sorted_by_monitoring(MONITORABLE_CALCULATION_PROPORTIONAL);
    }


    foreach my $key (@asn_keys)
    {

        my $asn_xml = $self->get_as_node_xml( $key, $ninety_percent_control_asns, $total_ips );
        $xml_graph->appendChild($asn_xml);
    }

    #now add the rest_of_the_world_node:
    my $rest_of_world_xml =
      $self->get_as_node_xml( AS::get_rest_of_the_world_name(), $ninety_percent_control_asns, $total_ips );
    $xml_graph->appendChild($rest_of_world_xml);

    return $xml_graph;
}

sub get_as_node_xml
{
    my ( $self, $asn, $ninety_percent_control_asns, $total_ips ) = @_;
    my $asns     = $self->{asn_nodes};
    my $asn_info = $asns->{$asn}->get_statistics();

    my $asn_xml = XML::LibXML::Element->new('as');

    foreach my $attrib_key ( sort keys %{$asn_info} )
    {
        $asn_xml->appendTextChild( $attrib_key, $asn_info->{$attrib_key} );
    }

    my $is_point_of_countrol = _list_contains( $asn, $ninety_percent_control_asns );

    $asn_xml->setAttribute( 'point_of_control', $is_point_of_countrol );
 
    unless ($direct_info_only)
      {
    $asn_xml->appendTextChild( 'percent_monitorable', $asn_info->{effective_monitorable_ips} / $total_ips * 100.0 );
    }

    $asn_xml->appendTextChild( 'percent_direct_ips',  $asn_info->{direct_ips} / $total_ips * 100.0 );

    return $asn_xml;
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
        return $self->get_as_node( AS::get_rest_of_the_world_name() );
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

	    if ($new_asn->is_rest_of_world() )
            {
	        $new_asn->{$relationship_type} = [ grep { ! $_->is_rest_of_world } @{ $new_asn->{$relationship_type} } ];
	    }

	    #die "AS cannot be its own $relationship_type " if any {$_ == $new_asn}  @{ $new_asn->{$relationship_type} } ;
 
# $new_asn->{$relationship_type} = [ grep {$_->get_as_number  ne AS::get_rest_of_the_world_name()}   @{ $new_asn->{$relationship_type} } ];
        }
    }

    return $ret;
}

1;
