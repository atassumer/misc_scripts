#!/usr/bin/env perl

# EMAS ticket search
#
# Prints the ID for a Mail Subject
# Returns the number of matching tickets

use strict;
use warnings;
use DBI;

my $eventos = 0;

if ( $#ARGV != 0 ) {
        print("\nUsage: obtener_id.pl STRING\n");
        exit -1;
}

my $asunto = $ARGV[0];

$asunto =~ s/^((Re|Rv|Fwd|Fw):\s*)+//ig;

my $dbh = DBI->connect("DBI:Pg:dbname=emas;host=localhost", "emas", "", {'RaiseError' => 1});

my $sth = $dbh->prepare("select evento.idevento
        from evento
        where evento.descripcion = '" . $asunto . "'
                and evento.idestadoev != 40");

$sth->execute();

while(my $ref = $sth->fetchrow_hashref()) {
    print "$ref->{'idevento'}";
    $eventos++;
}

$dbh->disconnect();

exit $eventos;
