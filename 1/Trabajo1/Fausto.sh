#!/bin/bash

# -----lAUNCHING "DEMONIO"-----
# Check if the "Demonio" process is running
if ! pgrep -x "Demonio" >/dev/null; then
  # Remove files and directory if they exist
  rm -f procesos procesos_servicio procesos_periodicos Biblia.txt SanPedro Apocalipsis
  rm -rf Infierno

  # Create the necessary files and folders
  touch procesos procesos_servicio procesos_periodicos Biblia.txt SanPedro
  mkdir Infierno

  # If the "Demonio" process is not running, start it and perform setup tasks
  ./Demonio.sh >/dev/null 2>&1 &

  # Record the creation of the demon in Biblia.txt
  echo "$(date '+%T'): ---------------Génesis---------------" >>Biblia.txt
  echo "$(date '+%T') El demonio ha sido creado" >>Biblia.txt
fi

# -----RUN COMMAND-----
# Function to check if the required number of arguments are provided
check_arguments() {
  local command_name="$1"
  local required_arg_count="$2"
  local recieved_arg_count="$3"
  if [ $recieved_arg_count -ne "$required_arg_count" ]; then
    echo "Uso: $0 $command_name <arg1> <arg2> ..."
    exit 1
  fi
}

# Function to record an event
record_event() {
  local pid_file="$1"
  local command="$2"
  local pid=$!
  echo "$pid '$command'" >>"$pid_file"
  echo "$(date '+%T'): El proceso $pid '$command' ha nacido." >>Biblia.txt
}

# Script
case "$1" in
run)
  check_arguments "$1" 2 $#
  command="${@:2}"
  bash -c "$command" &
  pid=$!

  # Record the event list and bible
  echo "$pid '$command'" >>"procesos"
  echo "$(date '+%T'): El proceso $pid '$command' ha nacido." >>Biblia.txt
  exit 0
  ;;

run-service)
  check_arguments "$1" 2 $#
  service_command="${@:2}"
  bash -c "$service_command" &
  service_pid=$!

  # Record the event list and bible
  echo "$service_pid '$service_command'" >>"procesos_servicio"
  echo "$(date '+%T'): El proceso servicio $service_pid '$service_command' ha nacido." >>Biblia.txt
  exit 0
  ;;

run-periodic)
  check_arguments "$1" 3 $#
  period="$2"
  periodic_command="${@:3}"
  bash -c "$periodic_command" &
  pid=$!

  # Record the event list and bible
  echo "0 $period $pid '$periodic_command'" >>"procesos_periodicos"
  echo "$(date '+%T'): El proceso periódico $pid '$periodic_command' ha nacido." >>Biblia.txt
  exit 0
  ;;

list)
  check_arguments "$1" 1 $#
  echo "Contents of list files:"
  cat "procesos"
  cat "procesos_servicio"
  cat "procesos_periodicos"
  exit 0
  ;;

help)
  check_arguments "$1" 1 $#
  echo "Comandos disponibles y su sintaxis:"
  echo "./Fausto.sh run <comando>"
  echo "./Fausto.sh run-service <comando>"
  echo "./Fausto.sh run-periodic <periodo> <comando>"
  echo "./Fausto.sh list (Mostrar el contenido de las listas: procesos, procesos_servicio y procesos_periodicos)"
  echo "./Fausto.sh help (Mostrar los comandos disponibles y su sintaxis)"
  echo "./Fausto.sh stop <PID> (Detener un proceso por su PID)"
  exit 0
  ;;

stop)
  check_arguments "$1" 2 $#
  local pid_to_stop="$2"

  if [ -f "procesos" ] || [ -f "procesos_servicio" ] || [ -f "procesos_periodicos" ]; then
    # Check if the PID exists in any of the lists
    if grep -q "$pid_to_stop" procesos procesos_servicio procesos_periodicos; then
      # Create a file in the 'Infierno' folder to signal the demon to stop the process
      touch "Infierno/$pid_to_stop"
    else
      echo "PID $pid_to_stop no está en las listas. Usa './Fausto.sh list'"
    fi
  else
    echo "Las listas (procesos, procesos_servicio, and procesos_periodicos) no existen o están vacías."
  fi
  ;;

*)
  echo "Uso: $0 {run | run-service | run-periodic | list | help | stop}"
  exit 1
  ;;
esac
