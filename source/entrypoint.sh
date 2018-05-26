#!/bin/ash

set -e
#-p	Contraseña del usuario de dinahosting
#-i 	Arranca el demonio de dinaip con la configuracion almacenada
#-a	Agrega una zona a monitorizar. Sintaxis: dominio:zona1,zona2...
#-l	Muestra una lista de los dominios pertenecientes a esta cuenta
#-b	Elimina una zona de la monitorización. Sintaxis: dominio:zona_a_eliminar
#-d	Detiene el demonio de DinaIP
#-h	Despliega esta ayuda
#-s	Muestra el status del demonio de DinaIP. 


dinaip -u $USUARIO -p $PASSWORD
