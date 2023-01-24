#!/usr/bin/env perl

use Cwd qw(abs_path);

sub BEGIN {
	my @partes = split /\//, abs_path($0);
	pop(@partes);
	push @INC, join('/', @partes);
}

use strict;
use Comando;
use Debug;
use Demonio;
use ConfiguracionDinapiIp;
use Proceso;
use Getopt::Std;
use IO::Handle;
#use Term::ReadKey;

my $CREDENCIALES_INICIADAS = undef;


unless($> == 0){
	print "Necesitas ser root para correr dinaIp\n";
	exit(1);
}

my %opciones;

getopts('isfdhla:b:u:p:', \%opciones);

unless(keys(%opciones)){
	&ayuda();
}

if(exists($opciones{f})){
        &Debug::setPrimerPlano(1);
}

# autentificamos primero si nos pasan usuario
if(exists($opciones{u})){
	if(exists($opciones{p})){
		&autentificar($opciones{u}, $opciones{p});
	}
	else{
		&autentificar(&pedirCredenciales($opciones{u}));
	}
}

if(exists($opciones{i})){
	if(&Demonio::demonioCorriendo){
		print "Dinaip ya estaba iniciada\n";
		exit 1;
	}
	else{
		&iniciar();
	}
}

if(exists($opciones{s})){
	&mostrarStatus();
}

if(exists($opciones{d})){
	&detenerDemonio();
}

if(exists($opciones{a})){
	&agregarZona($opciones{a});
}

if(exists($opciones{b})){
	&eliminarZona($opciones{b});
}

if(exists($opciones{h})){
	&ayuda();
}

if(exists($opciones{l})){
	&listarDominios(1);
}



unless(&Demonio::demonioCorriendo){
	&iniciar();
}

sub iniciar{

	&autentificar(&pedirCredenciales()) unless($CREDENCIALES_INICIADAS);
	
	my $configuracion = &ConfiguracionDinapiIp::recuperar;

	&Demonio::iniciar(sub {
		&Proceso::run(@_);
	}, $configuracion->frecuencia, exists($opciones{f}));
}

sub pedirCredenciales{

	my $usuario = $_[0];
	my $password;

	unless($usuario){
		print "Introduza su usuario de dinahosting: ";
		chomp($usuario = <STDIN>);


	}

	#ReadMode('noecho');
	system('stty -echo');
	print "Introduzca su password: ";
	chomp($password = <STDIN>);
	print "\n";
        system('stty echo');

	#ReadMode(0);

	return ($usuario, $password);
}

sub autentificar{
	my $usuario = $_[0];
	my $password = $_[1];

	my $configuracion = &ConfiguracionDinapiIp::recuperar;

	if(my $cuenta = $configuracion->cuenta){

		if($cuenta ne $usuario){
			
			print "La ultima vez, dinaip se inicio con otra cuenta de usuario. \n".
				"Si continua se borraran las preferencia de la sesion anterior. \n".
				"Continuar?(S/n): ";

			system('stty raw');
			flush STDIN;
			my $continuar = getc(STDIN);
			system('stty -raw');
			print "\n";

			if($continuar =~ /n|N/){
				exit 0;
			}

			$configuracion = &ConfiguracionDinapiIp::reset;

			$configuracion->cuenta($usuario)->almacenar;

		}	
	}
	else{
		$configuracion->cuenta($usuario)->almacenar;
	}

	&Proceso::setCredenciales($usuario, $password);

	&Proceso::validarCredenciales;

	$CREDENCIALES_INICIADAS = 1;

}

sub ayuda{

	print $_ foreach(<DATA>);
	exit(0);

}

sub mostrarStatus{

	my $corriendo =  (&Demonio::demonioCorriendo) ? '[si]' : '[no]'; 

	my $configuracion = ConfiguracionDinapiIp::recuperar;

	print "\ndinaip corriendo... $corriendo\n\n";

	if($configuracion->cuenta){
		print "Cuenta en dinahosting: " . $configuracion->cuenta . "\n";
	}

	print "Listado de zonas monitorizadas:\n";
	

	my $monitorizadas = undef;
	foreach my $dominio ($configuracion->getDominiosVigilar){

		print "\t- " . $dominio . ' : ' . 
			join(',', @{$configuracion->getZonasVigilar($dominio)}) . "\n";

		$monitorizadas = 1;
	}


	unless($monitorizadas){
		print "Sin zonas a monitorizar!!\n";
	}

	exit(0);
}

sub detenerDemonio{

	if(&Demonio::demonioCorriendo){

		&Demonio::demonioDetener;

		exit(0);
	}
	else{
		print "dinaip ya estaba detenido\n";
		exit(1);
	}

}

