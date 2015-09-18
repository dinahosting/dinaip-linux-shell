package ZonaDinaIp;

use strict;
use Debug;


sub new{

	return bless({
		zona => $_[1],
		tipo=> $_[2],
		ip => $_[3],
	});
}

sub cargarZona{
	my $self = $_[0];
	my $datos = $_[1];

	$self->{tipo} = $datos->{type};
	
	if($self->{tipo} eq 'A'){
		$self->{zona} = $datos->{hostname};
		$self->{direccion} = $datos->{address};
		$self->{ip} = $datos->{ip};
	
	}
	else{
		foreach my $k (keys(%$datos)){
			$self->{extra}->{$k} = $datos->{$k};
		}
	}

	$self;
}

#sub generarParametrosParaUrl{
#	my $self = $_[0];
#
#
#	my $parametros = {
#
#		type=>$self->{tipo},
#	};
#	
#	if($self->{tipo} eq 'A'){
#		$parametros->{hostname} = $self->{zona} if($self->{zona});
#		$parametros->{address} = $self->{direccion} if($self->{direccion}); 
#		$parametros->{ip} = $self->{ip} if($self->{ip});
#	}
#	else{
#		
#		if($self->{extra}){
#			$parametros->{$_} = $self->{extra}->{$_} foreach(keys(%{$self->{extra}}));
#		}
#	}
#
#	return $parametros;
#}

package Dominio;	
use Data::Dumper;

sub new{

	return bless({

		dominio=>$_[1],
		zonas=>[],
		cambios => [],
		nuevas_zonas => []

	});
}

sub agregarZona{
	my $self = $_[0];
	my $zona = $_[1];

	#$_[0]->{zonas}->{$_[1]->{zona}} = $_[1];
	push @{$self->{zonas}}, $zona;
}

sub cargar{
	my $dominio = $_[0];
	my $datos = $_[1];

	my $objeto = Dominio->new($dominio);


	foreach my $zona (@{$datos}){
		$objeto->agregarZona(ZonaDinaIp->new->cargarZona($zona));
	}

	&Debug::log("Cargando zonas del dominio $dominio");
	#&Debug::log(Dumper($objeto->{zonas}));

	return $objeto;
}

sub actualizarZonas{
	my $self = $_[0];
	my $lista_zonas = $_[1];
	my $ip_actual = $_[2];

	my $hay_cambios = undef;
	
	my @zonas_A = grep {$_->{tipo} eq 'A'} @{$self->{zonas}};

	

	foreach my $zona (@$lista_zonas){
	
		&Debug::log("Comprobando zona $zona");
		my @zonas_chequear = grep { $_->{zona} eq $zona } @zonas_A;

		if(@zonas_chequear){
			foreach my $z (@zonas_chequear) {
				if($z->{ip} ne $ip_actual){
					$z->{ip_antigua} = $z->{ip};
					$z->{ip} = $ip_actual;

					push @{$self->{cambios}}, $z;

					$hay_cambios = 1;
				}
			}
		}
		else {
			## damos de alta la nueva zona
			push @{$self->{nuevas_zonas}}, 
					ZonaDinaIp->new(
						$zona,
						'A',
						$ip_actual,
					);

			$hay_cambios = 1;
		}

		#if($self->{zonas}->{$zona}->{ip}){

		#	if($self->{zonas}->{$zona}->{ip} ne $ip_actual){

		#		$self->{zonas}->{$zona}->{ip} = $ip_actual;

		#		$hay_cambios = 1;

		#	}
		#}
		#else{

		#	# se crea una nueva zona
		#	$self->agregarZona(

		#		ZonaDinaIp->new(
		#			$zona,
		#			'A',
		#			$ip_actual,
		#		)
		#	);		

		#	$hay_cambios = 1;
		#}

	}
	
	return $hay_cambios;
}

#sub generarParametrosParaUrl{
#	my $self = $_[0];
#
#
#	#my $zonas = [map{
#	#
#	#	$_->generarParametrosParaUrl
#
#	#} values %{$self->{zonas}}];
#
#	&Debug::log("Prepararando envio de las zonas del dominio ".$self->{dominio});
#
#
#
#	my $zonas = [map{
#	
#		$_->generarParametrosParaUrl
#
#	} @{$self->{zonas}}];
#	
#	#&Debug::log(Dumper($zonas));
#	return {
#	
#		domain=>$self->{dominio},
#	
#		zones=>$zonas,
#
#		safeMode=>1,	
#	}
#	
#
#}


1;

