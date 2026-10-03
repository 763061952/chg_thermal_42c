#!/system/bin/sh
# 卸载：停守护 → 解除接管（remove=0）→ 档位交回官方 → 清理运行时文件
NODE_RM=/sys/class/xm_power/charger/charger_thermal/wired_thermal_remove
NODE_LV=/sys/class/xm_power/charger/charger_thermal/wired_ctrl_limit
SNAP=/data/local/tmp/chg_stock_gear
for f in /data/local/tmp/chg_fast.pid /data/local/tmp/chg_thermal.pid; do
  p=$(cat "$f" 2>/dev/null); [ -n "$p" ] && kill "$p" 2>/dev/null; rm -f "$f"
done
s=$(cat "$SNAP" 2>/dev/null); case "$s" in ''|*[!0-9]*) s=0 ;; esac
echo 0 > "$NODE_RM" 2>/dev/null
[ -e "$NODE_LV" ] && echo "$s" > "$NODE_LV" 2>/dev/null
rm -f /data/local/tmp/chg_fast.log
echo "稳充 v4.1: 已停止守护并交回系统官方策略(limit=$s)"
