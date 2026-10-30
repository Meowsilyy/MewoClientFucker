param(
    [ValidateSet('Quick','Standard','Deep')][string]$Mode = 'Standard',
    [int]$TargetPid = 0,
    [string]$InstancePath = ''
)

$ErrorActionPreference = 'Stop'
$url = 'https://raw.githubusercontent.com/Meowsilyy/MewoClientFucker/main/MewoClientFucker.ps1'
$path = Join-Path ([IO.Path]::GetTempPath()) 'MewoClientFucker.ps1'
try {
    Invoke-WebRequest -Uri $url -UseBasicParsing -OutFile $path -ErrorAction Stop
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw 'The scanner did not download.' }
    $options = @{}
    if ($PSBoundParameters.ContainsKey('Mode')) { $options.Mode = $Mode }
    if ($PSBoundParameters.ContainsKey('TargetPid')) { $options.TargetPid = $TargetPid }
    if ($PSBoundParameters.ContainsKey('InstancePath')) { $options.InstancePath = $InstancePath }
    & $path @options
    if (-not $?) { throw 'Mewo exited with an error.' }
} catch {
    Write-Host ('  Mewo launcher error: ' + $_.Exception.Message) -ForegroundColor Red
    exit 1
}
