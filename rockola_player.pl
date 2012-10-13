#!/usr/bin/env perl

use warnings;
use strict;
use WWW::Mechanize;
use Storable;
use XML::Simple;
use URI::Escape;
use Data::Dumper;
use Encode;
use IO::Prompt;
use utf8;
binmode(STDOUT, ":utf8");

my $mech = WWW::Mechanize->new(autocheck => 0);
$mech->add_header( 'User-Agent' => 'Mozilla/5.0' );

$mech->max_redirect( 0 );

$SIG{INT}=\&salir;

my $salir = 1;

sub salir {
  $salir = 0;
  print "\n caught $SIG{INT}",@_,"\n";
}

my $cont;
my $song = 0;
my $errors = 0;

my $login    = undef;
my $password = undef;
my $estacion = undef;
my $id = undef;

$login = prompt('Username:');
$password = prompt('Password:', -e => '*');


my $cancion_url="http://www.rockola.fm/openAPI.php?action=getSong";
my $emisoras_url="http://www.rockola.fm/selector/mis-emisoras";

sub login {
  my $mech = $_[0];
  my $inicio_url="http://www.rockola.fm/modal/login.php"; # Debe ser el form
  my $login_url='http://www.rockola.fm/updater.php?cmp=login&mail=' . uri_escape_utf8(${login}) . '&pass=' . uri_escape_utf8(${password}) . '&remember=false';
  $mech->get($inicio_url);
  
  print("+ Intentando login ...\n");
  $mech->get($login_url);
  
  if ( $mech->success ) {
    $cont = $mech->content ;
    my $xml = XMLin($cont);
  
    if ( $xml->{status} eq "success" ) {
      $id = $xml->{user}->{id};
      print("+ Login OK\n");
      
    } else {
      die "Fatal error $!";
    }
  } else {
    die "Fatal error $!";
  }
}

login($mech);

my $req;
my $res;

my %emisoras = ();

$mech->get( $emisoras_url );
if ( $mech->success ) {
  print("+ Obteniendo emisoras ...\n\n");
  $cont = $mech->content ;
  
  # Emisoras de usuario
   while ( $cont =~ m/{stationId: (\d+), stationName: '([^']+)', stationPage: '([^']+)'}/g ) {
     printf("%10s : %s\n", $1 ,decode("utf8", uri_unescape($2) ) );
    $emisoras{$1} = 1;
   }

  # Emisoras de Rockola
  while ( $cont =~ m/{stationType: \d+, stationId: (\d+), stationName: '([^']+)', stationPage: '([^']+)'}/g ) {
    my $id; my $nombre;
    $id = $1; $nombre=$2;
    if ( $3 =~ m{/usuario/} ) {
      $emisoras{$id} = 1;
    } else {
      $emisoras{$id} = 2;
    }
    printf("%10s : %s \n", $id, decode("utf8", uri_unescape($nombre) ) );
   }
} else {
  die "Fatal error $!";
}

print("\n");
print("+ Introduce ID de emisora : ");
$estacion =  <STDIN>;
chomp ($estacion);

my $ini_cancion_url = undef;

if ( defined($emisoras{$estacion}) && $emisoras{$estacion} == 1) { # Usuario
  $ini_cancion_url="http://www.rockola.fm/openAPI.php?action=siteUserStation&siteUserStationId=${estacion}&songOrder=";
} else { # Predefinidas
  $ini_cancion_url="http://www.rockola.fm/openAPI.php?action=siteStation&stationId=${estacion}";
}

  $mech->get( $ini_cancion_url );

if ( $mech->success ) {
  $cont = $mech->content ;
  my $xml = XMLin($cont);
  if ( $xml->{status} ne "success" ) {
    die "Fatal error $!";
  }
  print("+ Emisora: " . $xml->{list}->{name} . "\n");
} else {
  die "Fatal error $!";
}

while ( $salir ) {
  if ( $song == 0 ) {
    $req = HTTP::Request->new(GET => $cancion_url . "&stationId=${id}&pos=${song}&skip=0&format=mp4&firstSong=1" );
  } else {
    $req = HTTP::Request->new(GET => $cancion_url . "&stationId=${id}&pos=${song}&skip=0&format=mp4" );
  }

  if($res->code != 200 ) {
    print("* Publi (${song}) / codigo @{[$res->code]}\n");
    next;
  } 

  my $contenido = $res->content;

  my $xml = XMLin($contenido);

  my $valor = $xml->{status};

  if ( $valor eq "success" ) {
    print("+ Reproduciendo (" . $song . "): " . $xml->{song}->{artist}->{content} . " - " .  $xml->{song}->{title} . "\n");
    system("mplayer -really-quiet " . $xml->{song}->{audioServer} . $xml->{song}->{fileAudio} . " >/dev/null 2>/dev/null" );
  } else {
    print("* ERROR: Cancion no encontrada $!\n");
    $errors++;
    if ( $errors > 3 ) { login($mech); }
    print Dumper($xml);
  }
  
  if ( $res->code == 200 ) { # Si es publi no se incrementa
    $song++;
  }
  
  sleep(3);
}
