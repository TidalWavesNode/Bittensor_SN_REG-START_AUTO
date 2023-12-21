#!/bin/bash

# Change directory to ~/tensorage/neurons
cd ~/map-reduce-subnet/neurons

# Prompt user for the maximum registration cost they are willing to pay
read -p "Enter the maximum registration cost you are willing to pay: " REGCOST

# Prompt user for the subnet number
read -p "Enter the subnet number: " SN

# Prompt user for the wallet password and save it as PW
read -s -p "Enter your wallet password: " PW
echo

# Prompt user for the miner start script
read -p "Enter the command to start your miner: " START

# Prompt user for the sleep interval between registration attempts
read -p "Enter the sleep interval (in seconds) between registration attempts (default 600): " SLEEP_INTERVAL

# If the user input is empty or not a number, set the default sleep interval to 600 seconds
if ! [[ "$SLEEP_INTERVAL" =~ ^[0-9]+$ ]]; then
    SLEEP_INTERVAL=600
fi

# Function to check registration cost and perform registration
register() {
    # Check the cost to register
    COST_OUTPUT=$(btcli s list | awk '$1 == $SN {sub(/τ/, "", $6); print $6}')
    REGISTRATION_COST=$(echo "$COST_OUTPUT" | grep -oP 'The cost to register is \K[0-9.]+')

    # Compare the registration cost with the user's maximum willing to pay
    if (( $(echo "$REGISTRATION_COST < $REGCOST" | bc -l) )); then
        # If the cost is less than the maximum the user is willing to pay, proceed with registration
        echo "The cost to register is within your specified limit. Proceeding with registration..."
        # Run the registration command and input the password when prompted
        expect -c "
            spawn btcli s register --subtensor.network finney --netuid $SN --wallet.name default --wallet.hotkey default 
            expect \"Are you sure you want to register? (y/n):\"
            send \"y\r\"
            expect \"Enter your wallet password:\"
            send \"$PW\r\"
            expect eof
        "
        return 0
    else
        echo "The cost to register is greater than your specified limit. Registration aborted."
        return 1
    fi
}

# Loop until registration is successful
while true; do
    if register; then
        echo "Registration successful!"
        break
    else
        echo "Retrying in $SLEEP_INTERVAL seconds..."
        sleep $SLEEP_INTERVAL
    fi
done

# Run the miner start script
echo "Starting your miner..."
eval $START
