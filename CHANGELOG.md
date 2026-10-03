# 更新日志

## v4.1.0
- 默认 `POWER_LOOP=0`：充电期间恒定使用放开档，不再做任何功率限制（要的就是最快）
- 配置项整理到 `config.sh`，`POLL` 显式化
- 首次开源（仓库：https://github.com/763061952/chg_thermal_42c）
- 许可由 MIT 改为 **GPL-3.0**：衍生作品必须同样开源

## v4.0（稳充）
- 新增功率闭环：每 `STEP_EVERY` 次巡检按 `current_now × voltage_now` 调一档，
  把功率稳在 `TARGET_W` 附近，避免 0↔43W 通断
- 档位限制在 `[GEAR_MIN, GEAR_MAX]`，绝不比 v3.6 更放开

## v3.6（亮屏快充）
- 基础版本：充电中写 `wired_thermal_remove=1` + 放开档 `wired_ctrl_limit=3`
- 未充电 / 按钮关闭时交回官方档（`remove=0` + `limit=12`）

> 更早的版本记录作者未整理，欢迎补充。
