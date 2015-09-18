package Debug;

use IO::Handle;
use POSIX qw(strftime);

my $INICIADO = undef;
my $DEBUG = undef;

sub log{

	&iniciar unless($INICIADO);
	
	my $fecha = strftime ("%Y-%m-%d %H:%M:%S",localtime());
	print $DEBUG "[$fecha] $_[0] \n";	

}

sub iniciar{

	open ($DEBUG, '>>', '/var/log/dinaip.log') ||
		die($!);

	$DEBUG->autoflush;

	$INICIADO = 1;
}


1;

