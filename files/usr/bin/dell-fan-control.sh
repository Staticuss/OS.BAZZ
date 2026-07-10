#!/bin/bash
# Dynamic Fan Speed Controller for Dell PowerEdge R730xd via ipmitool
# Monitors CPU temperature and controls fan speed accordingly.

# Temp thresholds
TEMP_LOW=55
TEMP_HIGH=72

# Fan speed levels (hex values)
SPEED_MIN="0x0c"     # ~12% speed
SPEED_MED="0x1b"     # ~27% speed
SPEED_MAX="0x32"     # ~50% speed

# IP/Auth overrides can be done via local variables or environment,
# but locally (using local IPMI interface) we do not need host/password:
IPMI_CMD="ipmitool raw"

# Ensure ipmitool is available
if ! command -v ipmitool &> /dev/null; then
    echo "ipmitool could not be found, exiting."
    exit 1
fi

echo "Starting Dell PowerEdge R730xd Dynamic Fan Control daemon..."

# Main monitoring loop
while true; do
    # Get highest CPU core temperature (using standard sysfs/sensors)
    # Fallback to ipmitool sdr temp reading if sysfs is not present
    TEMP=$(ipmitool sdr type temperature | grep -i "Temp" | awk '{print $10}' | sort -n | tail -1 | cut -d'.' -f1)

    if [ -z "$TEMP" ] || ! [[ "$TEMP" =~ ^[0-9]+$ ]]; then
        # fallback to sysfs coretemp
        TEMP=$(cat /sys/class/hwmon/hwmon*/temp*_input 2>/dev/null | sort -n | tail -1)
        if [ ! -z "$TEMP" ]; then
            TEMP=$((TEMP / 1000))
        else
            TEMP=45 # Default fallback
        fi
    fi

    echo "Current maximum temperature: ${TEMP}°C"

    if [ "$TEMP" -ge "$TEMP_HIGH" ]; then
        echo "Temperature high (${TEMP}°C). Restoring automatic iDRAC control."
        $IPMI_CMD 0x30 0x30 0x01 0x01
    elif [ "$TEMP" -ge "$TEMP_LOW" ]; then
        echo "Temperature moderate (${TEMP}°C). Setting manual medium speed (${SPEED_MED})."
        $IPMI_CMD 0x30 0x30 0x01 0x00
        $IPMI_CMD 0x30 0x30 0x02 0xff $SPEED_MED
    else
        echo "Temperature low (${TEMP}°C). Setting manual low speed (${SPEED_MIN})."
        $IPMI_CMD 0x30 0x30 0x01 0x00
        $IPMI_CMD 0x30 0x30 0x02 0xff $SPEED_MIN
    fi

    sleep 10
done
