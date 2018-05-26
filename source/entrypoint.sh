#!/bin/ash

set -e

# Si las env var no están asignadas, se piden las credenciales por stdin y fail
dinaip -u $USUARIO -p $PASSWORD
