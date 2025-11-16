# JDGenie 本地启动脚本 (Windows PowerShell)
# 使用方法：在 PowerShell 中执行 .\start_local.ps1

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  JDGenie 本地启动脚本" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 检查环境
Write-Host "检查环境..." -ForegroundColor Yellow

# 检查 Java
try {
    $javaVersion = java -version 2>&1 | Select-String "version"
    Write-Host "✅ Java: $javaVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Java 未安装或未配置到 PATH" -ForegroundColor Red
    exit 1
}

# 检查 Python
$pythonCmd = $null
if (Get-Command python -ErrorAction SilentlyContinue) {
    $pythonCmd = "python"
} elseif (Get-Command python3 -ErrorAction SilentlyContinue) {
    $pythonCmd = "python3"
} elseif (Get-Command py -ErrorAction SilentlyContinue) {
    $pythonCmd = "py"
}

if ($pythonCmd) {
    $pythonVersion = & $pythonCmd --version
    Write-Host "✅ Python: $pythonVersion" -ForegroundColor Green
} else {
    Write-Host "❌ Python 未安装或未配置到 PATH" -ForegroundColor Red
    exit 1
}

# 检查 .env 文件
$envFile = "genie-tool\.env"
if (Test-Path $envFile) {
    Write-Host "✅ .env 文件已存在" -ForegroundColor Green
} else {
    Write-Host "❌ .env 文件不存在，请先创建" -ForegroundColor Red
    Write-Host "   位置: genie-tool\.env" -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  启动服务（需要 3 个终端窗口）" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 获取当前目录
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptDir

Write-Host "1. 启动工具服务 (genie-tool) - 端口 1601" -ForegroundColor Yellow
Write-Host "   命令: cd genie-tool; uv run python server.py" -ForegroundColor Gray
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$scriptDir\genie-tool'; Write-Host '启动工具服务...' -ForegroundColor Green; uv run python server.py"

Start-Sleep -Seconds 3

Write-Host "2. 启动后端服务 (genie-backend) - 端口 8080" -ForegroundColor Yellow
Write-Host "   命令: cd genie-backend; sh build.sh; sh start.sh" -ForegroundColor Gray
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$scriptDir\genie-backend'; Write-Host '编译后端...' -ForegroundColor Green; sh build.sh; Write-Host '启动后端服务...' -ForegroundColor Green; sh start.sh"

Start-Sleep -Seconds 5

Write-Host "3. 启动前端服务 (ui) - 端口 3000" -ForegroundColor Yellow
Write-Host "   命令: cd ui; pnpm dev" -ForegroundColor Gray
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$scriptDir\ui'; Write-Host '启动前端服务...' -ForegroundColor Green; pnpm dev"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  服务启动中..." -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "✅ 已打开 3 个终端窗口，分别启动以下服务：" -ForegroundColor Green
Write-Host "   - 工具服务: http://localhost:1601" -ForegroundColor White
Write-Host "   - 后端服务: http://localhost:8080" -ForegroundColor White
Write-Host "   - 前端服务: http://localhost:3000" -ForegroundColor White
Write-Host ""
Write-Host "等待服务启动完成后，在浏览器中访问: http://localhost:3000" -ForegroundColor Yellow
Write-Host ""
Write-Host "按 Ctrl+C 可以停止各个服务" -ForegroundColor Gray

