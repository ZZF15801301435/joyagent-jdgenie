# JDGenie 环境检查脚本
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  JDGenie 环境检查" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 检查 Java
Write-Host "1. 检查 Java..." -ForegroundColor Yellow
try {
    $javaVersion = java -version 2>&1 | Select-String "version"
    Write-Host "   ✅ Java: $javaVersion" -ForegroundColor Green
} catch {
    Write-Host "   ❌ Java 未安装或未配置到 PATH" -ForegroundColor Red
}

# 检查 Python
Write-Host "2. 检查 Python..." -ForegroundColor Yellow
$pythonFound = $false
$pythonCmd = $null

if (Get-Command python -ErrorAction SilentlyContinue) {
    try {
        $pythonVersion = python --version 2>&1
        Write-Host "   ✅ Python: $pythonVersion" -ForegroundColor Green
        $pythonCmd = "python"
        $pythonFound = $true
    } catch {
        Write-Host "   ❌ Python 命令执行失败" -ForegroundColor Red
    }
} elseif (Get-Command python3 -ErrorAction SilentlyContinue) {
    try {
        $pythonVersion = python3 --version 2>&1
        Write-Host "   ✅ Python3: $pythonVersion" -ForegroundColor Green
        $pythonCmd = "python3"
        $pythonFound = $true
    } catch {
        Write-Host "   ❌ Python3 命令执行失败" -ForegroundColor Red
    }
} else {
    Write-Host "   ❌ Python 未安装或未配置到 PATH" -ForegroundColor Red
    Write-Host "      请访问 https://www.python.org/downloads/ 下载安装" -ForegroundColor Yellow
}

# 检查 pip
Write-Host "3. 检查 pip..." -ForegroundColor Yellow
if ($pythonFound) {
    try {
        $pipVersion = python -m pip --version 2>&1
        Write-Host "   ✅ pip: $pipVersion" -ForegroundColor Green
    } catch {
        Write-Host "   ❌ pip 未安装" -ForegroundColor Red
        Write-Host "      运行: python -m ensurepip --upgrade" -ForegroundColor Yellow
    }
} else {
    Write-Host "   ⚠️  跳过 pip 检查（Python 未安装）" -ForegroundColor Yellow
}

# 检查 uv
Write-Host "4. 检查 uv..." -ForegroundColor Yellow
if (Get-Command uv -ErrorAction SilentlyContinue) {
    try {
        $uvVersion = uv --version
        Write-Host "   ✅ uv: $uvVersion" -ForegroundColor Green
    } catch {
        Write-Host "   ❌ uv 命令执行失败" -ForegroundColor Red
    }
} else {
    Write-Host "   ❌ uv 未安装" -ForegroundColor Red
    if ($pythonFound) {
        Write-Host "      运行: python -m pip install uv" -ForegroundColor Yellow
    }
}

# 检查 genie-tool 目录
Write-Host "5. 检查 genie-tool 目录..." -ForegroundColor Yellow
$genieToolPath = "code\joyagent-jdgenie\genie-tool"
if (Test-Path $genieToolPath) {
    Write-Host "   ✅ genie-tool 目录存在" -ForegroundColor Green
    
    # 检查 .env 文件
    $envPath = Join-Path $genieToolPath ".env"
    if (Test-Path $envPath) {
        Write-Host "   ✅ .env 文件存在" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️  .env 文件不存在" -ForegroundColor Yellow
        Write-Host "      需要创建: $envPath" -ForegroundColor Yellow
    }
    
    # 检查虚拟环境
    $venvPath = Join-Path $genieToolPath ".venv"
    if (Test-Path $venvPath) {
        Write-Host "   ✅ 虚拟环境已创建" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️  虚拟环境未创建" -ForegroundColor Yellow
        Write-Host "      运行: cd $genieToolPath; uv sync" -ForegroundColor Yellow
    }
    
    # 检查 pyproject.toml
    $pyprojectPath = Join-Path $genieToolPath "pyproject.toml"
    if (Test-Path $pyprojectPath) {
        Write-Host "   ✅ pyproject.toml 存在" -ForegroundColor Green
    } else {
        Write-Host "   ❌ pyproject.toml 不存在" -ForegroundColor Red
    }
} else {
    Write-Host "   ❌ genie-tool 目录不存在" -ForegroundColor Red
    Write-Host "      路径: $genieToolPath" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  环境检查完成" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

