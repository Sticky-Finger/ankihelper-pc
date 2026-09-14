# release 产物冒烟测试：启动打包出的 exe，断言主窗口出现且进程稳定存活
#
# 用途：
#   - 本地：flutter build windows --release 后运行 .\tool\smoke_packaged.ps1
#   - CI：build.yml 的 Windows job 在打包 zip 前执行（缺 DLL / 资源丢失等
#     打包层回归会让窗口无法出现或进程崩溃，从而被拦下）
#
# 说明：Flutter 桌面 release 构建不暴露 Dart VM 服务，OS 层只能看到顶层
# 窗口（详见 docs/E2E_TESTING.md），因此深度 GUI 自动化不在本脚本范围，
# 由 integration_test 在源码构建层面覆盖。
param(
    [string]$ExePath = "build\windows\x64\runner\Release\ankihelper.exe",
    [int]$StartupTimeoutSec = 30,
    [int]$AliveSec = 5
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path $ExePath)) {
    Write-Error "未找到待测产物: $ExePath（先执行 flutter build windows --release）"
    exit 1
}

$exeFullPath = Resolve-Path $ExePath
Write-Host "启动产物: $exeFullPath"
$proc = Start-Process -FilePath $exeFullPath -PassThru -WorkingDirectory (Split-Path $exeFullPath)

try {
    # 1. 等待主窗口出现（轮询 MainWindowTitle，超时即失败）
    $deadline = (Get-Date).AddSeconds($StartupTimeoutSec)
    $windowTitle = $null
    while ((Get-Date) -lt $deadline) {
        Start-Sleep -Milliseconds 500
        if ($proc.HasExited) {
            Write-Error "进程提前退出（ExitCode=$($proc.ExitCode)），疑似缺少 DLL 或启动崩溃"
            exit 1
        }
        $proc.Refresh()
        if ($proc.MainWindowTitle) {
            $windowTitle = $proc.MainWindowTitle
            break
        }
    }
    if (-not $windowTitle) {
        Write-Error "${StartupTimeoutSec}s 内未出现主窗口，疑似启动挂起"
        exit 1
    }
    Write-Host "主窗口已出现: $windowTitle"

    # 2. 窗口出现后需稳定存活一段时间（捕捉启动即崩 / 持续崩溃循环）
    Start-Sleep -Seconds $AliveSec
    $proc.Refresh()
    if ($proc.HasExited) {
        Write-Error "窗口出现后 ${AliveSec}s 内进程退出（ExitCode=$($proc.ExitCode)）"
        exit 1
    }

    Write-Host "冒烟测试通过：窗口「$windowTitle」存活 ${AliveSec}s"
    exit 0
}
finally {
    if ($proc -and -not $proc.HasExited) {
        Stop-Process -Id $proc.Id -Force
    }
}
