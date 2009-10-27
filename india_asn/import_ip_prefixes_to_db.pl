#!/usr/bin/perl

use strict;
use warnings;
use DBI;
use strict;
use Class::CSV;
use DBIx::Simple;
use Data::Dumper;
use Locale::Country qw(country2code);
use IO::Uncompress::Gunzip qw(gunzip $GunzipError);
use Perl6::Say;
use Net::CIDR ':all';
use Carp qw(confess);
use List::Util qw(sum);
use Math::Round qw (round);
use Net::CIDR::Lite;
use Net::ASN;

use NetAddr::IP qw(
  Compact
  Coalesce
  Zeros
  Ones
  V4mask
  V4net
  netlimit
);

package IP_Prefix;

use Moose;

has 'asn_list' => (
    is       => 'rw',
    required => 1
);
has 'start_ip' => ( is => 'rw', required => 1 );
has 'end_ip'   => ( is => 'rw', required => 1 );

sub get_end_point
{
    my $self = shift;

    return $self->{end_point} if ( defined( $self->{end_point} ) );

    $self->{end_point} = IP_Prefix_End_Boundary->new( ip_prefix => $self, ip => $self->end_ip );
    return $self->{end_point};
}

sub get_start_point
{
    my $self = shift;

    return $self->{start_point} if ( defined( $self->{start_point} ) );

    $self->{start_point} = IP_Prefix_Start_Boundary->new( ip_prefix => $self, ip => $self->start_ip );
    return $self->{start_point};
}

sub ip_count
{
    my $self = shift;
    return $self->end_ip - $self->start_ip + 1;
}

sub summary
{
    my $self = shift;

    return $self->start_ip . ' - ' . $self->end_ip . ' : ' . $self->asn_list;
}

package IP_Prefix_Boundary;
use Perl6::Say;
use Moose;
use MooseX::ABC;

has 'ip_prefix' => (
    isa      => 'IP_Prefix',
    is       => 'rw',
    required => 1
);
has 'ip' => ( is => 'rw', required => 1 );

requires('is_start_point');

sub is_end_point
{
    my $self = shift;
    return !$self->is_start_point;
}

#sort by ip and then by prefix size.
sub cmp
{
    my $self  = shift;
    my $other = shift;

    my $ip_cmp = $self->ip <=> $other->ip;

    return $ip_cmp if $ip_cmp != 0;

    if ($self->is_start_point != $other->is_start_point)
    {

        #The same ip will be both a start and end boundary is 
        # when a single block has length 1
        if ($self->ip_prefix == $other->ip_prefix)
        {
            die unless $self->ip_prefix->ip_count == 1;
            
            if ($self->is_start_point)
            {
                return -1;
            }
            else
            {
                return 1;
            }
        }
        # one of the blocks may be only a single 1
        elsif ($self->ip_prefix->ip_count == 1 || $other->ip_prefix->ip_count == 1)
        {
            die if ($self->ip_prefix->ip_count == 1) && ($other->ip_prefix->ip_count == 1);

            if ($self->ip_prefix->ip_count == 1)
            {
                return -1;
            }
            else
            {
                return 1;
            }
        }
        else
        {
            say "start point and end point with the same IP";
            say $self->summary;
            say $other->summary;
            die;
        }
    }

    #TODO  end points before start -- is this necessary

    if ($self->is_start_point)
    {
        #Larger prefixes first
        my $ip_count_cmp = $other->ip_prefix->ip_count <=> $self->ip_prefix->ip_count;
        return $ip_count_cmp;
    }
    else
    {
        die unless $self->is_end_point;
        #Larger prefixes last
        my $ip_count_cmp = $self->ip_prefix->ip_count <=> $other->ip_prefix->ip_count;
        return $ip_count_cmp;
        
    }
}

sub summary
{
    my $self = shift;
    return $self->ip . ' ' . $self->is_start_point . ' ' 
        . ' (' . $self->ip_prefix . ') ' . $self->ip_prefix->summary;
}

package IP_Prefix_Start_Boundary;
use Moose;

extends 'IP_Prefix_Boundary';

sub is_start_point
{
    return !0;
}

package IP_Prefix_End_Boundary;
use Moose;

extends 'IP_Prefix_Boundary';

sub is_start_point
{
    return 0;
}

package main;

sub list_find_element_index
{
    my ( $start_indx, $element, $list ) = @_;

    my $ret = $start_indx;
    while ( $list->[$ret] != $element )
    {
        $ret++;
        if ( $ret > scalar(@$list) )
        {
            say "Element not in list";
            say "Start index $start_indx";
            say $element->summary;
            say $element->ip_prefix;
            say Dumper($element);
            confess();
        }
    }

    return $ret;
}