sub listarDominios{
	my $por_pantalla = $_[0] || undef;

	my $lista;

	if(&Demonio::demonioCorriendo){

		$lista = &enviarComandoDemonio(ComandoListarDominios->new);	
	}
	else{
	
		&autentificar(&pedirCredenciales()) unless($CREDENCIALES_INICIADAS);

		$lista = &Proceso::getListadDominios;

	}

	if($lista){
		
		if(ref($lista) eq 'ARRAY' || $lista->{com} eq 'LISTA_DOMINIOS'){

			if($por_pantalla){

				print "Listado de dominios en la cuenta del usuario:\n";

				my @mostrar = (ref($lista) eq 'ARRAY') ? @$lista : @{$lista->{args}->[0]};

				foreach(@mostrar){

					print "\t$_\n";	

				}
			}
			else{
				return (ref($lista) eq 'ARRAY') ? $lista : $lista->{args}->[0];
			}

		}
		else{
			print "Se ha producido un error en el listado de los dominios del usuario: " . $lista->{args}->[0] . "\n";
			exit(1);
		}
	}

	exit(0);
	
}

sub enviarComandoDemonio{
	my $comando = $_[0];

	unless(&Demonio::demonioCorriendo){
		&iniciar();
	}

	$comando->almacenar;

	&Demonio::demonioComando;

	return &Comando::esperarRespuesta(5);
}

sub agregarZona{
	my $zonas = $_[0];
	
	unless($zonas && $zonas =~ /:/){
		print "Uso: dinaip -a dominio:zona1,zona2[...]\n";
		exit(1);
	}

	my ($dominio, $zonas_vigilar) = split(/\:/, $zonas); 

	&validarDominio($dominio);	

	my @zonas_vigilar = split(/\,/, $zonas_vigilar);

	my $configuracion = ConfiguracionDinapiIp::recuperar;

	$configuracion->setZonaVigilar($dominio, $_) foreach(@zonas_vigilar);

	$configuracion->almacenar;

	&Demonio::demonioRecargar if(&Demonio::demonioCorriendo);

}

sub validarDominio{
	my $dominio = $_[0];

	my $lista = &listarDominios();

	unless(scalar(grep {$dominio eq $_ } @$lista)){
		print "Error. El dominio " . $dominio . " no parece estar en la lista de servicios del usuario\n";
		exit 1;
	}

}

sub eliminarZona{
	my $zonas = $_[0];
	
	unless($zonas){
		print "Uso: dinaip -b dominio:[zona1,zona2[...]]\n";
		exit(1);
	}


	my $configuracion = ConfiguracionDinapiIp::recuperar;
	
	my @dominios_vigilados = $configuracion->getDominiosVigilar();

	unless(scalar(@dominios_vigilados) > 0 ){
		print "Error. Dinaip no tiene ningun dominio configurado para vigilar\n";
		exit (2);
	}

	if($zonas =~ /\:/){

		my ($dominio, $zonas_eliminar) = split(/\:/, $zonas);

		my @zonas_eliminar = split(/\,/, $zonas_eliminar);	

		unless($dominio && scalar(@zonas_eliminar)){
			print "Uso: dinaip -b dominio:[zona1,zona2[...]]\n";
		}

		foreach my $zona (@zonas_eliminar){

			if($configuracion->existeZonaAVigilar($dominio, $zona)){
				$configuracion->eliminarZonaAVigilar($dominio, $zona);
			}
			else{
				print "Aviso La zona $zona no se estaba vigilando\n";
			}

		}
	}
	else{
		unless ($zonas  ~~ @dominios_vigilados){
			print "Error. El dominio $zonas no esta siendo vigilado\n";
			exit(1);
		}
	
		$configuracion->eliminarDominioAVigilar($zonas);
	}

	$configuracion->almacenar;

	&Demonio::demonioRecargar if(&Demonio::demonioCorriendo);

	exit(0);
}

1;


__DATA__

DinaIP - gestión de zonas DNS desde shell

Uso: dinaip [OPCIONES] ... 

-u	Usuario en dinahosting
-p	Contraseña del usuario de dinahosting
-i 	Arranca el demonio de dinaip con la configuracion almacenada
-a	Agrega una zona a monitorizar. Sintaxis: dominio:zona1,zona2...
-l	Muestra una lista de los dominios pertenecientes a esta cuenta
-b	Elimina una zona de la monitorización. Sintaxis: dominio:zona_a_eliminar
-d	Detiene el demonio de DinaIP
-f      Arranca el demonio de DinaIP en primer plano y enva logs al terminal
-h	Despliega esta ayuda
-s	Muestra el status del demonio de DinaIP. 


