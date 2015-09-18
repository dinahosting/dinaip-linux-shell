package Proceso;

use strict;
use Data::Dumper;

use Comando;
use JSON::PP;
use zonas;
use Debug;
use MIME::Base64;
use ConfiguracionDinapiIp;
use LWP::Simple;
use LWP::UserAgent;


my @COMPROBADORES_IP;
my $URL_API;
my $IP_ACTUAL = undef;
my $CONFIGURACION = undef;
my $T_CONFIGURACION = undef;

sub BEGIN{

	@COMPROBADORES_IP = (

		'http://dinadns01.dinaserver.com',
		'http://dinadns02.dinaserver.com'

	);

	$URL_API = 'https://dinahosting.com/special/api.php';
}


sub run{
	my $forzar_actualizacion = $_[0];

	# actualizar configuracion
	&actualizarConfiguracion;	

	# se recoge la ip de salida
	my $ip_actual = &getIpActual;

	if($forzar_actualizacion){
		&actualizarIp($ip_actual);	
		return;
	}

	if($IP_ACTUAL){
		if($ip_actual ne $IP_ACTUAL){
			&actualizarIp($ip_actual);
		}
	}
	else{
		&actualizarIp($ip_actual);
	}


}

sub ejecutarComando{

	my $comando = &Comando::recuperar;

	if($comando->{com} == 'LISTAR_DOM'){
		ComandoListaDeDominios->new(&getListadDominios)->almacenar;
	}	

}

sub getListadDominios{
	my $respuesta = &enviarPeticion('User_GetServices', {responseType=>'json'});

	if($respuesta){

		if($respuesta->{responseCode} =~ /^1000$/){

			my @lista_dominios = map {	

				$_->{service}

			} grep {
	
				$_->{family} eq 'DOM'

			} @{$respuesta->{data}};

			return \@lista_dominios;
		}
	}

}

sub actualizarIp{
	my $ip_actual = $_[0];

	$IP_ACTUAL = $ip_actual;

	&Debug::log('Actualizando la informacion de ip');

	&Demonio::bloquear;

	# por cada uno de los dominios se cogen sus zonas y se realizan las actualizaciones
	foreach my $dominio ($CONFIGURACION->getDominiosVigilar){

		&Debug::log('Comprobando dominio ' .$dominio);

		&actualizarDominio($dominio, $CONFIGURACION->getZonasVigilar($dominio), $ip_actual);
	}
	
	&Demonio::desbloquear;

}

sub actualizarDominio{
	my $dominio = $_[0];
	my $zonas = $_[1];
	my $ip_actual = $_[2];

	my $dominio_obj = &getZonasDominio($dominio);

	return unless($dominio_obj);	

	if($dominio_obj->actualizarZonas($zonas, $ip_actual)){
		&setZonasDominio($dominio_obj);	
	}
	else{
		&Debug::log("No hay cambios que enviar al servidor");
	}
}

sub actualizarConfiguracion{

	my $t = &ConfiguracionDinapiIp::getUltimoRefresco();	

	if(!$T_CONFIGURACION || ($T_CONFIGURACION < $t)){

		&Debug::log('Actualizando configuracion');

		$CONFIGURACION = ConfiguracionDinapiIp::recuperar();

		$T_CONFIGURACION = $t;

		&Demonio::setFrecuencia($CONFIGURACION->{comprobar_cada});

	}

}

sub setCredenciales{
	my $u = $_[0];
	my $p = $_[1];

	*{getUsuario} = sub{
		return $u;
	};

	*{getPassword} = sub{
		return $p;
	};
}

sub validarCredenciales{
		
	my $respuesta = &enviarPeticion('User_GetInfo', {});

	if($respuesta){
		if($respuesta->{responseCode} =~ /2200|2201/){
			print "Credenciales incorrectas\n";
			exit(1);
		}
		else{
			if($respuesta->{responseCode} !~ /^1000$/){
				print "Error accediendo a Dinahosting. Se ha obtenido un codigo de error " . $respuesta->{responseCode};
				exit(1);
			}
		}
	}
	else{
		print "Error desconocido\n";
		exit(1);
	}
}

sub getIpActual{
	
	my $ip;

	foreach(@COMPROBADORES_IP){

		$ip = get $_;

		last if($ip);
	}

	return $ip;
}

