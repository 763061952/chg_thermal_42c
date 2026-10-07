#!/system/bin/sh
# test_write_one.sh - 诊断：写 remove=1 后跟踪是否被改回
S=/sys/class/xm_power/charger/charger_thermal
B=/sys/class/power_supply/battery

echo "before=$(cat $S/wired_thermal_remove) limit=$(cat $S/wired_ctrl_limit) temp=$(cat $B/temp) status=$(cat $B/status)"
echo 1 > $S/wired_thermal_remove
echo "rc=$?"
echo "immediate=$(cat $S/wired_thermal_remove)"
sleep 1
echo "t+1s=$(cat $S/wired_thermal_remove)"
sleep 2
echo "t+3s=$(cat $S/wired_thermal_remove)"
sleep 5
echo "t+8s=$(cat $S/wired_thermal_remove) temp=$(cat $B/temp)"
