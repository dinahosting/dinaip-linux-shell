#!/bin/ash

set -e
if [[ -z "${USUARIO}" ]]; then
  echo "USUARIO no definido"
  exit 1
elif [[ -z "${PASSWORD}" ]]; then
  echo "PASSWORD no definida"
  exit 1
fi

alias dina='dinaip -u "${USUARIO}" -p "${PASSWORD}"'
# dinaip -u "${USUARIO}" -p "${PASSWORD}" -a rubencabrera.es:www
# echo "-i"
# dina -i
# echo "Añadiendo zona www"
# dina
echo "-l Lista los dominios de esta cuenta"
dina -l
sleep 5
echo "-s Muestra el estado"
dina -s
# Para meter otra zona este es el comando.
# TODO: ejecutar opcionalmente si le pasamos los argumentos necesarios
# echo "Vamos a meter otra zona NUEVA"
# dina -a rubencabrera.art:prueba
echo "Fin del script, hasta luego"
