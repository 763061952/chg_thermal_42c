# 稳充（亮屏快充 + 功率闭环）配置       酷安@happier2
#
# 思路：不去跟驱动抢限流（ibat_limit / charge_control_limit / constant_charge_current
#       都会被驱动按真实温度改回或直接拒绝），而是用厂商自己的档位 wired_ctrl_limit
#       当控制量 —— 它写得进、也站得住。
#
# POWER_LOOP=1 时每 POLL 秒读一次电池侧功率（current_now × voltage_now），
# 高于目标就收紧一档、低于目标就放松一档，把功率稳在 TARGET_W 附近，
# 避免"冲高 → 电芯过热 → 被驱动 stop charge"的 0↔43W 通断。

# ---------- 功率闭环 ----------
POWER_LOOP=0        # 0=不闭环：充电期间恒定用放开档（默认，追求最快）
                    # 1=闭环：把功率稳在 TARGET_W 附近
TARGET_W=40         # 仅 POWER_LOOP=1 时有效：目标功率（W）
TOL_HI=2            # 高于 TARGET_W+TOL_HI 就收紧一档
TOL_LO=4            # 低于 TARGET_W-TOL_LO 就放松一档
STEP_EVERY=3        # 每 N 次巡检才允许动一档（防抖）

# ---------- 厂商档位 ----------
# 注意：档位取值范围因机型而异，必须按机型实测标定，详见 docs/机型适配指南.md
GEAR_MIN=3          # 最放开档（本机实测峰值 38~43W）
GEAR_MAX=12         # 最保守档（= 官方档，本机实测 9~25W）
STOCK_GEAR=12       # 未充电 / 按钮关闭时交回官方的档位

# ---------- 巡检 ----------
POLL=2              # 巡检间隔（秒）
