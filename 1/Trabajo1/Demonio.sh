#!/bin/bash

# Function to revive a process and log it in the Bible
revive_process() {
  local pid="$1"
  local command="$2"

  # If it is not running, run it
  if ! kill -0 "$pid" 2>/dev/null; then
    bash -c "$command" &

    # Log the revival in Biblia.txt
    echo "$(date '+%T') El proceso $pid '$command' ha resucitado." >>Biblia.txt
  fi
}

# Function to process a list of processes
process_processes() {
  local list_file="$1"

  # Check and maintain the list
  if [ -f "$list_file" ]; then
    while IFS= read -r line; do
      pid=$(echo "$line" | awk '{print $1}')
      command_to_run=$(echo "$line" | cut -d' ' -f2-)

      if [ -e "Infierno/$pid" ]; then
        # Kill the entire process tree
        pkill -P "$pid"
        rm -f "Infierno/$pid"
        echo "$(date '+%T') El proceso $pid '$command_to_run' ha sido destruido." >>Biblia.txt
      elif ! kill -0 "$pid" 2>/dev/null; then
        # TODO: Remove the entry if the process is no longer running
        echo "$(date '+%T') El proceso $pid '$command_to_run' ha terminado." >>Biblia.txt
      fi
    done <"$list_file"
  fi
}

# Loop until Apocalipsis arrives
while ! [ -f "Apocalipsis" ]; do
  sleep 1
  process_processes "procesos"
  process_processes "procesos_servicio"
  process_processes "procesos_periodicos"
done

echo "$(date '+%T') Se acabó el mundo." >>Biblia.txt
