#!/bin/bash
#este archivo es un scrip que:
#compila los fuentes padre.c e hijo.c con gcc
cd ./Trabajo2
gcc padre.c -o padre
gcc hijo.c -o hijo
#crea el fihero fifo "resultado"
mkfifo resultado
#lanza un cat en segundo plano para leer "resultado"
cat resultado &
#lanza el proceso padre
./padre ./padre 10
#al acabar limpia todos los ficheros que ha creado
#borra los exe y el FIFO
rm padre
rm hijo
rm resultado
