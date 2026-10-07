#!/system/bin/sh
S=/sys/class/xm_power/charger/charger_thermal
B=/sys/class/power_supply/battery

echo "before=$(cat $S/wired_thermal_remove) limit=$(cat $S/wired_ctrl_limit) temp=$(cat $B/temp)"
echo 0 > $S/wired_thermal_remove
echo "rc=$?"
echo "immediate=$(cat $S/wired_thermal_remove)"
sleep 1
echo "t+1s=$(cat $S/wired_thermal_remove)"
sleep 3
echo "t+4s=$(cat $S/wired_thermal_remove) temp=$(cat $B/temp)"
sleep 5
echo "t+9s=$(cat $S/wired_thermal_remove) limit=$(cat $S/wired_ctrl_limit) temp=$(cat $B/temp) curr=$(cat $S/wired_chg_curr)"
dmesg | grep -i -E "mca_thermal|mca_charger_thermal" | tail -15
