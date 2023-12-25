#!/bin/bash
#este archivo es un scrip que:
#compila los fuentes padre.c e hijo.c con gcc
#crea el fihero fifo "resultado"
#lanza un cat en segundo plano para leer "resultado"  
#lanza el proceso padre
#al acabar limpia todos los ficheros que ha creado
#borra los exe y el FIFO