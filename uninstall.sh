#!/system/bin/sh
# 卸载：停守护 → 解除接管（remove=0）→ 清理运行时文件
# 档位不主动回写：v5 交回官方后由官方策略自行接管（K90PM 实测官方会自己写 limit）
NODE_RM=/sys/class/xm_power/charger/charger_thermal/wired_thermal_remove
for f in /data/local/tmp/chg_fast.pid /data/local/tmp/chg_thermal.pid; do
  p=$(cat "$f" 2>/dev/null); [ -n "$p" ] && kill "$p" 2>/dev/null; rm -f "$f"
done
echo 0 > "$NODE_RM" 2>/dev/null
rm -f /data/local/tmp/chg_fast.log /data/local/tmp/chg_stock_gear
echo "稳充 v5: 已停止守护并交回系统官方策略(remove=0)"
