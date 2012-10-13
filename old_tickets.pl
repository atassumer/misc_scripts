#!/usr/bin/env perl

# Sends in an email all tickets that need update

use strict;
use MIME::Lite;
my $email = '';
my $email2 = '';


my $SQL = "select evento.idevento as ticket,evento.descripcion,empresa.nombre as cliente,areaconocimiento.nombre as area
        from evento, empresa,areaconocimiento 
        where empresa.idempresa=evento.idempresa 
                and evento.modificacion < now()::timestamp - interval '14 days' 
                and evento.idestadoev != 40 
                and evento.idarea!= 45 
                and areaconocimiento.habilitada = 1 
                and areaconocimiento.idarea=evento.idarea 
        order by empresa.nombre;";

my $comando = 'echo "\H \\\\\\ '. $SQL .'" | PGUSER=postgres psql -q -d XXXX';

my $TABLA = `$comando`;

$TABLA = '<html><head><title></title></head><body><div></div>' . $TABLA . '</body></html>';

my $msg = MIME::Lite->new
(
Subject => "XXX",
From    => 'XXXX',
To      => $email,
Cc      => $email2,
Type    => 'text/html',
Encoding => '8bit',
Data    => $TABLA
);
$msg->send();
