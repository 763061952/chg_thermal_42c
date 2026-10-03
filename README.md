# 亮屏快充 · 稳充（chg_thermal_42c）

> 小米 / 红米 HyperOS 充电模块：解除有线充电的温控降档，用**厂商自己的档位**当控制量，
> 把亮屏充电功率稳在可用区间，避免"冲高 → 过热 → 被停充"的反复通断。

作者：酷安@happier2（GitHub [@763061952](https://github.com/763061952)）｜ 许可：**GPL-3.0** ｜ 适配：有 `xm_power` 节点的机型（HyperOS）

---

## 它解决什么问题

实测现象：亮屏快充放开后功率会冲到 **~43W**，把电芯顶到 **47~49℃**，驱动按 JEITA 直接 `stop charge`
→ 掉到 **~10W**，凉下来再放开 → **0↔43W 大约 20 秒一轮，平均只有 ~25W**。

软件侧限流全试过：`ibat_limit` / `charge_control_limit` / `constant_charge_current` ——
**驱动会立刻改回，或者干脆不接受**。最后发现只有厂商自己的档位 `wired_ctrl_limit` 写得进、也站得住。

## 原理

控制的节点：`/sys/class/xm_power/charger/charger_thermal/`

| 节点 | 作用 | 本模块是否使用 |
|---|---|---|
| `wired_thermal_remove` | `1` = 解除有线充电的温控降档；`0` = 交回官方 | ✅ 使用 |
| `wired_ctrl_limit` | 厂商充电档位（**数值越大越保守**，范围因机型而异） | ✅ 使用 |
| `wired_chg_curr` / `wired_chg_curr2` | 更细的直接电流旋钮 | ⬜ 未使用（见路线图） |
| `wireless_*` | 无线充电对应的两个节点 | ⬜ 未使用 |

`service.sh` 每 `POLL` 秒读一次 `battery/status`：

```
Charging / Full  →  wired_thermal_remove=1
                    档位 = GEAR_MIN（放开，默认）  或  闭环调节到 TARGET_W 附近
其它状态         →  wired_thermal_remove=0 + 档位回 STOCK_GEAR   ← 交回官方
```

功率反馈量取电池侧：`battery/current_now × battery/voltage_now`（µA × µV ÷ 1e12 = W）。

## 安装

1. 下载 `dist/chg_thermal_42c-v4.1.1.zip`（或自己 `sh build.sh` 打包）
2. KernelSU / Magisk 里刷入，重启
3. 看日志：`/data/local/tmp/chg_fast.log`

## 配置（`config.sh`）

| 键 | 默认 | 说明 |
|---|---|---|
| `POWER_LOOP` | `0` | `0` = 充电期间恒定用放开档（追求最快）；`1` = 闭环，把功率稳在 `TARGET_W` |
| `TARGET_W` | `40` | 仅闭环时有效：目标功率（W） |
| `TOL_HI` / `TOL_LO` | `2` / `4` | 高于 / 低于目标多少才动档位 |
| `STEP_EVERY` | `3` | 每几次巡检才允许动一档（防抖） |
| `GEAR_MIN` | `3` | 最放开档（**本机实测值**，换机型必须重标） |
| `GEAR_MAX` | `12` | 最保守档 |
| `STOCK_GEAR` | `12` | 未充电 / 按钮关闭时交回官方的档位 |
| `POLL` | `2` | 巡检间隔（秒） |

改完不用重刷：重启生效，或杀掉守护进程让它重新拉起（`kill $(cat /data/local/tmp/chg_fast.pid)`）。

## 关闭 / 卸载

- **临时关闭**：在模块目录建一个 `disable` 文件（KernelSU 里就是点按钮）→ 守护 2 秒内交回官方并退出
- **卸载**：`uninstall.sh` 会自动停守护 → `wired_thermal_remove=0` → 档位交回 → 清日志

⚠️ **"零残留"的准确含义**：本模块只是**停止写入**，节点随后由官方充电策略接管。
官方会按它自己的逻辑改写 `wired_ctrl_limit`（实测本机交回后官方写成 `8`，而我们写的是 `12`），
所以**不要指望卸载后节点值一定等于 `STOCK_GEAR`**。

## 已知限制（重要，先看这里）

1. **本版本不参与温度判定**。充电期间只要 `status` 是 `Charging/Full` 就一直保持放开档，
   **没有温度上限**，电芯保护完全依赖原厂驱动。想加自定义温度上限 → 见 `ROADMAP.md` P0。
2. **档位含义因机型而异**。`GEAR_MIN=3` / `STOCK_GEAR=12` 是本机（2608BPX34C）实测标定出来的，
   **不能直接套用到别的机型**，否则可能写了更放开的值。标定方法见 `机型适配指南.md`。
3. **节点不存在会直接退出**（`[ -w ... ] || exit 1`），不会在不支持的机型上乱写。
4. 历史遗留：早期版本把温度档位表放在 `/data/adb/fastcharge.conf`，**当前 `service.sh` 并不读它**。
   如果你机器上有这个文件，它是无效的，别被它误导。

## 支持机型

| 机型 | 系统 | GEAR_MIN | GEAR_MAX | STOCK_GEAR | 实测 |
|---|---|---|---|---|---|
| 2608BPX34C | HyperOS / Android 17 | 3 | 12 | 12 | 放开 38~43W ／ 官方 9~25W |
| *（你的机型）* | | | | | 按 `机型适配指南.md` 标定后欢迎 PR |

## 路线图

见 [`ROADMAP.md`](ROADMAP.md)：温度上限 → 机型适配表 → 自定义功率档 → 120W 双电芯适配 → WebUI。

## 贡献

见 [`CONTRIBUTING.md`](CONTRIBUTING.md)。**改充电策略的 PR 必须附实测数据**，否则不收。

- 问题 / 建议 / 机型标定数据 → 开 [Issue](https://github.com/763061952/chg_thermal_42c/issues)
- 代码改动 → Fork 后提 PR

## 免责声明

本模块会解除原厂的一部分充电保护逻辑，让电池工作在更高温度下。
高温加速电池衰减，极端情况有鼓包 / 热失控风险。
请自行评估，作者不对任何后果负责；出问题先断电、长按电源键重启。

## 许可

[GPL-3.0](LICENSE) © 2026 酷安@happier2

本程序是自由软件：你可以按自由软件基金会发布的 **GNU 通用公共许可证第 3 版**（或任何更新版本）
的条款重新发布和/或修改它。本程序按"有用但不作任何担保"发布，详见 [LICENSE](LICENSE)。

**衍生作品必须同样以 GPL-3.0 开源**——不允许闭源分发或闭源二次打包。
