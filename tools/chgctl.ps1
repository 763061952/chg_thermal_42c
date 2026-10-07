# chgctl.ps1 - K90PM 充电节点读取/写入辅助（仅标定用，不随模块分发）
param(
    [Parameter(Mandatory = $true)][ValidateSet('read', 'write', 'watch')][string]$Action,
    [string]$Node = 'wired_ctrl_limit',
    [string]$Value,
    [string]$Serial = '',
    [int]$Seconds = 0,
    [int]$IntervalMs = 2000
)

$ErrorActionPreference = 'Stop'
$S = '/sys/class/xm_power/charger/charger_thermal'
$B = '/sys/class/power_supply/battery'
$U = '/sys/class/power_supply/usb'

if (-not $Serial) {
    $devs = @(& adb devices | Select-Object -Skip 1 | Where-Object { $_ -match '\sdevice$' } | ForEach-Object { ($_ -split '\s+')[0] })
    if ($devs.Count -eq 1) { $Serial = $devs[0] }
    elseif ($devs.Count -gt 1) {
        $Serial = ($devs | Where-Object { $_ -match ':\d+$' } | Select-Object -First 1)
        if (-not $Serial) { $Serial = $devs[0] }
    } else { throw '没有已连接的设备' }
}

function Get-Remote([string]$Path) {
    $out = & adb -s $Serial shell su -c "cat $Path" 2>&1
    return ($out -join '').Trim()
}

function Set-Remote([string]$Path, [string]$Val) {
    # 必须以 root 身份整条执行（节点属主 system:system，shell 用户无法重定向）
    & adb -s $Serial shell su -c "sh -c 'echo $Val > $Path'" 2>&1 | Out-Null
}

# 电池侧功率（W）：current_now(µA) × voltage_now(µV)，双电芯按单芯报值处理
function Get-PowerW {
    $c = Get-Remote "$B/current_now"
    $v = Get-Remote "$B/voltage_now"
    if ($c -match '^-?\d+$' -and $v -match '^-?\d+$') {
        $cf = [math]::Abs([double]$c)
        $vf = [double]$v
        return [math]::Round($cf * $vf / 1e12, 2)
    }
    return 0
}

function Get-Snapshot([string]$Tag) {
    $limit = Get-Remote "$S/wired_ctrl_limit"
    $curr = Get-Remote "$S/wired_chg_curr"
    $curr2 = Get-Remote "$S/wired_chg_curr2"
    $remove = Get-Remote "$S/wired_thermal_remove"
    $status = Get-Remote "$B/status"
    $cap = Get-Remote "$B/capacity"
    $temp = Get-Remote "$B/temp"
    $uv = Get-Remote "$U/voltage_now"
    $ui = Get-Remote "$U/current_now"
    $p = Get-PowerW
    "{0,-22} limit={1,-3} curr={2,-9} curr2={3,-9} remove={4,-2} status={5,-10} cap={6,3}% temp={7,5} usb={8}mV/{9}uA P={10}W" -f `
        $Tag, $limit, $curr, $curr2, $remove, $status, $cap, $temp, $uv, $ui, $p
}

switch ($Action) {
    'read' {
        Get-Snapshot 'read'
    }
    'write' {
        if (-not $Value) { throw 'write 需要 -Value' }
        Set-Remote "$S/$Node" $Value
        Start-Sleep -Milliseconds 300
        Get-Snapshot "write $Node=$Value"
        Start-Sleep -Seconds 3
        Get-Snapshot 'verify +3s'
    }
    'watch' {
        $deadline = (Get-Date).AddSeconds($Seconds)
        do {
            Get-Snapshot (Get-Date -Format 'HH:mm:ss')
            if ((Get-Date) -lt $deadline) { Start-Sleep -Milliseconds $IntervalMs }
        } while ((Get-Date) -lt $deadline)
    }
}
