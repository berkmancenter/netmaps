#!/usr/bin/perl

#USAGE: This is a simple script to generate random IP address
#input: None
#output: 10,000 random ips addresses. Notes: We use the same initial seed so the IP list will be the same for each run.  (We consider this a feature not a bug.)  Also we do not generate IP in the range  240.X.X.X through 255.X.X.X since that is reserved for future use and not routable.  Currently we do generate IPs in the multicast range multicast: 224.X.X.X through 239.X.X.X. 

srand(12345);

for ( 1 .. 10000 )
{

    # 240.X.X.X through 255.X.X.X are reserved for future use
    #perhaps we should also avoid multicast 224.X.X.X through 239.X.X.X

    print join( '.', ( int( rand(239) ), int( rand(255) ), int( rand(255) ), int( rand(255) ) ) ), "\n";
}
