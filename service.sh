#!/system/bin/sh
# ============================================================
#  稳充 v5.0   作者：酷安@happier2
#  = 亮屏快充（remove=1）+ 温度保护 + 机型适配表
#  ----------------------------------------------------------
#  逻辑：
#    ① 机型识别（ro.product.device / ro.product.model）→ devices/*.conf
#       未知机型 → 安全模式：不写任何节点，仅记日志（绝不乱写）
#    ② 充电中：remove=1（解除官方温控降档）
#       - 支持档位的机型写放开档；K90PM 实测 limit 被驱动架空，故不写
#    ③ 温度保护（带迟滞）：temp >= T_HARD 交回官方；temp <= T_RESUME 重新放开
#       - T_HARD=0 表示该机型未标定温度，关闭保护（保持 v4.1 行为）
#    ④ 未充电 / 按钮关闭：remove=0 交回官方
#  安全：只写厂商自己的充电节点；节点不存在直接退出。
#  K90PM 标定数据见 calibration/k90pm/FINDINGS.md
# ============================================================
MODDIR=${0%/*}
[ -f "$MODDIR/config.sh" ] && . "$MODDIR/config.sh"
: "${POLL:=2}"

N=/sys/class/xm_power/charger/charger_thermal
B=/sys/class/power_supply/battery
LOG=/data/local/tmp/chg_fast.log
PIDF=/data/local/tmp/chg_fast.pid
PIDF2=/data/local/tmp/chg_thermal.pid

[ -w "$N/wired_thermal_remove" ] || exit 1

# ---------- 单实例 ----------
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

log(){ echo "[chg_fast] $(date '+%m-%d %H:%M:%S') $*" >> "$LOG"; }

until [ "$(getprop sys.boot_completed)" = "1" ]; do sleep 2; done
sleep 6

# ---------- 机型识别 ----------
DEV=$(getprop ro.product.device 2>/dev/null)
MODEL=$(getprop ro.product.model 2>/dev/null)
DEVICE_LABEL="未知机型 (${DEV}/${MODEL})"
SUPPORTED=0
OPEN_GEAR=""
STOCK_GEAR=""
WRITE_GEAR=0
T_HARD=0
T_RESUME=0

for f in "$MODDIR"/devices/*.conf; do
  [ -f "$f" ] || continue
  DEVICE_ID=""; DEVICE_MODEL=""; DEVICE_LABEL=""
  SUPPORTED=0; OPEN_GEAR=""; STOCK_GEAR=""; WRITE_GEAR=0
  T_HARD=0; T_RESUME=0
  . "$f"
  match=0
  [ -n "$DEVICE_ID" ] && [ "$DEVICE_ID" = "$DEV" ] && match=1
  [ "$match" = 0 ] && [ -n "$DEVICE_MODEL" ] && [ "$DEVICE_MODEL" = "$MODEL" ] && match=1
  [ "$match" = 1 ] && break
done

[ -z "$DEVICE_LABEL" ] && DEVICE_LABEL="未知机型 (${DEV}/${MODEL})"

# ---------- 工具 ----------
restore_once(){
  echo 0 > "$N/wired_thermal_remove" 2>/dev/null
  [ "$WRITE_GEAR" = "1" ] && [ -n "$STOCK_GEAR" ] && echo "$STOCK_GEAR" > "$N/wired_ctrl_limit" 2>/dev/null
}
put_open_gear(){
  [ "$WRITE_GEAR" = "1" ] && [ -n "$OPEN_GEAR" ] && echo "$OPEN_GEAR" > "$N/wired_ctrl_limit" 2>/dev/null
}
# 读温度（0.1℃）；读不到输出空串
read_temp(){
  t=$(cat "$B/temp" 2>/dev/null)
  case "$t" in ''|*[!0-9]*) echo "" ;; *) echo "$t" ;; esac
}

# ---------- 主循环 ----------
log "=== v5.0 启动 pid=$$ 机型=${DEVICE_LABEL} 支持=${SUPPORTED} 温度保护=${T_HARD:-0}/${T_RESUME:-0} 档位写入=${WRITE_GEAR} ==="

hot=0        # 1 = 温度保护生效中（交回官方）
mode=""
tfail=0      # 连续读取温度失败次数

while true; do
  if [ -f "$MODDIR/disable" ]; then
    restore_once
    log "按钮关闭 → 已交回官方（remove=0），守护退出"
    rm -f "$PIDF" "$PIDF2"
    exit 0
  fi

  if [ "$SUPPORTED" != "1" ]; then
    if [ "$mode" != "unsupported" ]; then
      log "机型未适配（${DEVICE_LABEL}）→ 安全模式：不写任何节点。如需适配请参考 机型适配指南.md"
      mode="unsupported"
    fi
    sleep "$POLL"
    continue
  fi

  st=$(cat "$B/status" 2>/dev/null)
  case "$st" in
    Charging|Full)
      temp=$(read_temp)
      if [ -z "$temp" ]; then
        tfail=$((tfail+1))
      else
        tfail=0
      fi

      # 温度迟滞状态机（T_HARD>0 时启用）
      if [ "$T_HARD" -gt 0 ]; then
        if [ "$tfail" -ge 3 ]; then
          if [ "$hot" != "1" ]; then
            hot=1
            restore_once
            log "连续 3 次读不到温度 → 交回官方（保守）"
          fi
        elif [ -n "$temp" ] && [ "$temp" -ge "$T_HARD" ]; then
          if [ "$hot" != "1" ]; then
            hot=1
            restore_once
            log "温度 ${temp}(0.1℃) ≥ 上限 ${T_HARD} → 交回官方降温"
          fi
        elif [ -n "$temp" ] && [ "$temp" -le "$T_RESUME" ]; then
          hot=0
        fi
      else
        hot=0
      fi

      if [ "$hot" = "1" ]; then
        if [ "$mode" != "hot" ]; then
          log "温度保护中：等待降温到 ${T_RESUME}(0.1℃) 后恢复"
          mode="hot"
        fi
      else
        echo 1 > "$N/wired_thermal_remove" 2>/dev/null
        put_open_gear
        if [ "$mode" != "fast" ]; then
          log "亮屏快充已生效：remove=1 放开档=${OPEN_GEAR:-跳过} 温度=${temp:-NA}"
          mode="fast"
        fi
      fi
      ;;
    *)
      if [ "$mode" != "idle" ]; then
        restore_once
        log "未充电 → 交回官方 (remove=0)"
        mode="idle"
        hot=0
        tfail=0
      fi
      ;;
  esac
  sleep "$POLL"
done
