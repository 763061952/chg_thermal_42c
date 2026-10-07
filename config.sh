# 稳充（亮屏快充 + 温度保护）通用配置
#
# 机型相关参数（放开档位、温度阈值）在 devices/*.conf，按机型自动加载：
#   devices/myron.conf        Redmi K90 Pro Max（K90PM）
#   devices/2608bpx34c.conf   2608BPX34C（原作者实测机型）
# 未在表中的机型 → 安全模式：不写任何节点。

# 巡检间隔（秒）
POLL=2
