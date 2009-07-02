CREATE TABLE asn_ip_counts ( 
       asn interger primary key not null, 
       ip_count integer not null
       );

CREATE UNIQUE INDEX asn_index ON asn_ip_counts(asn);