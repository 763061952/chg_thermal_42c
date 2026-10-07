#!/system/bin/sh
# hold_test.sh - 写入 wired_ctrl_limit 后跟踪 20 秒，验证是否被官方立即改写
S=/sys/class/xm_power/charger/charger_thermal
B=/sys/class/power_supply/battery

echo "=== baseline ==="
echo "limit=$(cat $S/wired_ctrl_limit) remove=$(cat $S/wired_thermal_remove)"
echo "status=$(cat $B/status) temp=$(cat $B/temp) current=$(cat $B/current_now) voltage=$(cat $B/voltage_now)"

echo "=== set limit=5 ==="
echo 5 > $S/wired_ctrl_limit
echo "immediate readback=$(cat $S/wired_ctrl_limit)"

i=1
while [ $i -le 20 ]; do
  sleep 1
  echo "[t=${i}s] limit=$(cat $S/wired_ctrl_limit) status=$(cat $B/status) temp=$(cat $B/temp) I=$(cat $B/current_now)"
  i=$((i+1))
done

echo "=== restore limit=0 ==="
echo 0 > $S/wired_ctrl_limit
echo "readback=$(cat $S/wired_ctrl_limit)"

echo "=== dmesg tail ==="
dmesg | tail -30

echo "=== done ==="
