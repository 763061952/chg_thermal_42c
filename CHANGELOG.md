# 更新日志

## v5.0.0（K90PM 适配）
- 新增**机型适配表** `devices/*.conf`（按 `ro.product.device` / `ro.product.model` 匹配）
- 未适配机型进入**安全模式**：不写任何节点，仅记日志
- 新增**温度保护**（带迟滞）：`T_HARD` 交回官方、`T_RESUME` 恢复放开；
  温度连续 3 次读取失败也会保守交回官方
- 新增 **Redmi K90 Pro Max**（`myron` / `25102RKBEC`）适配：
  - 实测 `remove=1` 即可解除温控降档（官方继续写 `wired_ctrl_limit` 也不再影响功率）
  - 因此该机型 `WRITE_GEAR=0`（不写档位，避免与官方策略做无效竞争）
  - 启用 42.0℃ 交回 / 39.0℃ 恢复的温度保护
  - 完整标定数据：`calibration/k90pm/FINDINGS.md`
- 移除功率闭环（`POWER_LOOP`）：v4.1 起默认即关闭，且对 K90PM 无效（档位被驱动架空）
- 记录一个坑：`wired_ctrl_limit` 属主为 `system:system`，用 shell 用户重定向写入会静默失败，
  必须以 root 执行整条命令（`su -c "sh -c 'echo N > 节点'"`）

## v4.1.1
- 模块信息里补上项目主页与作者 GitHub（`module.prop`）
- 功能与 v4.1.0 完全相同，只是元信息更新

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
