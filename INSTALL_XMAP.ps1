[CmdletBinding()]
param(
    [string]$DistroName = "xmap-ubuntu",
    [string]$UbuntuImage = "public.ecr.aws/ubuntu/ubuntu:24.04",
    [string]$InstallRoot,
    [switch]$ForceRecreate
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$RepoRoot = Split-Path -Parent $PSCommandPath
$LogPrefix = "[xmap-install]"

if (-not $PSBoundParameters.ContainsKey("InstallRoot")) {
    $InstallRoot = Join-Path $env:LOCALAPPDATA "XMap\wsl\$DistroName"
}

function Write-Step {
    param([string]$Message)
    Write-Host "$LogPrefix $Message" -ForegroundColor Cyan
}

function Test-CommandExists {
    param([string]$Name)
    return $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
}

function Invoke-Native {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        [string[]]$Arguments = @(),
        [switch]$IgnoreExitCode
    )

    & $FilePath @Arguments
    $exitCode = $LASTEXITCODE
    if (-not $IgnoreExitCode -and $exitCode -ne 0) {
        throw "Command failed with exit code ${exitCode}: $FilePath $($Arguments -join ' ')"
    }
}

function Test-DistroExists {
    & wsl -d $DistroName -u root -- true 2>$null
    return $LASTEXITCODE -eq 0
}

function Remove-DistroIfRequested {
    if (-not $ForceRecreate) {
        return
    }

    if (-not (Test-DistroExists)) {
        return
    }

    Write-Step "Removing existing WSL distro $DistroName ..."
    & wsl --terminate $DistroName 2>$null | Out-Null
    & wsl --unregister $DistroName
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to unregister distro $DistroName."
    }
}

function Ensure-WSLAvailable {
    if (-not (Test-CommandExists "wsl")) {
        throw "wsl.exe not found. Install WSL first, then rerun INSTALL_XMAP.bat."
    }

    & wsl --status 2>$null | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw @"
WSL is not ready on this machine.

Please open an elevated terminal once and run:
  wsl --install

Then reboot if Windows asks for it, and rerun INSTALL_XMAP.bat.
"@
    }
}

function New-DistroFromDocker {
    if (-not (Test-CommandExists "docker")) {
        return $false
    }

    Write-Step "Bootstrapping $DistroName from Docker image $UbuntuImage ..."

    & docker image inspect $UbuntuImage *> $null
    if ($LASTEXITCODE -ne 0) {
        Write-Step "Pulling $UbuntuImage ..."
        Invoke-Native -FilePath "docker" -Arguments @("pull", $UbuntuImage)
    }

    $tempDir = Join-Path $env:TEMP "xmap-installer"
    $rootfsTar = Join-Path $tempDir "$DistroName-rootfs.tar"

    New-Item -ItemType Directory -Force -Path $tempDir | Out-Null

    $containerId = (& docker create $UbuntuImage).Trim()
    if (-not $containerId) {
        throw "Failed to create a temporary Docker container from $UbuntuImage."
    }

    try {
        Invoke-Native -FilePath "docker" -Arguments @("export", $containerId, "-o", $rootfsTar)
    }
    finally {
        & docker rm $containerId *> $null
    }

    if (Test-Path $InstallRoot) {
        Remove-Item -Recurse -Force $InstallRoot
    }

    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $InstallRoot) | Out-Null
    Invoke-Native -FilePath "wsl" -Arguments @("--import", $DistroName, $InstallRoot, $rootfsTar, "--version", "2")

    Remove-Item -Force $rootfsTar -ErrorAction SilentlyContinue
    return $true
}

function New-DistroFromWslInstall {
    Write-Step "Bootstrapping $DistroName with wsl --install ..."
    Write-Step "If Windows asks for elevation or a reboot, complete that first and rerun the installer."

    Invoke-Native -FilePath "wsl" -Arguments @("--install", "Ubuntu-24.04", "--name", $DistroName, "--no-launch", "--web-download")

    Start-Sleep -Seconds 5
    & wsl -d $DistroName -u root -- true 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw @"
The distro was installed, but root shell is not ready yet.

Open this once:
  wsl -d $DistroName

Let Ubuntu finish first-run setup, close it, then rerun INSTALL_XMAP.bat.
"@
    }
}

function Ensure-Distro {
    Remove-DistroIfRequested

    if (Test-DistroExists) {
        Write-Step "WSL distro $DistroName already exists."
        return
    }

    if (-not (New-DistroFromDocker)) {
        New-DistroFromWslInstall
    }

    if (-not (Test-DistroExists)) {
        throw "WSL distro $DistroName is still not available after bootstrap."
    }
}

function Convert-ToWslPath {
    param([string]$WindowsPath)

    if ($WindowsPath -match '^(?<drive>[A-Za-z]):\\(?<rest>.*)$') {
        $drive = $Matches.drive.ToLowerInvariant()
        $rest = $Matches.rest -replace '\\', '/'
        if ([string]::IsNullOrWhiteSpace($rest)) {
            return "/mnt/$drive"
        }
        return "/mnt/$drive/$rest"
    }

    throw "Could not convert Windows path to WSL path: $WindowsPath"
}

function Install-Packages {
    Write-Step "Installing build dependencies inside $DistroName ..."

    $command = @"
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y build-essential cmake libgmp3-dev gengetopt libpcap-dev flex byacc libjson-c-dev pkg-config libunistring-dev iproute2 iputils-ping net-tools
rm -rf /var/lib/apt/lists/*
"@

    Invoke-Native -FilePath "wsl" -Arguments @("-d", $DistroName, "-u", "root", "--", "sh", "-lc", $command)
}

function Build-XMap {
    Write-Step "Building xmap from $RepoRoot ..."

    $repoRootWsl = Convert-ToWslPath -WindowsPath $RepoRoot
    $command = "cd '$repoRootWsl' && cmake . && make -j`$(nproc) && make install"

    Invoke-Native -FilePath "wsl" -Arguments @("-d", $DistroName, "-u", "root", "--", "sh", "-lc", $command)
}

function Verify-XMap {
    Write-Step "Verifying xmap installation ..."
    Invoke-Native -FilePath "wsl" -Arguments @("-d", $DistroName, "-u", "root", "--", "/usr/local/sbin/xmap", "--version")
}

try {
    Write-Step "Repo root: $RepoRoot"
    Ensure-WSLAvailable
    Ensure-Distro
    Install-Packages
    Build-XMap
    Verify-XMap

    Write-Host ""
    Write-Host "Install complete." -ForegroundColor Green
    Write-Host "Next steps:" -ForegroundColor Green
    Write-Host "  1. Open $RepoRoot\OPEN_QUICK_TABLE.bat"
    Write-Host "  2. Or run $RepoRoot\xmap.bat"
    Write-Host "  3. Use menu option 7 to paste a scan command"
}
catch {
    Write-Host ""
    Write-Host "$LogPrefix Install failed." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}
