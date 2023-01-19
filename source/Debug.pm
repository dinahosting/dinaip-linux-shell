package Debug;

use IO::Handle;
use POSIX qw(strftime);

my $INICIADO = undef;
my $DEBUG = undef;

my $PRIMERPLANO = undef;

sub log{

        &iniciar unless($INICIADO);

        my $fecha = strftime ("%Y-%m-%d %H:%M:%S",localtime());
        print $DEBUG "[$fecha] $_[0] \n";

}

sub iniciar{
        if ($PRIMERPLANO == 1) {
                open ($DEBUG, '>>', '/dev/stdin') ||
                        die($!);
        } else {
                open ($DEBUG, '>>', '/var/log/dinaip.log') ||
                        die($!);
        }

        $DEBUG->autoflush;

        $INICIADO = 1;
}

sub setPrimerPlano{
        $PRIMERPLANO = $_[0];
}


1;