sub setIpZona{
	my $zona = $_[0];
}

sub getZonasDominio{
	my $dominio = $_[0];

	my $respuesta = &enviarPeticion('Domain_Zone_GetAll', {domain=>$dominio, responseType=>'json'});

	if($respuesta){
		if($respuesta->{responseCode} =~ /^1000$/){
			return Dominio::cargar($dominio, $respuesta->{data});
		}
	}

	return undef;
}



sub setZonasDominio{
	my $dominio = $_[0];

	foreach my $zona (@{$dominio->{cambios}}){

		&Debug::log("Modificando zona $zona->{zona} del dominio $dominio->{dominio}");

		my $r1 = &enviarPeticion('Domain_Zone_UpdateTypeA', {domain => $dominio->{dominio},
									hostname => $zona->{zona},
									ip => $zona->{ip}},1);
	}

	foreach my $zona(@{$dominio->{nuevas_zonas}}){
		&Debug::log("Agregando nueva zona $zona->{zona}");
		my $r2 = &enviarPeticion('Domain_Zone_AddTypeA', {domain => $dominio->{dominio},
                                                                     hostname => $zona->{zona},
                                                                     ip => $zona->{ip}},1);
	}

	#my $respuesta = &enviarPeticion('Domain_Zone_SetAll', $dominio->generarParametrosParaUrl);

	#print(Dumper($respuesta));

}

sub enviarPeticion{
	my $comando = $_[0];
	my $datos = $_[1];
	my $loguear = $_[2] || undef;

	&Debug::log("Comando $comando a dinahosting");

	my $peticion = JSON::PP->new->encode({

		method=>$comando,
		params=>$datos,

	});

	my $respuesta = undef;

	eval{
		$respuesta = &__peticionLwp($peticion, $loguear);
	};
	if($@){
		$respuesta = &__peticionCurl($peticion, $loguear);
	}
	
	return $respuesta;
}

sub __descodificarRespuesta{
	my $respuesta = $_[0];

	my $respuesta_descodificada;
	eval{
		$respuesta_descodificada = JSON::PP->new->decode($respuesta);
	};
	if($@){
		return undef;
	}
	return $respuesta_descodificada;

}



sub __peticionLwp{
	my $peticion = $_[0];
	my $loguear = $_[1];

	my $ua = LWP::UserAgent->new();	
	$ua->agent('dinaip-perl/1.0 ');

	export PERL_LWP_SSL_VERIFY_HOSTNAME=0;

	my $r = HTTP::Request->new(POST=>$URL_API);
	
	$r->header('Authorization' => 'Basic ' . encode_base64(join(':', &getUsuario, &getPassword)));

	$r->content_type('application/json');
	$r->content($peticion);

	&Debug::log("Enviando a DHAPI: " . Dumper($peticion) ) if($loguear);
	my $respuesta = $ua->request($r);
	&Debug::log("Respuesta de DHAPI: ". Dumper($respuesta->content)) if($loguear);

	if($respuesta){

		my $respuesta_descodificada = &__descodificarRespuesta($respuesta->content);
		if(!$respuesta_descodificada){
			print "Se ha producido un error en la obtencion de respuesta del servidor: " . $respuesta->content;
			exit 1;					
		}
		else{
			return $respuesta_descodificada;
		}
	}
	return undef;
}

sub __peticionCurl{
	my $peticion = $_[0];
	my $loguear = $_[1];

        my $auth = encode_base64(join(':', &getUsuario, &getPassword));
        chomp($auth);

        &Debug::log("Enviando a DHAPI: " . Dumper($peticion) ) if($loguear);
        my $respuesta = `curl -s -X POST -H 'Authorization: Basic $auth' -H 'Content-Type: application/json' -d '$peticion' -k '$URL_API'`;
        &Debug::log("Respuesta de DHAPI: ". Dumper($respuesta)) if($loguear);

        if($respuesta){
                my $respuesta_descodificada = &__descodificarRespuesta($respuesta);

                if(!$respuesta_descodificada){
                        print "Se ha producido un error en la obtencion de respuesta del servidor: " . $respuesta;
                        exit 1;
                }
                else{
                        return $respuesta_descodificada;
                }
        }
        return undef;
}

1;

