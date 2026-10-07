#!/system/bin/sh
# set_threshold.sh <conf文件> <T_HARD> <T_RESUME> - 修改机型配置的温度阈值（标定/测试用）
CONF="$1"
[ -f "$CONF" ] || { echo "no such conf: $CONF"; exit 1; }
sed -i "s/^T_HARD=.*/T_HARD=$2/" "$CONF"
sed -i "s/^T_RESUME=.*/T_RESUME=$3/" "$CONF"
grep -E "^(T_HARD|T_RESUME)" "$CONF"
