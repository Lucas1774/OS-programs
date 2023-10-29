#!/bin/bash

# Receives commands, creating the appropriate processes and lists
# If the Demon is not alive, it creates it
# When reading/writing to the lists, locking must be used to avoid conflicts with the Demon

# Check if the "Demonio" process is running
if ! pgrep -x "Demonio" > /dev/null; then
    # If the "Demonio" process is not running, start it and perform setup tasks
    ./Demonio > /dev/null 2>&1 &
    
    # Remove files and directory if they exist
    rm -f procesos procesos_servicio procesos_periodicos Biblia.txt SanPedro Apocalipsis
    rm -rf Infierno

    # Create the necessary files and folders
    touch procesos procesos_servicio procesos_periodicos Biblia.txt SanPedro
    mkdir Infierno
fi

# Use a case block to handle different valid arguments
case "$1" in
  run)
    # Check if the 'run' command is provided as an argument
    if [ -z "$2" ]; then
      echo "Usage: $0 run <command>"
      exit 1
    fi

    # Extract the command to be executed
    command_to_run="${@:2}"

    # Run the command in the background
    bash -c "$command_to_run" &

    # Get the PID of the Bash process that is executing the command
    pid=$!

    # Create an entry in the process list file
    echo "$pid '$command_to_run'" >> procesos

    # Record the process birth event in Biblia.txt
    echo "$(date '+%T:%M:%S'): The process $pid '$command_to_run' has been born." >> Biblia.txt

    # Exit immediately
    exit 0
    ;;

  # Add more valid arguments here if needed
  *)
    echo "Usage: $0 {run}"
    exit 1
    ;;
esac
