Set-Location $PSScriptRoot

$Env:HF_HOME="huggingface"
#$Env:HF_ENDPOINT="https://hf-mirror.com"
$Env:PIP_DISABLE_PIP_VERSION_CHECK=1
$Env:PIP_NO_CACHE_DIR=1
#$Env:PIP_INDEX_URL="https://pypi.mirrors.ustc.edu.cn/simple"
#$Env:UV_INDEX_URL="https://pypi.tuna.tsinghua.edu.cn/simple/"
$Env:UV_EXTRA_INDEX_URL="https://download.pytorch.org/whl/cu124"
$Env:UV_CACHE_DIR="${env:LOCALAPPDATA}/uv/cache"
$Env:UV_NO_BUILD_ISOLATION=1
$Env:UV_NO_CACHE=0
$Env:UV_LINK_MODE="symlink"
$Env:GIT_LFS_SKIP_SMUDGE=1

function InstallFail {
    Write-Output "Install failed|安装失败。"
    Read-Host | Out-Null ;
    Exit
}

function Check {
    param (
        $ErrorInfo
    )
    if (!($?)) {
        Write-Output $ErrorInfo
        InstallFail
    }
}

# Check C drive free space with error handling
try {
    $CDrive = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='C:'" -ErrorAction Stop
    if ($CDrive) {
        $FreeSpaceGB = [math]::Round($CDrive.FreeSpace / 1GB, 2)
        Write-Host "C: drive free space: ${FreeSpaceGB}GB"
        
        # Set UV cache directory based on available space
        if ($FreeSpaceGB -lt 10) {
            Write-Host "Low disk space detected. Using local .cache directory"
            $Env:UV_CACHE_DIR=".cache"
            $Env:UV_LINK_MODE="copy"
        } 
    } else {
        Write-Warning "C: drive not found. Using local .cache directory"
        $Env:UV_CACHE_DIR=".cache"
        $Env:UV_LINK_MODE="copy"
    }
} catch {
    Write-Warning "Failed to check disk space: $_. Using local .cache directory"
    $Env:UV_CACHE_DIR=".cache"
    $Env:UV_LINK_MODE="copy"
}

try {
    ~/.local/bin/uv --version
    Write-Output "uv installed|UV模块已安装."
}
catch {
    Write-Output "Installing uv|安装uv模块中..."
    if ($Env:OS -ilike "*windows*") {
        powershell -ExecutionPolicy ByPass -c "./uv-installer.ps1"
        Check "uv install failed|安装uv模块失败。"
    }
    else {
        sh "./uv-installer.sh"
        Check "uv install failed|安装uv模块失败。"
    }
}

if ($env:OS -ilike "*windows*") {
    if (Test-Path "./venv/Scripts/activate") {
        Write-Output "Windows venv"
        . ./venv/Scripts/activate
    }
    elseif (Test-Path "./.venv/Scripts/activate") {
        Write-Output "Windows .venv"
        . ./.venv/Scripts/activate
    }else{
        Write-Output "Create .venv"
        ~/.local/bin/uv venv -p 3.10
        . ./.venv/Scripts/activate
    }
}
elseif (Test-Path "./venv/bin/activate") {
    Write-Output "Linux venv"
    . ./venv/bin/Activate.ps1
}
elseif (Test-Path "./.venv/bin/activate") {
    Write-Output "Linux .venv"
    . ./.venv/bin/activate.ps1
}
else{
    Write-Output "Create .venv"
    ~/.local/bin/uv venv -p 3.10
    . ./.venv/bin/activate.ps1
}

Write-Output "Installing main requirements"

~/.local/bin/uv pip sync requirements-uv.txt --index-strategy unsafe-best-match
Check "Install main requirements failed"

~/.local/bin/uv pip install kaolin -f https://nvidia-kaolin.s3.us-east-2.amazonaws.com/torch-2.5.1_cu124.html
Check "Install kaolin failed"

~/.local/bin/uv pip install --no-build-isolation git+https://github.com/JeffreyXiang/diffoctreerast.git
Check "Install diffoctreerast failed"

~/.local/bin/uv pip install git+https://github.com/sdbds/diff-gaussian-rasterization
Check "Install diff-gaussian-rasterization failed"

Write-Output "Install finished"
Read-Host | Out-Null ;
