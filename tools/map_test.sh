#!/system/bin/sh
# map_test.sh - wired_ctrl_limit 取值 → 各电流节点联动 映射实验（root 运行）
S=/sys/class/xm_power/charger/charger_thermal

echo "=== limit sweep -> curr nodes ==="
for v in 0 1 2 3 5 7 9 11 13 14 15 20 100; do
  echo $v > $S/wired_ctrl_limit
  sleep 0.3
  echo "write=$v readback=$(cat $S/wired_ctrl_limit) curr=$(cat $S/wired_chg_curr) curr2=$(cat $S/wired_chg_curr2)"
done

echo "=== restore 0 ==="
echo 0 > $S/wired_ctrl_limit
echo "readback=$(cat $S/wired_ctrl_limit)"

echo "=== remove sweep -> curr nodes ==="
for r in 0 1 0; do
  echo $r > $S/wired_thermal_remove
  sleep 0.3
  echo "remove=$r curr=$(cat $S/wired_chg_curr) curr2=$(cat $S/wired_chg_curr2)"
done

echo "=== done ==="
