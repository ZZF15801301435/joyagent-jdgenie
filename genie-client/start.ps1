# Windows PowerShell 启动脚本
# Genie Client 服务启动脚本

# 进入项目目录
Set-Location $PSScriptRoot

# 检查 uv 是否安装
if (-not (Get-Command uv -ErrorAction SilentlyContinue)) {
    Write-Host "错误: 未找到 uv 命令，请先安装 uv" -ForegroundColor Red
    Write-Host "安装命令: pip install uv" -ForegroundColor Yellow
    exit 1
}

# 创建虚拟环境（如果不存在）
if (-not (Test-Path ".venv")) {
    Write-Host "创建虚拟环境..." -ForegroundColor Green
    uv venv
}

# 同步依赖（如果需要）
Write-Host "检查依赖..." -ForegroundColor Green
uv sync

# 启动服务
Write-Host "启动 Genie Client 服务..." -ForegroundColor Green
Write-Host "服务地址: http://localhost:8188" -ForegroundColor Cyan
Write-Host "API 文档: http://localhost:8188/docs" -ForegroundColor Cyan
Write-Host "按 Ctrl+C 停止服务" -ForegroundColor Yellow
Write-Host ""

uv run python server.py

