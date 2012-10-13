#!/usr/bin/env perl

# Receives PerfMon counters and prints the munin snippet to add

use String::CamelCase qw(camelize decamelize wordsplit);

use Text::Trim;

sub superCamel {
        $cadena = $_[0];
        $cadena =~ s/[^a-zA-Z]//g;

        camelize ( $cadena );

        return $cadena;
}

sub PerfMunin {
#( $objeto, $contador ) {
$objeto =  $_[0];
$contador = $_[1];

# Objeto 1: Memory: Pages/sec
# Objeto 2: Memory: Availability Mb
# Objeto 3: Sql Server: Locks: Avg. wait time (ms)
# Objeto 4: Sql Server: Backup Device: Device Throughput bytes/sec

# El objeto es lo que esta antes de los : finales
# El contador retocado es in /sec o (ms) y quitar espacios con CamelCase
# El objecto retocado es el objecto y quitar espacios con CamelCase

@vector = split(':', $objeto);
$objeto_retocado = superCamel ( shift(@vector) );

$contador_retocado = superCamel ( $contador );

print('[PerfCounterPlugin_' . $objeto_retocado . $contador_retocado . ']
DropTotal=1
Object='. $objeto . '
Counter=' . $contador . '
CounterFormat=double
CounterMultiply=1.000000
GraphTitle=' . $contador . '
GraphCategory=' . $objeto_retocado  . '
GraphArgs=--base 1000 -l 0
GraphDraw=LINE

');

}

open(my $fh, '<', "monitores.txt") or die $!;

while ( <$fh> ) { 

    $buffer = trim ( $_ );
    @vector = split(':', $buffer);
    
    $contador = trim( pop(@vector) );

    $objeto = "";

    for ($i=0; $i< scalar(@vector); $i++) {
        @vector[$i] = trim( @vector[$i] );
    }
    
    $objeto = join(':', @vector );

    PerfMunin($objeto , $contador );
}
