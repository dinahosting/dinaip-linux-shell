package Demonio;

use POSIX qw(setsid);
use Fcntl qw(:flock);

use strict;
use Debug;

my $RUTA_PID = '/var/run/dinaip.pid';
#my $RUTA_PID = '/tmp/dinaip.pid';
my $NOMBRE_PROCESO = 'dinaIP';

my $BLOQUEO = undef;
my $SALIR = undef;

my $FRECUENCIA = 10;

my $AVISO_COMANDO = undef;

my $AVISO_RECARGA = undef;

sub iniciar{

        &Debug::log('Iniciando proceso...');

        my $proceso = $_[0];
        my $frecuencia = $_[1] || $FRECUENCIA;
        my $primerPlano = $_[2] || 0;

        if(!$primerPlano && (my $pid = &demonizar)){

                open (F, '>', $RUTA_PID);
                print F $pid;
                close F;

                exit(0);
        }
        else{

                &setDemonioCorriendo;

                &procesar;
        }
}

sub procesar{
	my $proceso = $_[0];
	my $frecuencia = $_[1];

	$0 = $NOMBRE_PROCESO;

	&Debug::log('En demonio...');

	&setFrecuencia($frecuencia);

	&instalarManejadoresSenhales;

	while(!$SALIR){

		&$proceso;

		&Debug::log('Durmiendo ' . $frecuencia);

		for(1..($FRECUENCIA*60)){

			sleep(1);

			if($AVISO_COMANDO){

				&Proceso::ejecutarComando;

				$AVISO_COMANDO = undef;

			}

			if($AVISO_RECARGA){

				$AVISO_RECARGA = undef;
	
				&Proceso::actualizarConfiguracion;

				&$proceso('forzar_actualizacion');

			}

		}

	}
	
	&limpiarDemonio;
}

sub limpiarDemonio{

	unlink($RUTA_PID);

	exit(0);
}

sub salir{
	$SALIR = 1;
}

sub bloquear{
	$BLOQUEO = 1;
}

sub desbloquear{
	$BLOQUEO = undef;
}

sub bloqueado{
	$BLOQUEO;
}

sub setFrecuencia{
	$FRECUENCIA = $_[0] if($_[0] && $_[0] =~ /^\d+$/);
}


sub instalarManejadoresSenhales{
	
	$SIG{TERM} = sub {

		if(&bloqueado){
			&salir;
		}
		else{
			&limpiarDemonio;
		}
	};

	$SIG{HUP} = sub {

		$AVISO_RECARGA = 1;	

	};

	$SIG{USR1} = sub {
	
		$AVISO_COMANDO = 1;

	};

}


sub demonizar{
	chdir '/' || die('DinaIP: no se pudo hacer un chdir a / :' . $!);
	open STDIN, '/dev/null' || die('No se pudo leer /dev/null :' .$!);
	open STDOUT, '>>/tmp/demonio' || die('No se pudo escribir en /dev/null :' . $!);
	open STDERR, '>>/tmp/demonio' || die('No se pudo escribir  en /dev/null : ' . $!);
	
	my $pid = fork;

	unless(defined($pid)){
		die('No se pudo realizar un fork de proceso : ' . $!);
	}
	
	return $pid if($pid);

 	setsid || die('No se puede iniciar una nueva sesion: ' . $!);
	
	umask 0;

	return undef;
}

sub setDemonioCorriendo{
	flock(DATA, LOCK_EX) ||
		die('Se ha producido un error en el intento de bloquear el proceso');
}

sub demonioCorriendo{
	(flock(DATA, LOCK_EX | LOCK_NB)) ? undef : 1;
}

sub demonioDetener{
	

	my $pid = &getPidDemonio;

	kill TERM => $pid;
	print "Deteniendo demonio de dinaIp.";
	&Debug::log("Deteniendo demonio de dinaIp.");

	$| = 1;

	for(1..100){
		unless(kill 0 => $pid){
			print "\nDemonio detenido\n";
			return;
		}

		print '.';
		select(undef, undef, undef, 0.75);
	}
	
	die('El demonio de dinaIp no parece detenerse. Busquelo en su arbol de procesos y detengalo manualmente con kill');
}


sub demonioRecargar{
	
	my $pid = &getPidDemonio;	
	
	kill HUP => $pid;

}

sub demonioComando{

	my $pid = &getPidDemonio;

	kill USR1 => $pid;	

}

sub getPidDemonio{

	unless(-f $RUTA_PID){
		die('No se ha encontrado el fichero de pid en ' . $RUTA_PID. "\n Busque dinaIP en su arbol de procesos y detengalo con kill");
	}
	
	my $f;
	open($f, $RUTA_PID) ||
		die('No se ha podido abrir el fichero de pid en ' . $RUTA_PID. "\n Busque dinaIP en su arbol de procesos y detengalo con kill");

	chomp (my $pid = <$f>);

	close $f;

	return $pid;
}

1;


__DATA__
