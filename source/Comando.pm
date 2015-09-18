package Comando;

use JSON::PP;

my $RUTA_COMANDOS = '/tmp/.dinaip_com';

my $ULTIMO_COMANDO = undef;

sub new{

	return bless({

		com=>$_[1],
		args=>$_[2]

	}, $_[0]);	

}

sub almacenar{
	my $self = $_[0];
	
	open F, '>', $RUTA_COMANDOS ||
		die('DinaIP: no se pudo abrir el fichero de intercambio de comandos: ' . $!);

	$ULTIMO_COMANDO = [stat(F)];

	my %h = %{$self};

	print F JSON::PP->new->encode(\%h);
	
	close F;
}

sub recuperar{

	if(-f $RUTA_COMANDOS){

		open F, $RUTA_COMANDOS ||
			die('DinaIP: no se pudo abrir el fichero de intercambio de comandos:' . $!);
	
		my $datos = <F>;

		unlink($RUTA_COMANDOS);

		return JSON::PP->new->decode($datos);
	}
}

sub esperarRespuesta{
	my $tiempo_espera_maximo = $_[0] || 5;

	while($tiempo_espera_maximo--){

		sleep(1);
	
		if(-f $RUTA_COMANDOS){
	
			open F, $RUTA_COMANDOS;
			close F;

			if((stat(F))[9] != $ULTIMO_COMANDO->[9]){
		
				return &recuperar;				

			}
			
		}
	
	}

	return undef;	
}

package ComandoListarDominios;

@ISA = qw('Comando');

sub new{
	return Comando->new('LISTAR_DOM');
}

package ComandoListaDeDominios;

@ISA = qw('Comando');

sub new{
	return Comando->new('LISTA_DOMINIOS', [$_[1]]);
}

