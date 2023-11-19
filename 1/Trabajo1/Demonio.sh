#!/bin/bash

# Constants
LOG_FILE="Biblia.txt"
PROCESS_LIST="procesos"
SERVICE_LIST="procesos_servicio"
PERIODIC_LIST="procesos_periodicos"
LOCK_FILE="SanPedro"
HELL_DIR="Infierno"
APOCALIPSIS_FILE="Apocalipsis"

# Function to kill a process tree
kill_tree() {
  local pid="$1"
  pids=$(pgrep -P "$pid")
  echo " killing proceses $pids" # For debugging purposes
  kill -SIGTERM $pids
  kill -SIGTERM $pid
}

# Function to process a list of processes
process() {
  local list_file="$1"

  # Check and maintain the list
  if [ -f "$list_file" ]; then
    # Iterate through lines
    while IFS= read -r line; do
      pid=$(echo "$line" | awk '{print $1}')
      command_to_run=$(echo "$line" | cut -d' ' -f2-)
      # If in hell folder -> kill tree, remove from queue
      if [ -e "$HELL_DIR/$pid" ]; then
        flock "$LOCK_FILE" sed -i "/$pid/d" "$list_file"
        kill_tree "$pid"
        rm -f "$HELL_DIR/$pid"
        echo "$(date '+%T') El proceso $pid '$command_to_run' ha sido destruido." >>"$LOG_FILE"
      # If dead
      elif ! ps "$pid" > /dev/null; then
        flock "$LOCK_FILE" sed -i "/$pid/d" "$list_file"
        # If process remove from list
        if [ "$list_file" == "$PROCESS_LIST" ]; then
          echo "$(date '+%T') Process $pid '$command_to_run' has terminated." >>"$LOG_FILE"
        # If service revive
        elif [ "$list_file" == "$SERVICE_LIST" ]; then
          bash -c "$command_to_run" &
          new_pid=$!
          flock "$LOCK_FILE" echo "$new_pid '$command_to_run'" >> "$list_file"
          echo "$(date '+%T') El servicio $pid $command_to_run ha resucitado." >>"$LOG_FILE"
        fi
      fi
    done < "$list_file"
  fi
}

# Function to process a list of periodic processes
# process_periodic() {
# }

# Loop until Apocalipsis arrives
until [ -f "$APOCALIPSIS_FILE" ]; do
  sleep 1
  process "$PROCESS_LIST"
  process "$SERVICE_LIST"
  # process_periodic "$PERIODIC_LIST"
done

# Remove files and hell directory
rm -f "$PROCESS_LIST" "$SERVICE_LIST" "$PERIODIC_LIST" "$LOCK_FILE" "$APOCALIPSIS_FILE"
rm -rf "$HELL_DIR"

# Commit suicide
echo "$(date '+%T') Se acabó el mundo." >>"$LOG_FILE"
pkill -f "[D]emonio" >>/dev/null