#!/system/bin/sh
# observe.sh [duration_sec] [interval_sec] - 采样充电状态（只读，不改任何节点）
S=/sys/class/xm_power/charger/charger_thermal
B=/sys/class/power_supply/battery
U=/sys/class/power_supply/usb
OUT=/data/local/tmp/chg_calib
DUR=${1:-90}
IV=${2:-2}

mkdir -p $OUT
LOG=$OUT/observe_$(date +%m%d_%H%M%S).log

line() {
  t=$1
  limit=$(cat $S/wired_ctrl_limit 2>/dev/null)
  remove=$(cat $S/wired_thermal_remove 2>/dev/null)
  curr=$(cat $S/wired_chg_curr 2>/dev/null)
  st=$(cat $B/status 2>/dev/null)
  cap=$(cat $B/capacity 2>/dev/null)
  temp=$(cat $B/temp 2>/dev/null)
  ib=$(cat $B/current_now 2>/dev/null)
  vb=$(cat $B/voltage_now 2>/dev/null)
  ct=$(cat $B/charge_type 2>/dev/null)
  iu=$(cat $U/current_now 2>/dev/null)
  vu=$(cat $U/voltage_now 2>/dev/null)
  # 功率(W)：|I|×V/1e12
  p=$(awk -v i="$ib" -v v="$vb" 'BEGIN{ if(i<0)i=-i; printf "%.1f", i*v/1e12 }')
  echo "[$t] limit=$limit remove=$remove curr=$curr $st ${cap}% ${temp}T batt=${vb}uV/${ib}uA (${p}W) usb=${vu}uV/${iu}uA type=$ct"
}

i=0
while [ $i -le $DUR ]; do
  line "${i}s" | tee -a $LOG
  i=$((i+IV))
  [ $i -le $DUR ] && sleep $IV
done

echo "saved: $LOG"
