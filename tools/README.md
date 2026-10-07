# 标定工具（不随模块打包）

配合 `机型适配指南.md` 使用。设备端脚本先 `adb push` 到 `/data/local/tmp/`，再用
`adb shell su -c 'sh /data/local/tmp/<脚本>'` 执行（必须以 root 执行整条脚本）。

## 设备端

| 脚本 | 用途 |
|---|---|
| `observe.sh [时长] [间隔]` | 只读采样充电状态（功率/温度/档位），日志存 `/data/local/tmp/chg_calib/` |
| `set_threshold.sh <conf> <T_HARD> <T_RESUME>` | 修改机型配置的温度阈值（标定/测试） |
| `dump_dt.sh` | 导出 `mca_charger_thermal` 设备树属性（od 十六进制，600B 表用） |
| `enum_nodes.sh` | 枚举 `xm_power` 全部子节点 |
| `probe_k90pm.sh` | 节点可写性诊断：权限 + 写入测试 + 自动恢复 |
| `map_test.sh` | 写不同 `wired_ctrl_limit` 值，观察联动节点 |
| `hold_test.sh` | 写入 `limit=5` 后跟踪 20 秒，验证是否被官方改回 |
| `exp_hold_fast.sh [时长]` | 单次写 `remove=1 + limit=0`，观察官方是否降档（K90PM 关键实验） |
| `restore_remove.sh` | 写回 `remove=0` 并跟踪读回值 |
| `test_write_one.sh` | 诊断 `remove=1` 写入是否保持（排除权限/引号问题） |

## Windows 端（pwsh）

```powershell
pwsh tools/chgctl.ps1 -Action read                          # 读一次
pwsh tools/chgctl.ps1 -Action watch -Seconds 120 -IntervalMs 2000   # 连续观察
pwsh tools/chgctl.ps1 -Action write -Node wired_thermal_remove -Value 1
```

多设备时加 `-Serial <序列号或 ip:5555>`（默认自动挑无线设备）。

## 重要提醒

`wired_ctrl_limit` 属主是 `system:system`，用 shell 用户直接重定向写入会**静默失败**。
所有写入务必走 `su -c 'sh <脚本>'` 形式（脚本内部的重定向才是 root 权限）。
这是本次标定踩过的最大的坑，详见 `calibration/k90pm/FINDINGS.md` §1。
