# dinaIP para Linux (shell)

## dinaIP: haz que tu dominio resuelva en una IP dinámica

**dinaIP** es una aplicación que se encarga de monitorizar la IP del equipo en el que se está ejecutando y actualizar la información de las zonas según vaya cambiando la misma. Así, permite que todas aquellas zonas que están apuntando a dicho equipo estén siempre actualizadas con los cambios que se van dando.

**dinaIP** mantiene estable el punto de entrada a tu host para acceder a él de forma remota tecleando el nombre de tu dominio. Es muy fácil de usar e incluso te permite la gestión completa de las zonas DNS de tu dominio. Por ejemplo: puedes asignarle tu IP a la zona "micasa", de manera que si tecleas en un navegador "micasa.example.net" (o por SSH, VNC...) podrás acceder a tu PC.

###Requisitos para la instalación
#### Para OpenWrt:
- Perl
- SSL
- curl (comando, necesario solamente si no se pueden instalar los modulos Crypt::SSLeay de Perl, por defecto no aparecen en OpenWrt)

###HOWTO:
Con el parametro -h se ejecuta la ayuda online:

Uso: dinaIP [OPCIONES] ...

-u	ID en dinahosting
-p	Clave de tu perfil de dinahosting
-i 	Arranca el demonio de dinaIP con la configuracion almacenada
-a	Agrega una zona a monitorizar. Sintaxis: dominio:zona1,zona2...
-l	Muestra una lista de los dominios pertenecientes a esta cuenta
-b	Elimina una zona de la monitorizacion. Sintaxis: dominio:zona_a_eliminar
-d	Detiene el demonio de dinaIP
-h	Despliega esta ayuda
-s	Muestra el status del demonio de dinaIP.