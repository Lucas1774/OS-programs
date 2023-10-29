#!/bin/bash

# Dummy Demon, you have to complete it to make it do something

# Loop until the apocalypse arrives
#   - Wait for one second
#   - Read the lists and revive processes when necessary, leaving entries in the Bible
#   - You can use as many temporary files as you want, but they must be deleted in the Apocalypse
#   - Use a lock to avoid accessing the lists at the same time as Fausto
#   - Be careful when closing processes; you must terminate the entire tree, not just one of them
# End of the loop

# Apocalypse: terminate all processes and clean up everything, leaving only Fausto, the Demon, and the Bible

# Trap to handle cleanup during the Apocalypse
trap 'kill $(jobs -p)' EXIT

# Loop until the apocalypse arrives
while true; do
  # Wait for one second
  sleep 1

  # Acquire a lock to access the lists
  exec 9<>.lock

  # Read the "procesos" file to check for processes to revive
  while read -r line; do
    pid=$(echo "$line" | awk '{print $1}')
    command_to_run=$(echo "$line" | cut -d' ' -f2-)

    # Check if the process is still alive
    if ! kill -0 "$pid" 2>/dev/null; then
      # Revive the process in the background
      bash -c "$command_to_run" &
    fi
  done < procesos

  # Release the lock
  exec 9>&-
done
