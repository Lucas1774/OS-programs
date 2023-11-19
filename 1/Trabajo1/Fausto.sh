#!/bin/bash

# Constants
LOG_FILE="Biblia.txt"
PROCESS_LIST="procesos"
SERVICE_LIST="procesos_servicio"
PERIODIC_LIST="procesos_periodicos"
LOCK_FILE="SanPedro"
HELL_DIR="Infierno"
APOCALIPSIS_FILE="Apocalipsis"

# -----LAUNCHING "DEMONIO"-----
# Check if the "Demonio" process is running
if ! pgrep -x "Demonio.sh" >/dev/null; then
  # Remove files and directory if they exist
  rm -f "$PROCESS_LIST" "$SERVICE_LIST" "$PERIODIC_LIST" "$LOG_FILE" "$LOCK_FILE" "$APOCALIPSIS_FILE"
  rm -rf "$HELL_DIR"

  # Create the necessary files and folders
  touch "$PROCESS_LIST" "$SERVICE_LIST" "$PERIODIC_LIST" "$LOG_FILE" "$LOCK_FILE"
  mkdir "$HELL_DIR"

  # Start it and perform setup tasks
  nohup ./Demonio.sh >/dev/null &

  # Record the creation of the demon in Biblia.txt
  echo "$(date '+%T'): ---------------Génesis---------------" >>"$LOG_FILE"
  echo "$(date '+%T') El demonio ha sido creado" >>"$LOG_FILE"
fi

# ----------------------------------------------------------------------
# Function to check if the required number of arguments are provided
check_arguments() {
  local command_name="$1"
  local required_arg_count="$2"
  local received_arg_count="$3"
  if [ "$received_arg_count" -ne "$required_arg_count" ]; then
    echo "Argumentos esperados: '$required_arg_count'"
    echo "Argumentos recibidos: '$received_arg_count'"
    exit 1
  fi
}

# Script
case "$1" in
run)
  check_arguments "$1" 2 "$#"
  command="$2"
  bash -c "$command" &
  pid=$!
  # Record the event list and bible
  flock "$LOCK_FILE" echo "$pid '$command'" >>"$PROCESS_LIST"
  echo "$(date '+%T'): El proceso $pid '$command' ha nacido." >>"$LOG_FILE"
  exit 0
  ;;

run-service)
  check_arguments "$1" 2 "$#"
  service_command="$2"
  bash -c "$service_command" &
  service_pid=$!
  # Record the event list and bible
  flock "$LOCK_FILE" echo "$service_pid '$service_command'" >>"$SERVICE_LIST"
  echo "$(date '+%T'): El proceso servicio $service_pid '$service_command' ha nacido." >>"$LOG_FILE"
  exit 0
  ;;

run-periodic)
  check_arguments "$1" 3 "$#"
  period="$2"
  periodic_command="$3"
  bash -c "$periodic_command" &
  pid=$!
  # Record the event list and bible
  flock "$LOCK_FILE" echo "0 $period $pid '$periodic_command'" >>"$PERIODIC_LIST"
  echo "$(date '+%T'): El proceso periódico $pid '$periodic_command' ha nacido." >>"$LOG_FILE"
  exit 0
  ;;

list)
  check_arguments "$1" 1 "$#"
  echo "Lista de procesos:"
  cat "$PROCESS_LIST" "$SERVICE_LIST" "$PERIODIC_LIST"
  exit 0
  ;;

help)
  check_arguments "$1" 1 "$#"
  echo "Comandos disponibles y su sintaxis:"
  echo "./Fausto.sh run <comando>"
  echo "./Fausto.sh run-service <comando>"
  echo "./Fausto.sh run-periodic <periodo> <comando>"
  echo "./Fausto.sh list (Mostrar el contenido de las listas: $PROCESS_LIST, $SERVICE_LIST y $PERIODIC_LIST)"
  echo "./Fausto.sh help (Mostrar los comandos disponibles y su sintaxis)"
  echo "./Fausto.sh stop <PID> (Detener un proceso por su PID)"
  exit 0
  ;;

stop)
  check_arguments "$1" 2 "$#"
  pid_to_stop="$2"

  if [ -f "$PROCESS_LIST" ] || [ -f "$SERVICE_LIST" ] || [ -f "$PERIODIC_LIST" ]; then
    # Check if the PID exists in any of the lists
    if grep -q "$pid_to_stop" "$PROCESS_LIST" "$SERVICE_LIST" "$PERIODIC_LIST"; then
      # Create a file in the 'Infierno' folder to signal the demon to stop the process
      touch "$HELL_DIR/$pid_to_stop"
    else
      echo "PID $pid_to_stop no está en las listas. Usa './Fausto.sh list'"
    fi
  else
    echo "Las listas ($PROCESS_LIST, $SERVICE_LIST, and $PERIODIC_LIST) no existen."
  fi
  exit 0
  ;;

end)
  touch "$APOCALIPSIS_FILE"
  exit 0
  ;;

*)
  echo "Uso: $0 {run | run-service | run-periodic | list | help | stop}"
  exit 1
  ;;
esac
