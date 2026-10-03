# 贡献指南

谢谢愿意搭把手。这个模块直接改**充电策略**，写错会让别人的电池过热，所以规矩比一般脚本严一点。

## 硬性要求（不满足直接不收）

1. **必须 fail-safe**：任何新逻辑都要保证"节点不存在 / 读不到值 / 权限不足"时**不写任何东西**并退出，
   参考现有 `[ -w "$N/wired_thermal_remove" ] || exit 1`。
2. **必须能完整交回官方**：任何新状态都要有对应的 `remove=0` + 档位还原路径；
   按钮关闭（`disable` 文件）和卸载（`uninstall.sh`）都必须能干净退出，不留守护进程。
3. **不许把机型相关常量写死在代码里**：档位范围 / 官方档 / 温度阈值都要走配置或机型表，
   未知机型必须走**保守分支**（不写或只交回官方）。
4. **不许悄悄删掉保护**：想放开更多必须显式写在 PR 描述里，并说明实测温度。

## PR 必须附的数据

- 机型（`ro.product.model` / `ro.product.device`）、系统版本（`ro.build.display.id`）、Android 版本
- 改动前后的 `wired_ctrl_limit` / `wired_thermal_remove` 实际值
- 实测功率曲线：至少覆盖放开档、官方档两点的 `current_now × voltage_now`
- 实测温度：`battery/temp`（0.1℃），以及有没有出现 `stop charge` 通断
- 日志片段：`/data/local/tmp/chg_fast.log`

## 怎么提

```sh
git checkout -b feat/你的改动
# 改动 module/ 下的文件，别改 dist/
sh build.sh            # 确保能打包
git commit -m "feat: xxx"
git push origin feat/你的改动
# 然后开 PR
```

## 特别欢迎的贡献

- 各机型的**标定数据**（这是当前最缺的，代码好写、数据难出，见 `机型适配指南.md`）
- 温度上限逻辑（ROADMAP P0）
- 机型识别 + 查表的骨架（ROADMAP P1）
