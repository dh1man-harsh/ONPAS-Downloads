$ErrorActionPreference = "Stop"

$Repo = "dh1man-harsh/ONPAS-Downloads"
$LatestUrl = "https://raw.githubusercontent.com/dh1man-harsh/ONPAS-Downloads/main/latest.json"
$ConfigRoot = Join-Path $env:LOCALAPPDATA "ONPAS"
$TempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("onpas-install-" + [System.Guid]::NewGuid().ToString("N"))

if ($env:OS -ne "Windows_NT") {
    throw "ONPAS Windows installer must be run on Windows."
}

New-Item -ItemType Directory -Force -Path $ConfigRoot | Out-Null
New-Item -ItemType Directory -Force -Path $TempRoot | Out-Null

try {
    $Latest = Invoke-RestMethod -Uri $LatestUrl -UseBasicParsing
    $SetupPath = Join-Path $TempRoot "ONPASSetup.exe"

    Invoke-WebRequest -Uri $Latest.windows -OutFile $SetupPath -UseBasicParsing

    $Process = Start-Process -FilePath $SetupPath -ArgumentList "/VERYSILENT", "/NORESTART", "/CLOSEAPPLICATIONS" -Wait -PassThru

    if ($Process.ExitCode -ne 0) {
        throw "ONPAS setup failed with exit code $($Process.ExitCode)."
    }
    Write-Host "ONPAS $($Latest.version) installed successfully."
} finally {
    if (Test-Path $TempRoot) {
        Remove-Item -LiteralPath $TempRoot -Recurse -Force
    }
}