sub _read_ip_prefix_to_asn_file
{
    my ($ip_prefix_to_asn_file) = @_;
    print "reading ip _prefix  file\n";

    my $z = new IO::Uncompress::Gunzip $ip_prefix_to_asn_file
      or die "IO::Uncompress::Gunzip failed: $GunzipError\n";

    say "unziped file";

    my $csv = Class::CSV->parse(
        filehandle     => $z,
        fields         => [qw /ip ip_prefix_length asn /],
        csv_xs_options => { binary => 1, sep_char => "\t" }
    );

    print "parsed unzipped ip _prefix file\n";

    my $lines_read = 0;

    my $prefix_boundaries = [];

    my @merged_cidr_list;

    my $cidr = Net::CIDR::Lite->new;

    for my $line ( @{ $csv->lines } )
    {
        $lines_read++;

        my $asn_list_string = $line->asn;

        if ($asn_list_string !~ /^[0-9_,.]*$/ )
        {
            warn "invalid asn_list_string: '$asn_list_string' "; 
            die "invalid asn_list_string: '$asn_list_string' " ;
            next;
        }

        my $num_ips = 2**( 32 - $line->ip_prefix_length );


        my $cidr_string = $line->ip . '/' . $line->ip_prefix_length;
        ( my $ip_range ) = Net::CIDR::cidr2range( $cidr_string );

        $cidr->add($cidr_string);

        ( my $ip_1, my $ip_2 ) = split '-', $ip_range;

        my $start_ip = new NetAddr::IP::Lite $ip_1;
        my $end_ip   = new NetAddr::IP::Lite $ip_2;


        #die "invalid asn_list_string: '$asn_list_string' " unless $asn_list_string =~ /^[0-9_,]*$/;


        my $prefix = IP_Prefix->new( asn_list => $line->asn, start_ip => $start_ip, end_ip => $end_ip );

        my $end_prefix   = $prefix->get_end_point;
        my $start_prefix = $prefix->get_start_point;

        push @{$prefix_boundaries}, $start_prefix, $end_prefix;

        say "Read $lines_read lines" if ($lines_read % 1000) == 0;
    }

    say "Done reading file";
    say "sorting";
    $prefix_boundaries = [ sort { $a->cmp($b) } @{$prefix_boundaries} ];

    say "done sorting";

    my $index = 0;
    #print Dumper( [map { $index++ . ' ' . $_->summary } @{$prefix_boundaries} ] );


    my $total_allocated_ips = 0;
    my $total_effective_ips = 0;  
    my $total_chunk_out = 0;

    my $effective_ips_for_asn_list = {};

    for ( my $i = 0 ; $i < scalar( @{$prefix_boundaries} ) ; $i++ )
    {
        my $current_prefix_boundary = $prefix_boundaries->[$i];

        say "i = $i" if ($i%1000 == 0 );

        next if $current_prefix_boundary->is_end_point;

        #say "Current prefix_boundary : " . $current_prefix_boundary->summary;

        my $current_prefix = $current_prefix_boundary->ip_prefix;

        my $chunk_out_size = 0;

        my $current_prefix_end_idx = list_find_element_index( $i + 1, $current_prefix->get_end_point, $prefix_boundaries );

        my $j = $i + 1;
        while ( $j < $current_prefix_end_idx )
        {
            #say "j : $j";
            my $chunk_out_prefix_boundary = $prefix_boundaries->[$j];

            confess() if $chunk_out_prefix_boundary->is_end_point;

            my $chunk_out_prefix = $prefix_boundaries->[$j]->ip_prefix;
            my $chunk_out_prefix_end_index =
              list_find_element_index( $j + 1, $chunk_out_prefix->get_end_point, $prefix_boundaries );
            #say "found end point at:  $chunk_out_prefix_end_index";
            $j = $chunk_out_prefix_end_index;
            $j++;
            $chunk_out_size += $chunk_out_prefix->ip_count;
        }

        #say $current_prefix_boundary->ip . ' ' . $current_prefix->asn_list . ' ' .  $current_prefix;
        #say "\tAllocated size " . $current_prefix->ip_count;
        $total_allocated_ips += $current_prefix->ip_count;
        #say "\tChunkout size $chunk_out_size";
        $total_chunk_out += $chunk_out_size;
        #say "\tEffective size: " . ( $current_prefix->ip_count - $chunk_out_size );

        my $effective_ips = ( $current_prefix->ip_count - $chunk_out_size );
        $total_effective_ips += $effective_ips;

        $effective_ips_for_asn_list->{$current_prefix_boundary->ip_prefix->asn_list} ||= 0;
        $effective_ips_for_asn_list->{$current_prefix_boundary->ip_prefix->asn_list} += $effective_ips;

    }

    say "CIDR merge results";
    #say Dumper ($cidr->list);
    my @prefixes_list = map { (split /\//, $_)[1] } $cidr->list;
    #say 'prefixes_list : ' . Dumper( @prefixes_list);
    my @ip_counts = map { 2 ** (32 - $_ ) } @prefixes_list;
    #say Dumper(@ip_counts);
    my $sum = sum(@ip_counts);

#     say Dumper (@merged_cidr_list);
#     my @prefixes_list = map { (split /\//, $_)[1] } @merged_cidr_list;
#     say 'prefixes_list : ' . Dumper( @prefixes_list);
#     my @ip_counts = map { 2 ** (32 - $_ ) } @prefixes_list;
#     say Dumper(@ip_counts);
     my $cidr_sum = sum(@ip_counts);

  
    say "CIDR sum is $cidr_sum";

    say "Total Allocated IPs $total_allocated_ips";
    say "Total Chunkout size $total_chunk_out";
    say "Toal effective Ips $total_effective_ips";
    say "Total Allocated IPs-Total Chunkout size = " . ($total_allocated_ips - $total_chunk_out);

    die "Effective IPs != allocated ips - chunked out ips " unless $total_effective_ips == ($total_allocated_ips - $total_chunk_out);

    die "Net::Cidr::Lite ip count doesn't match our effective ip count " unless $total_effective_ips == $cidr_sum;

    #say Dumper (sort keys %{$effective_ips_for_asn_list} );

    say "Calculating asn level allocation";

    my $asn_ip_allocation = {};
    foreach my $asn_list (sort keys %{$effective_ips_for_asn_list} )
    {
        my @asns = split( "_", $asn_list );
        @asns = map { split( ",", $_ ) } @asns;

        my $effective_ips = $effective_ips_for_asn_list->{$asn_list};
        my $asn_count = scalar(@asns);
        my $ips_per_asn = $effective_ips/$asn_count;
        foreach my $asn_string (@asns) 
        {
            my $asn = Net::ASN->new($asn_string) || die;

            die "Invalid asn: '$asn' from '$asn_list'" if $asn->toasplain ne int($asn->toasplain);
            $asn_ip_allocation->{$asn->toasplain} ||= 0;
            $asn_ip_allocation->{$asn->toasplain} += $ips_per_asn;
        }
    }

    say "Done calculating asn level allocation";

    {
        my $asn_ip_allocation_hash_sum = sum values %{$asn_ip_allocation};
        die "asn_ip_allocation_hash_sum ($asn_ip_allocation_hash_sum) != total_effective_ips ($total_effective_ips)" unless $asn_ip_allocation_hash_sum eq $total_effective_ips;
    }

    return $asn_ip_allocation;
}

sub get_asn_counts_from_ip_prefix_file
{
    my ($ip_prefix_to_asn_file) = @_;
    my $ret = _read_ip_prefix_to_asn_file($ip_prefix_to_asn_file);
}

sub main
{
    my $dbargs = {
        AutoCommit => 1,
        RaiseError => 1,
        PrintError => 1,
    };

    print "Starting\n";
    my $asn_counts = get_asn_counts_from_ip_prefix_file('downloaded_data/newest_prefix2as_file.txt');

    #my $asn_counts = get_asn_counts_from_ip_prefix_file('route_views_small.txt.gz');

    say "Got asn_counts hash";

    my $dbh = DBIx::Simple->connect( DBI->connect( "dbi:SQLite:dbname=db/asn_ip_counts.db", "", "", $dbargs ) );

    say "Got db handle";

    say "Clearing DB table";

    $dbh->query(' DELETE FROM asn_ip_counts' );

    say "Inserting into asn_ip_counts";

    my $rows_inserted = 0;
    foreach my $asn ( sort keys %$asn_counts)
    {
        $dbh->query( 'insert into asn_ip_counts (asn, ip_count) values (?, ? ) ', $asn, round($asn_counts->{$asn}) );
        $rows_inserted++;

        say "$rows_inserted rows inserted" if ($rows_inserted % 500) == 0;
    }

    say "Done inserting into table asn_ip_counts";

    $dbh->commit();
    $dbh->disconnect();

}

main();
