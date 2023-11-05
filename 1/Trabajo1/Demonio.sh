#!/bin/bash

# Constants
LOG_FILE="Biblia.txt"
PROCESS_LIST="procesos"
SERVICE_LIST="procesos_servicio"
PERIODIC_LIST="procesos_periodicos"
LOCK_FILE="SanPedro"
HELL_DIR="Infierno"
APOCALIPSIS_FILE="Apocalipsis"

# Function to revive a process and log it in the Bible
revive_process() {
  local pid="$1"
  local command="$2"

  # If it is not running, run it
  if ! kill -0 "$pid" 2>/dev/null; then
    bash -c "$command" &

    # Log the revival in Biblia.txt
    echo "$(date '+%T') El proceso $pid '$command' ha resucitado." >>"$LOG_FILE"
  fi
}

# Function to process a list of processes
process_processes() {
  local list_file="$1"

  # Check and maintain the list
  if [ -f "$list_file" ]; then
    # Iterate through lines
    while IFS= read -r line; do
      pid=$(echo "$line" | awk '{print $1}')
      command_to_run=$(echo "$line" | cut -d' ' -f2-)
      # If in hell folder -> kill tree, remove from queue
      if [ -e "$HELL_DIR/$pid" ]; then
        pkill -P "$pid"
        flock "$LOCK_FILE" sed -i "/$pid/d" "$list_file"
        rm -f "$HELL_DIR/$pid"
        echo "$(date '+%T') El proceso $pid '$command_to_run' ha sido destruido." >>"$LOG_FILE"
      # If dead -> remove from queue
      elif ! ps | grep "$pid"; then
        flock "$LOCK_FILE" sed -i "/$pid/d" "$list_file"
        echo "$(date '+%T') El proceso $pid '$command_to_run' ha terminado." >>"$LOG_FILE"
      fi
    done
  fi
}

# Loop until Apocalipsis arrives
until [ -f "$APOCALIPSIS_FILE" ]; do
  sleep 1
  process_processes "$PROCESS_LIST"
  process_processes "$SERVICE_LIST"
  process_processes "$PERIODIC_LIST"
done

# Remove files and hell directory
rm -f "$PROCESS_LIST" "$SERVICE_LIST" "$PERIODIC_LIST" "$LOCK_FILE" "$APOCALIPSIS_FILE"
rm -rf "$HELL_DIR"

# Commit suicide
echo "$(date '+%T') Se acabó el mundo." >>"$LOG_FILE"
pkill -f "[D]emonio" >>/dev/null