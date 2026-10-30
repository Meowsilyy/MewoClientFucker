param(
    [ValidateSet('Quick','Standard','Deep')][string]$Mode = 'Deep'
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [Text.Encoding]::UTF8

$source = 'https://github.com/Meowsilyy/MewoClientFucker'
$officialSource = 'https://github.com/MeowTonynoh/MeowClientFucker/releases/tag/V1.1'
$officialDownload = 'https://github.com/MeowTonynoh/MeowClientFucker/releases/download/V1.1/MeowClientFucker.exe'
$officialHash = '4AFCE4998DC5A336A6C8A503869BF9331AD2DFFAE125F10F7D4DEBFD3761BD73'
$scannerUrl = 'https://raw.githubusercontent.com/Meowsilyy/MewoClientFucker/main/MewoClientFucker.ps1'
$work = Join-Path ([IO.Path]::GetTempPath()) 'MewoClientFucker'
New-Item -ItemType Directory -Path $work -Force | Out-Null

function Text([string]$Value, [string]$Color = 'Gray') {
    Write-Host $Value -ForegroundColor $Color
}

function Download([string]$Url, [string]$Destination) {
    if (Test-Path -LiteralPath $Destination) {
        Remove-Item -LiteralPath $Destination -Force
    }
    Invoke-WebRequest -Uri $Url -UseBasicParsing -OutFile $Destination -ErrorAction Stop
    if (-not (Test-Path -LiteralPath $Destination -PathType Leaf)) {
        throw 'The download did not create a file.'
    }
}

function Run-Mewo {
    Text ''
    Text '  MEWO SCANNER' 'Magenta'
    Text ('  Source: ' + $source) 'Gray'
    Text ('  Scan mode: ' + $Mode) 'White'
    if ((Read-Host '  Download and run the Mewo PowerShell scanner? [y/N]') -notmatch '^(?i:y|yes)$') {
        Text '  Skipped Mewo.' 'Yellow'
        return
    }
    $local = Join-Path $work 'MewoClientFucker.ps1'
    Download $scannerUrl $local
    & $local -Mode $Mode
    if (-not $?) { Text '  Mewo returned an error.' 'Yellow' }
}

function Run-Meow {
    Text ''
    Text '  ORIGINAL MEOW CLIENT FUCKER V1.1' 'Magenta'
    Text ('  Publisher: MeowTonynoh') 'White'
    Text ('  Release: ' + $officialSource) 'Gray'
    Text '  This is the original closed-source EXE, not Mewo code.' 'Yellow'
    Text '  It may inspect Java memory and Windows DNS cache.' 'Yellow'
    Text '  Its hash can be verified, but that does not establish it is safe.' 'Yellow'
    if ((Read-Host '  Download and run the original Meow executable? [y/N]') -notmatch '^(?i:y|yes)$') {
        Text '  Skipped official Meow.' 'Yellow'
        return
    }
    $exe = Join-Path $work 'MeowClientFucker-V1.1.exe'
    if (Test-Path -LiteralPath $exe) {
        $oldHash = (Get-FileHash -LiteralPath $exe -Algorithm SHA256).Hash
        if ($oldHash -ne $officialHash) {
            Remove-Item -LiteralPath $exe -Force
        }
    }
    if (-not (Test-Path -LiteralPath $exe)) {
        Text '  Downloading the publisher release...' 'Magenta'
        Download $officialDownload $exe
    }
    $actual = (Get-FileHash -LiteralPath $exe -Algorithm SHA256).Hash
    if ($actual -ne $officialHash) {
        Remove-Item -LiteralPath $exe -Force -ErrorAction SilentlyContinue
        throw ('Publisher release hash mismatch. Expected: ' + $officialHash + ' Found: ' + $actual)
    }
    Text '  SHA-256 matches the published V1.1 release.' 'Green'
    Text '  Opening the original Meow scanner in this terminal.' 'White'
    & $exe
    if (-not $?) { Text '  The original Meow executable returned an error.' 'Yellow' }
}

try {
    Text ''
    Text '  MEWO CLIENT FUCKER' 'Magenta'
    Text '  Minecraft screenshare toolkit' 'White'
    Text '  Built by Meowsilyy | Official Meow by Tonynoh' 'Gray'
    Text ''
    Text '  [1] Mewo + original Meow' 'White'
    Text '  [2] Mewo only' 'White'
    Text '  [3] Original Meow only' 'White'
    Text '  [4] Exit' 'White'
    $answer = Read-Host '  Choose [1]'
    if (-not $answer) { $answer = '1' }
    switch ($answer) {
        '1' {
            Run-Mewo
            Run-Meow
        }
        '2' { Run-Mewo }
        '3' { Run-Meow }
        '4' { return }
        default { throw 'Invalid choice.' }
    }
    Text ''
    Text '  Finished. Both scanners report independently.' 'Magenta'
} catch {
    Text ('  ERROR: ' + $_.Exception.Message) 'Red'
    exit 1
}
