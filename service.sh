#!/system/bin/sh
# ============================================================
#  稳充 v4.1   作者：酷安@happier2
#  = 亮屏快充（remove=1 + 放开档）+ 可选功率闭环（把功率稳在 TARGET_W）
#  逻辑：
#    ① 充电中：remove=1；每 STEP_EVERY 次巡检调一次档位——
#       功率 > TARGET+TOL_HI → 档位+1（收紧）；功率 < TARGET-TOL_LO → 档位-1（放松）
#       档位范围 [GEAR_MIN, GEAR_MAX]（GEAR_MIN=最放开，绝不比旧版更放开）
#    ② 未充电 / 按钮关闭：remove=0 + 恢复官方档，然后退出（零残留）
#
#  安全：本脚本只写厂商自己的充电节点，不碰电芯保护；节点不存在则直接退出。
# ============================================================
MODDIR=${0%/*}
[ -f "$MODDIR/config.sh" ] && . "$MODDIR/config.sh"
: "${POLL:=2}"; : "${TARGET_W:=40}"; : "${TOL_HI:=2}"; : "${TOL_LO:=4}"; : "${STEP_EVERY:=3}"
: "${GEAR_MIN:=3}"; : "${GEAR_MAX:=12}"; : "${STOCK_GEAR:=12}"; : "${POWER_LOOP:=0}"
N=/sys/class/xm_power/charger/charger_thermal
B=/sys/class/power_supply/battery
LOG=/data/local/tmp/chg_fast.log
PIDF=/data/local/tmp/chg_fast.pid
PIDF2=/data/local/tmp/chg_thermal.pid
SNAP=/data/local/tmp/chg_stock_gear

[ -w "$N/wired_thermal_remove" ] || exit 1

if [ -f "$PIDF" ]; then
  old=$(cat "$PIDF" 2>/dev/null)
  case "$old" in
    ''|*[!0-9]*) ;;
    *) if [ -d "/proc/$old" ]; then
         c=$(tr '\0' ' ' < "/proc/$old/cmdline" 2>/dev/null)
         case "$c" in *chg_thermal_42c/service.sh*) exit 0 ;; esac
       fi ;;
  esac
fi
echo $$ > "$PIDF"; echo $$ > "$PIDF2"
echo "$STOCK_GEAR" > "$SNAP" 2>/dev/null

log(){ echo "[chg_fast] $(date '+%m-%d %H:%M:%S') $*" >> "$LOG"; }
until [ "$(getprop sys.boot_completed)" = "1" ]; do sleep 2; done
sleep 6

restore_once(){ echo 0 > "$N/wired_thermal_remove" 2>/dev/null; echo "$STOCK_GEAR" > "$N/wired_ctrl_limit" 2>/dev/null; }
put_gear(){ echo "$1" > "$N/wired_ctrl_limit" 2>/dev/null; }
power_w(){ awk -v c="$(cat $B/current_now 2>/dev/null)" -v v="$(cat $B/voltage_now 2>/dev/null)" 'BEGIN{ if(c==""||v==""){print 0; exit} if(c<0)c=-c; printf "%.1f", c*v/1e12 }'; }

gear=$GEAR_MIN; mode=""; n=0
log "=== v4.1 亮屏快充启动 pid=$$ 功率闭环=${POWER_LOOP:-0} 目标=${TARGET_W}W 档位区间[$GEAR_MIN,$GEAR_MAX] ==="
while true; do
  if [ -f "$MODDIR/disable" ]; then
    restore_once
    log "按钮关闭 → 已交回官方(remove=0 limit=$STOCK_GEAR)，守护退出"
    rm -f "$PIDF" "$PIDF2"
    exit 0
  fi
  st=$(cat $B/status 2>/dev/null)
  case "$st" in
    Charging|Full)
      echo 1 > "$N/wired_thermal_remove" 2>/dev/null
      p=$(power_w); n=$((n+1))
      if [ "${POWER_LOOP:-0}" = "1" ] && [ $((n % STEP_EVERY)) -eq 0 ]; then
        hi=$(( TARGET_W + TOL_HI )); lo=$(( TARGET_W - TOL_LO ))
        if awk -v p="$p" -v hi="$hi" 'BEGIN{exit !(p>hi)}'; then
          [ "$gear" -lt "$GEAR_MAX" ] && { gear=$((gear+1)); log "功率 ${p}W 偏高 → 收紧档位=$gear"; }
        elif awk -v p="$p" -v lo="$lo" 'BEGIN{exit !(p<lo)}'; then
          [ "$gear" -gt "$GEAR_MIN" ] && { gear=$((gear-1)); log "功率 ${p}W 偏低 → 放松档位=$gear"; }
        fi
      fi
      [ "${POWER_LOOP:-0}" = "1" ] || gear=$GEAR_MIN    # 闭环关闭时恒定用放开档
      put_gear "$gear"
      if [ "$mode" != "fast" ]; then log "亮屏快充已生效：remove=1 档位=$gear 功率=${p}W 闭环=${POWER_LOOP:-0}"; mode="fast"; fi
      ;;
    *)
      if [ "$mode" != "idle" ]; then restore_once; log "未充电 → 恢复官方档(remove=0 limit=$STOCK_GEAR)"; mode="idle"; fi ;;
  esac
  sleep "$POLL"
done
