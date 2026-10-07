#!/system/bin/sh
# probe_k90pm.sh - K90PM 充电节点可写性诊断（只读+单次写入测试，运行后自动恢复）
S=/sys/class/xm_power/charger/charger_thermal
B=/sys/class/power_supply/battery

echo "=== permissions ==="
ls -l $S/wired_ctrl_limit $S/wired_thermal_remove $S/wired_chg_curr $S/wired_chg_curr2

echo "=== baseline ==="
echo "limit=$(cat $S/wired_ctrl_limit) remove=$(cat $S/wired_thermal_remove) curr=$(cat $S/wired_chg_curr)"

echo "=== write wired_ctrl_limit=5 ==="
echo 5 > $S/wired_ctrl_limit 2>&1
echo "rc=$?"
echo "readback=$(cat $S/wired_ctrl_limit)"

echo "=== write wired_thermal_remove=1 ==="
echo 1 > $S/wired_thermal_remove 2>&1
echo "rc=$?"
echo "readback=$(cat $S/wired_thermal_remove)"
echo 0 > $S/wired_thermal_remove

echo "=== write wired_chg_curr=5000000 ==="
echo 5000000 > $S/wired_chg_curr 2>&1
echo "rc=$?"
echo "readback=$(cat $S/wired_chg_curr)"
echo 18400000 > $S/wired_chg_curr

echo "=== write wired_ctrl_limit=0 (restore) ==="
echo 0 > $S/wired_ctrl_limit
echo "readback=$(cat $S/wired_ctrl_limit)"

echo "=== dmesg tail (charger) ==="
dmesg | grep -i -E "mca_charger_thermal|ctrl_limit|charger_thermal" | tail -20

echo "=== done ==="
