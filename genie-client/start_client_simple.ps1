# Genie Client 简单启动脚本（不依赖 uv 命令）
# 直接使用虚拟环境中的 Python

Set-Location $PSScriptRoot

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   Genie Client 服务启动" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 检查虚拟环境
if (-not (Test-Path ".venv")) {
    Write-Host "错误: 虚拟环境不存在，请先运行: uv venv" -ForegroundColor Red
    exit 1
}

Write-Host "启动服务..." -ForegroundColor Green
Write-Host "服务地址: http://localhost:8188" -ForegroundColor Cyan
Write-Host "API 文档: http://localhost:8188/docs" -ForegroundColor Cyan
Write-Host "健康检查: http://localhost:8188/health" -ForegroundColor Cyan
Write-Host ""
Write-Host "按 Ctrl+C 停止服务" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 直接使用虚拟环境中的 Python 运行
.venv\Scripts\python.exe server.py

