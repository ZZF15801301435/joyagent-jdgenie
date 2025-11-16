# Genie Client 启动脚本
# 在 PowerShell 中运行此脚本

Set-Location $PSScriptRoot

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   Genie Client 服务启动" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 检查虚拟环境
if (-not (Test-Path ".venv")) {
    Write-Host "创建虚拟环境..." -ForegroundColor Yellow
    uv venv
}

# 同步依赖
Write-Host "检查依赖..." -ForegroundColor Yellow
uv sync

Write-Host ""
Write-Host "启动服务..." -ForegroundColor Green
Write-Host "服务地址: http://localhost:8188" -ForegroundColor Cyan
Write-Host "API 文档: http://localhost:8188/docs" -ForegroundColor Cyan
Write-Host "健康检查: http://localhost:8188/health" -ForegroundColor Cyan
Write-Host ""
Write-Host "按 Ctrl+C 停止服务" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 重新加载 PATH 环境变量（确保 uv 可用）
$env:PATH = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# 检查 uv 是否可用
if (-not (Get-Command uv -ErrorAction SilentlyContinue)) {
    Write-Host "错误: 未找到 uv 命令" -ForegroundColor Red
    Write-Host "尝试使用完整路径..." -ForegroundColor Yellow
    $uvPath = "C:\Users\Administrator\AppData\Local\Programs\Python\Python314\Scripts\uv.exe"
    if (Test-Path $uvPath) {
        & $uvPath run python server.py
    } else {
        Write-Host "错误: 无法找到 uv，请使用虚拟环境中的 Python 直接运行" -ForegroundColor Red
        Write-Host "运行: .venv\Scripts\python.exe server.py" -ForegroundColor Yellow
        .venv\Scripts\python.exe server.py
    }
} else {
    # 启动服务
    uv run python server.py
}

