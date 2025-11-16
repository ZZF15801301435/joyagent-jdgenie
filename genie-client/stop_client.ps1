# 停止占用端口 8188 的进程

Write-Host "查找占用端口 8188 的进程..." -ForegroundColor Yellow

$connection = Get-NetTCPConnection -LocalPort 8188 -ErrorAction SilentlyContinue
if ($connection) {
    $pid = $connection.OwningProcess
    $process = Get-Process -Id $pid -ErrorAction SilentlyContinue
    
    if ($process) {
        Write-Host "找到进程: $($process.ProcessName) (PID: $pid)" -ForegroundColor Cyan
        Write-Host "路径: $($process.Path)" -ForegroundColor Cyan
        
        Write-Host ""
        Write-Host "正在停止进程..." -ForegroundColor Yellow
        Stop-Process -Id $pid -Force
        Start-Sleep -Seconds 2
        
        # 验证是否已停止
        $check = Get-NetTCPConnection -LocalPort 8188 -ErrorAction SilentlyContinue
        if (-not $check) {
            Write-Host "进程已成功停止，端口 8188 已释放" -ForegroundColor Green
        } else {
            Write-Host "警告: 进程可能仍在运行" -ForegroundColor Red
        }
    } else {
        Write-Host "无法获取进程信息" -ForegroundColor Red
    }
} else {
    Write-Host "端口 8188 未被占用" -ForegroundColor Green
}

