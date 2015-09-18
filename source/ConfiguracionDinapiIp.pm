package ConfiguracionDinapiIp;

use strict;
use JSON::PP;

my $RUTA_CONFIGURACION = '/etc/dinaip.conf';

sub new{
	return bless({

		zonas=>$_[1] || {

			"dominio.ejemplo" => [qw(zona1 zona2 zona3)],

		},

		comprobar_cada=>$_[2] || 10,

		cuenta => $_[3] || undef,

	});
}

sub cuenta{
	if($_[1]){
		$_[0]->{cuenta} = $_[1];
		$_[0];
	}
	else{
		$_[0]->{cuenta};
	}
}

sub frecuencia {
	if($_[1]){
		$_[0]->{comprobar_cada} = $_[1];
		return $_[0];
	}

	return $_[0]->{comprobar_cada};
}


sub getUltimoRefresco{
	return (stat($RUTA_CONFIGURACION))[9];
}

sub getDominiosVigilar{

	return grep {

		$_ ne 'dominio.ejemplo',	

	} keys %{$_[0]->{zonas}};	

}

sub getZonasVigilar{
	$_[0]->{zonas}->{$_[1]};
}

sub setZonaVigilar{
	my $self = $_[0];
	my $dominio = $_[1];
	my $zona = $_[2];

	unless(exists($self->{zonas}->{$dominio})){
		$self->{zonas}->{$dominio} = []
	}

	unless(grep { $_ eq $zona} @{$self->{zonas}->{$dominio}}){
		push @{$self->{zonas}->{$dominio}}, $zona;
	}
}

sub existeZonaAVigilar{
	my $self  = $_[0];
	my $dominio = $_[1];
	my $zona = $_[2];

	if($self->{zonas}->{$dominio}){
		return scalar(grep {$_ eq $zona} @{$self->{zonas}->{$dominio}});
	}

}

sub eliminarZonaAVigilar{
	my $self  = $_[0];
	my $dominio = $_[1];
	my $zona = $_[2];

	if($self->{zonas}->{$dominio}){
	
		$self->{zonas}->{$dominio} = [grep {

			$_ ne $zona
	
		} @{$self->{zonas}->{$dominio}}]	

	}

	if(scalar(@{$self->{zonas}->{$dominio}}) == 0){
		$self->eliminarDominioAVigilar($dominio);
	}
}

sub eliminarDominioAVigilar{
	my $self = $_[0];
	my $dominio = $_[1];

	delete($self->{zonas}->{$dominio});
	
}

sub almacenar{

	my %h = %{$_[0]};

	my $datos = JSON::PP->new->pretty->encode(\%h);

	my $fichero;
	open($fichero, '>', $RUTA_CONFIGURACION)||
		die('dinapi: se ha producido un error almacenando la configuracion: ' . $!);

	print $fichero $datos;
	close $fichero;
}

sub recuperar{

	my $fichero;

	unless(-f $RUTA_CONFIGURACION){
		return ConfiguracionDinapiIp->new;
	}

	open($fichero, $RUTA_CONFIGURACION) ||
		die('dinapi: se ha producido un error leyendo el archivo de configuracion: ' . $!);	

	my @datos = <$fichero>;
	close $fichero;

	my $self;
	eval{
		$self = bless(JSON::PP->new->decode(join('', @datos)));	
	};
	if($@){
		die("Error en el fichero de configuracion. Se ha corrompido o no es correcto.".
			"\nBorre el fichero /etc/dinaip.conf y vuelva a lanzar dinaip");
	}

	return $self;

}

sub reset{
	
	unlink($RUTA_CONFIGURACION);

	&recuperar;
}


1;

