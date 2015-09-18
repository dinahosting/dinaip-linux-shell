#!/bin/sh

RUTA_INSTALACION='/opt/dinaip'
LINK='/usr/sbin/dinaip'
RUTA_CONFIGURACION='/etc/dinaip.conf'

MY_PATH="`dirname \"$0\"`"
MY_PATH="`( cd \"$MY_PATH\" && pwd )`"

instalar() {

	if [ -z "$MY_PATH" ]; then
		echo "No es posible acceder al directorio de extraccion"
		exit 1
	fi
	
	
	if [ "$(id -u)" != "0" ]; then
	   echo "Necesitas ser root para instalar la aplicacion" 1>&2
	   exit 1
	fi
	
	
	if [ -d $RUTA_INSTALACION ]; then
		echo "La ruta de instalacion $RUTA_INSTALACION ya existe"
		exit 1
	else
		/bin/mkdir -p $RUTA_INSTALACION
		/bin/cp -a * $RUTA_INSTALACION/
	fi
	
	if [ ! -e $LINK ]; then
		exec /bin/ln -s $RUTA_INSTALACION/dinaip.pl $LINK
	fi
	
	echo "dinaip instalado correctamente en $RUTA_INSTALACION";
	dinaip -h

}

desinstalar() {

	if [ "$(id -u)" != "0" ]; then
	   echo "Necesitas ser root para desinstalar la aplicacion" 1>&2
	   exit 1
	fi

	if [ ! -d "$RUTA_INSTALACION" ]; then
		echo "El directorio de instalacion de dinaip no existe"
		exit 1;
	fi
	
	rm -rf $RUTA_INSTALACION
	rm -f $LINK
	rm -f $RUTA_CONFIGURACION;
	
	echo "dinaip desinstalado correctamente"
}

if [ "$1" = "-u" ];
	then
		desinstalar
	else
		instalar
fi


