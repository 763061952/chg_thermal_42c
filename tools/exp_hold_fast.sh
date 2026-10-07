#!/system/bin/sh
# exp_hold_fast.sh [duration] - 单次写 remove=1 + limit=0，观察官方是否改回
S=/sys/class/xm_power/charger/charger_thermal
B=/sys/class/power_supply/battery
DUR=${1:-90}

echo "=== before ==="
echo "limit=$(cat $S/wired_ctrl_limit) remove=$(cat $S/wired_thermal_remove) temp=$(cat $B/temp)"

echo "=== apply: remove=1, limit=0 ==="
echo 1 > $S/wired_thermal_remove
echo 0 > $S/wired_ctrl_limit
echo "applied: limit=$(cat $S/wired_ctrl_limit) remove=$(cat $S/wired_thermal_remove)"

i=3
while [ $i -le $DUR ]; do
  sleep 3
  limit=$(cat $S/wired_ctrl_limit)
  remove=$(cat $S/wired_thermal_remove)
  curr=$(cat $S/wired_chg_curr)
  st=$(cat $B/status)
  cap=$(cat $B/capacity)
  temp=$(cat $B/temp)
  ib=$(cat $B/current_now)
  vb=$(cat $B/voltage_now)
  p=$(awk -v i="$ib" -v v="$vb" 'BEGIN{ if(i<0)i=-i; printf "%.1f", i*v/1e12 }')
  echo "[t=${i}s] limit=$limit remove=$remove curr=$curr $st ${cap}% ${temp}T ${p}W"
  i=$((i+3))
done

echo "=== leave state as-is (remove/limit NOT restored) ==="
echo "final: limit=$(cat $S/wired_ctrl_limit) remove=$(cat $S/wired_thermal_remove)"
