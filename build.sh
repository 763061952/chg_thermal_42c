#!/bin/sh
# 打包成可直接刷入的 KernelSU / Magisk 模块 zip
# 用法: sh build.sh
set -e
ROOT=$(cd "$(dirname "$0")" && pwd)
ID=$(sed -n 's/^id=//p' "$ROOT/module.prop" | head -1)
VER=$(sed -n 's/^version=//p' "$ROOT/module.prop" | head -1)
OUT="$ROOT/dist/$ID-$VER.zip"
mkdir -p "$ROOT/dist"
rm -f "$OUT"
# 只有刷机需要的文件进包；说明书和打包脚本不进
cd "$ROOT"
zip -q -9 "$OUT" module.prop config.sh service.sh uninstall.sh
zip -q -9 -r "$OUT" devices
echo "已生成: $OUT"
unzip -l "$OUT" | tail -4
