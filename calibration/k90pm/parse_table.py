"""解析 mca_charger_thermal 的 wired_thermal / wireless_thermal 设备树表。

od -t x4 在 little-endian 设备上输出的十六进制字符串是字节序反转的，
例如 "6c070000" 实际值 = 0x0000076c = 1900。
"""
import re
import sys
from pathlib import Path


def load_values(path: Path) -> list[int]:
    text = path.read_text(encoding="utf-8", errors="ignore")
    raw = re.findall(r"\b[0-9a-fA-F]{8}\b", text)
    values = []
    for h in raw:
        b = bytes.fromhex(h)
        values.append(int.from_bytes(b, "little"))
    return values


def show_matrix(values: list[int], cols: int, label: str) -> None:
    print(f"== {label}: {len(values)} values, {cols} cols ==")
    if len(values) % cols:
        print(f"   (not divisible by {cols})")
    for i in range(0, len(values), cols):
        row = values[i : i + cols]
        print(f"row {i // cols:2d}: " + " ".join(f"{v:6d}" for v in row))
    print()


def main() -> None:
    base = Path(__file__).parent
    text = (base / "dt_charger_thermal.txt").read_text(encoding="utf-8", errors="ignore")

    wired_part = text.split("--- wired_thermal ---")[1].split("--- wireless_thermal ---")[0]
    wired_file = base / "_wired.txt"
    wired_file.write_text(wired_part, encoding="utf-8")
    wired = load_values(wired_file)

    wireless_part = text.split("--- wireless_thermal ---")[1].split("--- support_wireless ---")[0]
    wireless_file = base / "_wireless.txt"
    wireless_file.write_text(wireless_part, encoding="utf-8")
    wireless = load_values(wireless_file)

    print(f"wired: {len(wired)} values, bytes={len(wired) * 4}")
    print(f"wireless: {len(wireless)} values, bytes={len(wireless) * 4}")
    print()

    show_matrix(wired, 10, "wired_thermal 15x10")
    show_matrix(wireless, 11, "wireless_thermal 15x11")


if __name__ == "__main__":
    sys.exit(main())
