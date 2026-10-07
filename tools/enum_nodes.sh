#!/system/bin/sh
# enum_nodes.sh - 枚举 xm_power 全部子节点（只读）
for d in /sys/class/xm_power/*/; do
  echo "## $d"
  ls "$d"
done
