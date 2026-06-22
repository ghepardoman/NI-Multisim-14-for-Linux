#!/bin/bash

# Define the prefix path
PREFIX="$HOME/.multisim32"

echo "Monitoring $PREFIX... Press [CTRL+C] to stop."

while true
do
    # Force-kill the wineserver for this prefix
    killall winedbg > /dev/null 2>&1

    # Wait 1 second before the next check to save CPU cycles
    sleep 1
done
#little blud loxor needs to stop commiting he aint working a 9 to 5
