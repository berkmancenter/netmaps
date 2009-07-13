#!/usr/bin/perl -w

use Class::CSV;

@header = qw (AS Connections  CC  Registry Allocated Name);

my $csv = Class::CSV->new( fields => \@header );

$csv->add_line( \@header );    #hack: Class::CSV doesn't provide another way to add a header row.

#print join ";", @header;
#print "\n";

while (<>)
{
    /.*(AS.*): (.*)/;
    if ( $1 eq "ASREST_OF_WORLD" )
    {
        next;
    }

    $asn         = $1;
    $connections = $2;

    my @who_is = ` whois -h whois.cymru.com " -v $1"`;

    chomp( $who_is[1] );

    @results = split( /\s*\|\s*/, $who_is[1] );

    shift @results;

    @line = ( $asn, $connections, @results );
    $csv->add_line( \@line );

    #    print "$asn;$connections;" . join ";", @results;
    #    print "\n";
}

$csv->print;
