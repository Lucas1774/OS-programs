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
  pid="$1"
  # tree -> tree with only PID -> space separated PIDs
  childernPidsSpaceSeparated=$(pstree -p $pid | grep -o -E '[0-9]+' | tr '\n' ' ')
  kill -SIGTERM "$childernPidsSpaceSeparated"
}

# Function to process a list of processes
process() {
  local list_file="$1"

  # Check and maintain the list
  if [[ -f "$list_file" ]]; then
    # Iterate through lines
    IFS=$'\n' # Define line separator
    for line in $(cat "$list_file"); do
      echo "line: $line"
      # Get pid and command
      if [[ "$list_file" != "$PERIODIC_LIST" ]]; then
        pid=$(echo "$line" | awk '{print $1}')
        command_to_run=$(cut -d' ' -f2- <<<"$line")
      else
        pid=$(echo "$line" | awk '{print $3}')
        command_to_run="$(cut -d' ' -f4- <<<"$line")"
      fi
      # If in hell folder -> kill tree, remove from queue
      if [[ -e "$HELL_DIR/$pid" ]]; then
        flock "$LOCK_FILE" sed -i "/$pid/d" "$list_file"
        rm -f "$HELL_DIR/$pid"
        echo "$(date '+%T') El proceso $pid $command_to_run ha sido destruido." >>"$LOG_FILE"
        kill_tree "$pid"
      else
        # If periodic adjust times
        if [[ "$list_file" == "$PERIODIC_LIST" ]]; then
          former_time=$(awk '{print $1}' <<<"$line")
          ((current_time = former_time + 1))
          total_time=$(awk '{print $2}' <<<"$line")
          flock $LOCK_FILE sed -i "/$pid/ s/^$former_time /$current_time /g" $list_file
        fi
        # If dead
        if ! ps "$pid" >/dev/null; then
          flock "$LOCK_FILE" sed -i "/$pid/d" "$list_file" # Remove from queue
          # If process
          if [[ "$list_file" == "$PROCESS_LIST" ]]; then
            echo "$(date '+%T') El proceso $pid $command_to_run ha terminado." >>"$LOG_FILE"
          # If service
          elif [[ "$list_file" == "$SERVICE_LIST" ]]; then
            # Revive
            clean_command_to_run=$(echo "$command_to_run" | tr -d "'") # Remove quotes
            bash -c "$clean_command_to_run" &
            new_pid=$!
            flock "$LOCK_FILE" echo "$new_pid" "$command_to_run" >>"$list_file"
            echo "$(date '+%T') El servicio $pid $command_to_run ha resucitado con pid "$new_pid"." >>"$LOG_FILE"
          # If periodic and shouldn't be dead
          elif [[ "$current_time" -ge "$total_time" ]]; then
            # Revive
            clean_command_to_run=$(echo "$command_to_run" | tr -d "'") # Remove quotes
            bash -c "$clean_command_to_run" &
            new_pid=$!
            flock "$LOCK_FILE" echo "0" "$total_time" "$new_pid" "$command_to_run" >>"$list_file"
            echo "$(date '+%T') El proceso periódico $pid $command_to_run ha resucitado con pid "$new_pid"." >>"$LOG_FILE"
          fi
        fi
      fi
    done
  fi
}

do_kill() {
  local list_file="$1"
  IFS=$'\n' # Define line separator
  for line in $(cat "$list_file"); do
    # Get pid and command
    if [[ "$list_file" != "$PERIODIC_LIST" ]]; then
      pid=$(echo "$line" | awk '{print $1}')
      command_to_run=$(cut -d' ' -f2- <<<"$line")
    else
      pid=$(echo "$line" | awk '{print $3}')
      command_to_run="$(cut -d' ' -f4- <<<"$line")"
    fi
    flock "$LOCK_FILE" sed -i "/$pid/d" "$list_file"
    echo "$(date '+%T') El proceso $pid $command_to_run ha sido destruido." >>"$LOG_FILE"
    kill_tree "$pid"
  done
}

# Loop until Apocalipsis arrives
until [[ -f "$APOCALIPSIS_FILE" ]]; do
  sleep 1
  process "$PROCESS_LIST"
  process "$SERVICE_LIST"
  process "$PERIODIC_LIST"
done

echo "$(date '+%T'): ---------------Apocalipsis---------------" >>"$LOG_FILE"
do_kill "$PROCESS_LIST"
do_kill "$SERVICE_LIST"
do_kill "$PERIODIC_LIST"
# Remove files and hell directory
rm -f "$PROCESS_LIST" "$SERVICE_LIST" "$PERIODIC_LIST" "$LOCK_FILE" "$APOCALIPSIS_FILE"
rm -rf "$HELL_DIR"

# Commit suicide
echo "$(date '+%T') Se acabó el mundo." >>"$LOG_FILE"
pkill -f "[D]emonio" >>/dev/null
