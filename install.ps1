$ErrorActionPreference = "Stop"

$Repo = "dh1man-harsh/ONPAS-Downloads"
$LatestUrl = "https://raw.githubusercontent.com/dh1man-harsh/ONPAS-Downloads/main/latest.json"
$InstallRoot = Join-Path $env:LOCALAPPDATA "ONPAS"
$ConfigRoot = Join-Path $env:APPDATA "ONPAS"
$TempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("onpas-install-" + [System.Guid]::NewGuid().ToString("N"))

if ($env:OS -ne "Windows_NT") {
    throw "ONPAS Windows installer must be run on Windows."
}

New-Item -ItemType Directory -Force -Path $ConfigRoot | Out-Null
New-Item -ItemType Directory -Force -Path $TempRoot | Out-Null

try {
    $Latest = Invoke-RestMethod -Uri $LatestUrl -UseBasicParsing
    $ZipPath = Join-Path $TempRoot "ONPAS-Windows.zip"
    $ExtractRoot = Join-Path $TempRoot "extract"

    Invoke-WebRequest -Uri $Latest.windows -OutFile $ZipPath -UseBasicParsing

    if (Test-Path $InstallRoot) {
        Remove-Item -LiteralPath $InstallRoot -Recurse -Force
    }

    New-Item -ItemType Directory -Force -Path $ExtractRoot | Out-Null
    Expand-Archive -LiteralPath $ZipPath -DestinationPath $ExtractRoot -Force

    $Exe = Get-ChildItem -Path $ExtractRoot -Filter "ONPAS.exe" -Recurse | Select-Object -First 1

    if (-not $Exe) {
        throw "ONPAS.exe was not found in the downloaded package."
    }

    $AppSource = Split-Path -Parent $Exe.FullName
    New-Item -ItemType Directory -Force -Path $InstallRoot | Out-Null
    Copy-Item -Path (Join-Path $AppSource "*") -Destination $InstallRoot -Recurse -Force

    $InstalledExe = Join-Path $InstallRoot "ONPAS.exe"

    if (-not (Test-Path $InstalledExe)) {
        throw "ONPAS installation failed."
    }

    $Shell = New-Object -ComObject WScript.Shell
    $DesktopShortcut = $Shell.CreateShortcut((Join-Path ([Environment]::GetFolderPath("Desktop")) "ONPAS.lnk"))
    $DesktopShortcut.TargetPath = $InstalledExe
    $DesktopShortcut.WorkingDirectory = $InstallRoot
    $DesktopShortcut.Save()

    $Programs = [Environment]::GetFolderPath("Programs")
    $StartShortcut = $Shell.CreateShortcut((Join-Path $Programs "ONPAS.lnk"))
    $StartShortcut.TargetPath = $InstalledExe
    $StartShortcut.WorkingDirectory = $InstallRoot
    $StartShortcut.Save()

    Start-Process -FilePath $InstalledExe
    Write-Host "ONPAS $($Latest.version) installed successfully."
} finally {
    if (Test-Path $TempRoot) {
        Remove-Item -LiteralPath $TempRoot -Recurse -Force
    }
}
