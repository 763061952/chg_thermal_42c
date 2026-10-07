#!/system/bin/sh
# dump_dt.sh - 导出 mca_charger_thermal 设备树属性（只读）
DT=/proc/device-tree/soc/mca_charger_thermal
for f in wired_thermal wireless_thermal support_wireless wireless_phone_level status; do
  echo "--- $f ---"
  od -A n -t x4 $DT/$f
done
