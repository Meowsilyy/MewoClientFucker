param(
    [ValidateSet('Quick','Standard','Deep')][string]$Mode = 'Standard',
    [string]$InstancePath = '',
    [string]$OutputDirectory = '',
    [int]$ProcessId = 0,
    [switch]$SelfTest
)

$ErrorActionPreference = 'Stop'
$script:ModeWasProvided = $PSBoundParameters.ContainsKey('Mode')
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$script:Version = '0.6.0'
$script:Findings = [System.Collections.Generic.List[object]]::new()
$script:Mods = [System.Collections.Generic.List[object]]::new()
$script:Modules = [System.Collections.Generic.List[object]]::new()
$script:Runtime = [System.Collections.Generic.List[object]]::new()
$script:Timeline = [System.Collections.Generic.List[object]]::new()
$script:Coverage = [System.Collections.Generic.List[object]]::new()
$script:SessionId = [guid]::NewGuid().ToString('N')
$script:Started = [datetime]::UtcNow
$script:Rules = @(
    @{ id = 'meteor'; label = 'Meteor Client'; path = '(?i)(^|/)meteordevelopment/meteorclient/'; name = '(?i)(^|[-_. ])meteor([-_. ]|$)' },
    @{ id = 'wurst'; label = 'Wurst Client'; path = '(?i)(^|/)net/wurstclient/'; name = '(?i)(^|[-_. ])wurst([-_. ]|$)' },
    @{ id = 'liquidbounce'; label = 'LiquidBounce'; path = '(?i)(^|/)net/ccbluex/liquidbounce/'; name = '(?i)liquidbounce' },
    @{ id = 'bleachhack'; label = 'BleachHack'; path = '(?i)(^|/)org/bleachhack/'; name = '(?i)bleachhack' },
    @{ id = 'thunderhack'; label = 'ThunderHack'; path = '(?i)(^|/)(thunder/hack|thunderhack)/'; name = '(?i)thunderhack' },
    @{ id = 'rusherhack'; label = 'RusherHack'; path = '(?i)(^|/)org/rusherhack/'; name = '(?i)rusherhack' },
    @{ id = 'forgehax'; label = 'ForgeHax'; path = '(?i)(^|/)dev/fiki/forgehax/'; name = '(?i)forgehax' },
    @{ id = 'kamikblue'; label = 'KAMI Blue'; path = '(?i)(^|/)me/zeroeightsix/kami/'; name = '(?i)(kami[-_. ]?blue|kamiblue)' },
    @{ id = 'lambda'; label = 'Lambda'; path = '(?i)(^|/)com/lambda/client/'; name = '(?i)(^|[-_. ])lambda([-_. ]|$)' },
    @{ id = 'mathax'; label = 'MatHax'; path = '(?i)(^|/)xyz/mathax/mathaxclient/'; name = '(?i)mathax' },
    @{ id = 'aristois'; label = 'Aristois'; path = '(?i)(^|/)me/deftware/'; name = '(?i)aristois' }
)

$script:ModuleNames = [ordered]@{
    'Combat' = @('killaura','aimassist','triggerbot','silentaim','bowaimbot','maceaura','w-tap','shielddisabler')
    'Crystal' = @('autocrystal','crystalaura','crystaloptimizer','doubleanchor','anchorexploder','autodtap','autohitcrystal')
    'Totem' = @('autototem','totemoffhand','hovertotem','forceretotem','autoretotem')
    'Movement' = @('fastbridge','bridgeassist','fastplace','nofall','inventorymove','elytraglide')
    'Automation' = @('autoclicker','autopot','autoxp','autoarmor','autotool','automine','cheststealer','autorestock')
    'ESP' = @('playeresp','storageesp','entityesp','xray','targethud')
}
$script:ModuleIndex = @{}
foreach ($category in $script:ModuleNames.Keys) {
    foreach ($name in $script:ModuleNames[$category]) {
        $script:ModuleIndex[$name] = $category
    }
}

function Say([string]$Message, [string]$Color = 'Gray') {
    Write-Host $Message -ForegroundColor $Color
}

function Section([string]$Title) {
    Write-Host ''
    Say ('  ' + ('─' * 61)) 'DarkMagenta'
    Say ('  ' + $Title.ToUpperInvariant()) 'Magenta'
}

function Banner {
    try { & "$env:SystemRoot\System32\chcp.com" 65001 > $null } catch {}
    try { Clear-Host } catch {}
    $art = @'
  ███╗   ███╗███████╗██╗    ██╗ ██████╗
  ████╗ ████║██╔════╝██║    ██║██╔═══██╗
  ██╔████╔██║█████╗  ██║ █╗ ██║██║   ██║
  ██║╚██╔╝██║██╔══╝  ██║███╗██║██║   ██║
  ██║ ╚═╝ ██║███████╗╚███╔███╔╝╚██████╔╝
  ╚═╝     ╚═╝╚══════╝ ╚══╝╚══╝  ╚═════╝

  ██████╗██╗     ██╗███████╗███╗   ██╗████████╗
 ██╔════╝██║     ██║██╔════╝████╗  ██║╚══██╔══╝
 ██║     ██║     ██║█████╗  ██╔██╗ ██║   ██║
 ██║     ██║     ██║██╔══╝  ██║╚██╗██║   ██║
 ╚██████╗███████╗██║███████╗██║ ╚████║   ██║
  ╚═════╝╚══════╝╚═╝╚══════╝╚═╝  ╚═══╝   ╚═╝

 ███████╗██╗   ██╗ ██████╗██╗  ██╗███████╗██████╗
 ██╔════╝██║   ██║██╔════╝██║ ██╔╝██╔════╝██╔══██╗
 █████╗  ██║   ██║██║     █████╔╝ █████╗  ██████╔╝
 ██╔══╝  ██║   ██║██║     ██╔═██╗ ██╔══╝  ██╔══██╗
 ██║     ╚██████╔╝╚██████╗██║  ██╗███████╗██║  ██║
 ╚═╝      ╚═════╝  ╚═════╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝
'@
    Say $art 'Magenta'
    Say '                  /\_/\      ' 'DarkMagenta'
    Say '                 ( o.o )     ' 'DarkMagenta'
    Say '                  > ^ <      ' 'DarkMagenta'
    Say ('           Mewo v' + $script:Version + '  |  Made by Meowsilyy') 'Magenta'
    Say '    Inspired by Meow Client Fucker (Tonynoh) and Yarp' 'DarkGray'
    Say ('  ' + ('─' * 61)) 'DarkMagenta'
    Say ('  ' + $Mode.ToUpperInvariant() + ' MODE    |    LOCAL INSPECTION    |    READ-ONLY') 'White'
}

function Stage([int]$Step, [int]$Total, [string]$Label) {
    Say ('  [{0}/{1}] {2}' -f $Step, $Total, $Label) 'Magenta'
}

function ScanProgress([int]$Done, [int]$Total, [string]$Label) {
    if ($Total -le 0) { return }
    $filled = [int][Math]::Floor(28 * $Done / $Total)
    $percent = [int][Math]::Floor(100 * $Done / $Total)
    $bar = ('█' * $filled) + ('░' * (28 - $filled))
    Say ('  {0} {1}%  ({2}/{3} {4})' -f $bar, $percent, $Done, $Total, $Label) 'Magenta'
}

function Private-Path([string]$Value) {
    if (-not $Value) { return '' }
    $homeDir = [Environment]::GetFolderPath('UserProfile')
    if ($homeDir -and $Value.StartsWith($homeDir, [StringComparison]::OrdinalIgnoreCase)) {
        return '~' + $Value.Substring($homeDir.Length)
    }
    return $Value
}

function Finding([string]$Level, [string]$Category, [string]$Title, [string]$Details, [string]$RuleId = '', [string]$Evidence = '') {
    $script:Findings.Add([pscustomobject]@{
        level = $Level
        category = $Category
        title = $Title
        detail = $Details
        ruleId = $RuleId
        evidence = $Evidence
        confidence = switch ($Level) { 'Indicator' { 'Medium' } 'Review' { 'Low' } default { 'NotApplicable' } }
    })
    $color = switch ($Level) { 'Indicator' { 'Yellow' } 'Review' { 'DarkYellow' } default { 'Gray' } }
    Say ('  [{0}] {1}: {2}' -f $Level.ToUpperInvariant(), $Title, $Details) $color
}

function Covered([string]$Name, [string]$State, [string]$Reason) {
    $script:Coverage.Add([pscustomobject]@{ check = $Name; status = $State; explanation = $Reason })
}

function Instance-At([string]$Candidate) {
    if (-not $Candidate) { return '' }
    $candidatePath = [Environment]::ExpandEnvironmentVariables($Candidate.Trim(' ', '"', "'"))
    if (-not (Test-Path -LiteralPath $candidatePath -PathType Container)) { return '' }
    $options = @($candidatePath, (Join-Path $candidatePath '.minecraft'), (Join-Path $candidatePath 'minecraft'), (Join-Path $candidatePath 'game'))
    if ((Split-Path $candidatePath -Leaf) -ieq 'mods') { $options = @((Split-Path $candidatePath -Parent)) + $options }
    foreach ($path in $options) {
        if ((Test-Path -LiteralPath (Join-Path $path 'mods') -PathType Container) -or (Test-Path -LiteralPath (Join-Path $path 'logs') -PathType Container) -or (Test-Path -LiteralPath (Join-Path $path 'versions') -PathType Container)) {
            try { return (Get-Item -LiteralPath $path).FullName } catch {}
        }
    }
    return ''
}

function Game-Directory([string]$CommandLine) {
    if ($CommandLine -match '--gameDir\s+"([^"]+)"') { return $Matches[1] }
    if ($CommandLine -match '--gameDir\s+([^\s]+)') { return $Matches[1] }
    if ($CommandLine -match '-Dfabric\.gameDir="([^"]+)"') { return $Matches[1] }
    if ($CommandLine -match '-Dfabric\.gameDir=([^\s]+)') { return $Matches[1] }
    return ''
}

function Running-Games {
    $results = [System.Collections.Generic.List[object]]::new()
    $processes = @()
    try { $processes = @(Get-CimInstance Win32_Process -Filter "Name = 'java.exe' OR Name = 'javaw.exe'" -ErrorAction Stop) } catch {}
    foreach ($p in $processes) {
        $command = [string]$p.CommandLine
        $gameDir = Game-Directory $command
        if (-not $gameDir -and $command -notmatch '(?i)(minecraft|fabricmc|quiltmc|neoforge|lwjgl|forge|net\.minecraft\.client)') { continue }
        $started = ''
        try { $started = (Get-Process -Id $p.ProcessId -ErrorAction Stop).StartTime.ToUniversalTime().ToString('o') } catch {}
        $results.Add([pscustomobject]@{
            pid = [int]$p.ProcessId
            name = [string]$p.Name
            startedUtc = $started
            executable = Private-Path ([string]$p.ExecutablePath)
            instance = Instance-At $gameDir
            gameDir = $gameDir
            command = $command
        })
    }
    return @($results.ToArray())
}

function Discover-Instances {
    $folders = [System.Collections.Generic.List[string]]::new()
    if ($env:APPDATA) {
        foreach ($relative in @('.minecraft','ModrinthApp\profiles','PrismLauncher\instances','MultiMC\instances','PolyMC\instances','ATLauncher\instances','.feather\profiles','gdlauncher_next\instances')) {
            $folders.Add((Join-Path $env:APPDATA $relative))
        }
    }
    if ($env:USERPROFILE) { $folders.Add((Join-Path $env:USERPROFILE 'curseforge\minecraft\Instances')) }
    $results = [System.Collections.Generic.List[string]]::new()
    foreach ($folder in $folders) {
        $instance = Instance-At $folder
        if ($instance) { $results.Add($instance) }
        if (-not (Test-Path -LiteralPath $folder -PathType Container)) { continue }
        foreach ($child in @(Get-ChildItem -LiteralPath $folder -Directory -ErrorAction SilentlyContinue | Select-Object -First 120)) {
            $instance = Instance-At $child.FullName
            if ($instance) { $results.Add($instance) }
        }
    }
    return @($results.ToArray() | Select-Object -Unique)
}

function Choose-Game([object[]]$Running) {
    if ($ProcessId -gt 0) {
        $matched = @($Running | Where-Object { $_.pid -eq $ProcessId })
        if ($matched.Count -ne 1) { throw ('PID ' + $ProcessId + ' was not detected as a Minecraft Java process.') }
        return $matched[0]
    }
    if ($Running.Count -eq 0) {
        Say '  No running Minecraft Java process found.' 'Yellow'
        return $null
    }
    foreach ($game in $Running) {
        $dir = if ($game.instance) { Private-Path $game.instance } else { 'game folder unknown' }
        Say ('  PID {0} | {1} | {2}' -f $game.pid, $game.name, $dir) 'White'
    }
    if ($Running.Count -eq 1) {
        Say ('  Selected running Minecraft PID ' + $Running[0].pid) 'Magenta'
        return $Running[0]
    }
    $answer = Read-Host '  Enter the PID you want to scan'
    $number = 0
    if (-not [int]::TryParse($answer, [ref]$number)) { throw 'Please enter one of the displayed PIDs.' }
    $matched = @($Running | Where-Object { $_.pid -eq $number })
    if ($matched.Count -ne 1) { throw 'That PID was not in the Minecraft list.' }
    return $matched[0]
}

function Choose-Instance([object]$Game) {
    if ($InstancePath) {
        $path = Instance-At $InstancePath
        if (-not $path) { throw '-InstancePath must point to a Minecraft instance.' }
        return $path
    }
    if ($Game -and $Game.instance) { return $Game.instance }
    Say '  The selected process did not expose a usable game directory.' 'Yellow'
    Say '  Folder checks are optional. You choose the folder; Mewo will not guess.' 'Gray'
    $available = @(Discover-Instances)
    for ($i = 0; $i -lt $available.Count; $i++) {
        Say ('  {0}. {1}' -f ($i + 1), (Private-Path $available[$i])) 'Gray'
    }
    $answer = Read-Host '  Folder number, full path, or Enter to skip folder checks'
    if (-not $answer) { return '' }
    $number = 0
    if ([int]::TryParse($answer, [ref]$number) -and $number -ge 1 -and $number -le $available.Count) {
        return $available[$number - 1]
    }
    $path = Instance-At $answer
    if (-not $path) { throw 'That folder was not recognized as a Minecraft instance.' }
    return $path
}

function Inspect-Jar([string]$Path) {
    $metadata = [ordered]@{ loader = 'Unknown'; id = ''; name = ''; version = ''; classes = 0; matches = @(); generic = @(); error = '' }
    $seen = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    $genericSeen = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    $zip = $null
    try {
        $zip = [IO.Compression.ZipFile]::OpenRead($Path)
        if ($zip.Entries.Count -gt 45000) { throw 'Too many archive entries to inspect safely.' }
        foreach ($entry in $zip.Entries) {
            if ($entry.FullName.EndsWith('.class', [StringComparison]::OrdinalIgnoreCase)) {
                $metadata.classes++
                foreach ($rule in $script:Rules) {
                    if ($entry.FullName -match $rule.path) { [void]$seen.Add($rule.id) }
                }
                $leaf = [IO.Path]::GetFileNameWithoutExtension($entry.FullName)
                $normalized = ($leaf -replace '[^a-zA-Z0-9]', '').ToLowerInvariant()
                if ($script:ModuleIndex.ContainsKey($normalized)) {
                    [void]$genericSeen.Add(($script:ModuleIndex[$normalized] + ': ' + $leaf))
                }
            }
            if ($entry.Length -gt 262144) { continue }
            if ($entry.FullName -eq 'fabric.mod.json' -or $entry.FullName -eq 'quilt.mod.json') {
                $reader = [IO.StreamReader]::new($entry.Open())
                try {
                    $obj = ConvertFrom-Json $reader.ReadToEnd()
                    $metadata.loader = if ($entry.FullName -eq 'fabric.mod.json') { 'Fabric' } else { 'Quilt' }
                    if ($metadata.loader -eq 'Fabric') {
                        $metadata.id = [string]$obj.id
                        $metadata.name = [string]$obj.name
                        $metadata.version = [string]$obj.version
                    } else {
                        $metadata.id = [string]$obj.quilt_loader.id
                        $metadata.version = [string]$obj.quilt_loader.version
                    }
                } catch {} finally { $reader.Dispose() }
            }
            if ($entry.FullName -in @('META-INF/mods.toml','META-INF/neoforge.mods.toml')) {
                $reader = [IO.StreamReader]::new($entry.Open())
                try {
                    $toml = $reader.ReadToEnd()
                    $metadata.loader = if ($entry.FullName -match 'neoforge') { 'NeoForge' } else { 'Forge' }
                    if ($toml -match 'modId\s*=\s*"([^"]+)"') { $metadata.id = $Matches[1] }
                    if ($toml -match 'displayName\s*=\s*"([^"]+)"') { $metadata.name = $Matches[1] }
                    if ($toml -match 'version\s*=\s*"([^"]+)"') { $metadata.version = $Matches[1] }
                } catch {} finally { $reader.Dispose() }
            }
        }
        $metadata.matches = @($seen)
        $metadata.generic = @($genericSeen)
    } catch {
        $metadata.error = $_.Exception.Message
    } finally {
        if ($zip) { $zip.Dispose() }
    }
    return [pscustomobject]$metadata
}

function Scan-Mods([string]$Root) {
    Section 'Mod JARs and file integrity'
    if (-not $Root) {
        Covered 'mod-jars' 'Skipped' 'No instance folder was linked to the selected process.'
        return
    }
    $folder = Join-Path $Root 'mods'
    if (-not (Test-Path -LiteralPath $folder -PathType Container)) {
        Covered 'mod-jars' 'Unavailable' 'No mods directory found.'
        Finding 'Info' 'Mods' 'No mod directory' 'Vanilla or nonstandard instance layout.'
        return
    }
    $items = @(Get-ChildItem -LiteralPath $folder -Filter '*.jar' -File -ErrorAction SilentlyContinue | Sort-Object Name | Select-Object -First 400)
    Say ('  Checking {0} JARs in this instance.' -f $items.Count) 'Magenta'
    $scanned = 0
    foreach ($file in $items) {
        $hash = ''
        try { $hash = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash } catch {}
        $info = Inspect-Jar $file.FullName
        $scanned++
        if ($scanned % 10 -eq 0 -or $scanned -eq $items.Count) {
            ScanProgress $scanned $items.Count 'mod JARs'
        }
        $script:Mods.Add([pscustomobject]@{
            file = $file.Name; size = $file.Length; sha256 = $hash; lastWriteUtc = $file.LastWriteTimeUtc.ToString('o')
            loader = $info.loader; id = $info.id; name = $info.name; version = $info.version
            classCount = $info.classes; signatures = @($info.matches); genericModules = @($info.generic); error = $info.error
        })
        if ($info.error) {
            Finding 'Review' 'Mods' 'Unreadable archive' ($file.Name + ': ' + $info.error) '' $file.Name
            continue
        }
        foreach ($id in @($info.matches)) {
            Finding 'Indicator' 'Mods' 'Known client package identifier' ($file.Name + ': ' + $id + '; confirm context.') $id $file.Name
        }
        $genericFlags = @($info.generic | Select-Object -First 20)
        if ($genericFlags.Count -gt 0) {
            Finding 'Info' 'Generic Modules' 'Module-like class names' ($file.Name + ': ' + ($genericFlags -join ', ') + '; this alone does not identify a cheat.') '' $file.Name
        }
        $idText = $file.BaseName + ' ' + $info.id + ' ' + $info.name
        foreach ($rule in $script:Rules) {
            if ($idText -match $rule.name -and @($info.matches) -notcontains $rule.id) {
                Finding 'Review' 'Mods' 'Known client name' ($file.Name + ': ' + $rule.label) $rule.id $file.Name
            }
        }
    }
    foreach ($group in @($script:Mods.ToArray() | Where-Object { $_.id } | Group-Object -Property id | Where-Object { $_.Count -gt 1 })) {
        $names = @($group.Group | Select-Object -ExpandProperty file)
        Finding 'Review' 'Mods' 'Duplicate mod identifier' ($group.Name + ': ' + ($names -join ', ') + '; possible version conflict.') '' $group.Name
    }
    Covered 'mod-jars' 'Completed' ('Read metadata and hashes for ' + $script:Mods.Count + ' JARs; no nested JAR scan.')
}

function Scan-GameArtifacts([string]$Root) {
    Section 'Minecraft file artifacts'
    if (-not $Root) {
        Covered 'mod-artifacts' 'Skipped' 'No instance folder linked.'
        return
    }
    $total = 0
    foreach ($relative in @('mods','config')) {
        $folder = Join-Path $Root $relative
        if (-not (Test-Path -LiteralPath $folder -PathType Container)) { continue }
        foreach ($entry in @(Get-ChildItem -LiteralPath $folder -Force -ErrorAction SilentlyContinue | Select-Object -First 350)) {
            if ($relative -eq 'mods' -and -not $entry.PSIsContainer -and $entry.Name -match '(?i)\.(jar\.(disabled|old|bak)|dll|exe)$') {
                $total++
                Finding 'Info' 'Artifacts' 'Inactive or unusual mod file' ($entry.Name + '; no indication it was used.') '' $entry.Name
            }
            foreach ($rule in $script:Rules) {
                if ($entry.Name -match $rule.name) {
                    $total++
                    Finding 'Review' 'Artifacts' 'Client-named file or config' ($relative + '/' + $entry.Name + ' resembles ' + $rule.label + '; could be left over from an older install.') $rule.id $entry.Name
                    break
                }
            }
        }
    }
    Say ('  ' + $total + ' relevant file or config names recorded.') 'Magenta'
    Covered 'mod-artifacts' 'Completed' 'Examines file names in the selected Minecraft mods/config folders for possible leftover client markers. Does not read config contents.'
}

function Scan-Jvm([object[]]$Processes) {
    Section 'JVM and process launch'
    if ($Processes.Count -eq 0) {
        Covered 'jvm' 'Unavailable' 'No Minecraft Java process was selected.'
        Finding 'Info' 'Runtime' 'Live process unavailable' 'Only folder checks can run without an active Minecraft Java process.'
        return
    }
    foreach ($p in $Processes) {
        $script:Runtime.Add([pscustomobject]@{ pid = $p.pid; name = $p.name; startedUtc = $p.startedUtc; executable = $p.executable })
        Say ('  Checking PID ' + $p.pid) 'Magenta'
        foreach ($check in @(
            @{ name = 'Java instrumentation agent'; expression = '(?i)(?:^|\s)-javaagent(?:\s|:)' },
            @{ name = 'Native Java agent'; expression = '(?i)(?:^|\s)-agent(path|lib):' },
            @{ name = 'Bootstrap classpath override'; expression = '(?i)-Xbootclasspath' },
            @{ name = 'Additional Fabric mods'; expression = '(?i)-Dfabric\.(addMods|loadMods|classPathGroups)=' },
            @{ name = 'Mixin override'; expression = '(?i)-D(mixin\.configs|fabric\.mixin\.configs)=' }
        )) {
            if ($p.command -match $check.expression) {
                Finding 'Review' 'Runtime' $check.name ('PID ' + $p.pid + ': JVM launch has this option; it may be normal.') '' ('PID ' + $p.pid)
            }
        }
        foreach ($rule in $script:Rules) {
            if (-not $rule.name) { continue }
            if ($p.command -match ('(?i)(?:[\\/]|^|[\s"''])(?:' + $rule.id + ')(?:[-_.\s\\/]|\.jar\b)')) {
                Finding 'Review' 'Launch' 'Client identifier in launch arguments' ('PID ' + $p.pid + ': ' + $rule.label + '; check the selected launcher.') $rule.id ('PID ' + $p.pid)
            }
        }
    }
    Covered 'jvm' 'Completed' 'Checked process launch settings and known names; original command lines are not stored.'
}

function Scan-Modules([object[]]$Processes) {
    Section 'Loaded native modules'
    if ($Processes.Count -eq 0) {
        Covered 'dlls' 'Unavailable' 'No matching running Minecraft process.'
        return
    }
    $attempted = 0
    foreach ($p in $Processes) {
        $loaded = @()
        try { $loaded = @((Get-Process -Id $p.pid -ErrorAction Stop).Modules) } catch {
            Finding 'Info' 'Modules' 'Module enumeration blocked' ('PID ' + $p.pid + ': Windows access or architecture limitation.')
            continue
        }
        $attempted++
        Say ('  PID {0}: {1} loaded modules.' -f $p.pid, $loaded.Count) 'Cyan'
        foreach ($module in @($loaded | Select-Object -First 500)) {
            $location = [string]$module.FileName
            if (-not $location) { continue }
            $record = [ordered]@{ pid = $p.pid; module = [string]$module.ModuleName; path = Private-Path $location; sha256 = ''; signature = 'NotChecked' }
            $systemPath = $env:WINDIR -and $location.StartsWith($env:WINDIR, [StringComparison]::OrdinalIgnoreCase)
            $programPath = $env:ProgramFiles -and $location.StartsWith($env:ProgramFiles, [StringComparison]::OrdinalIgnoreCase)
            if (-not $systemPath -and -not $programPath) {
                try { $record.signature = [string](Get-AuthenticodeSignature -LiteralPath $location).Status } catch { $record.signature = 'Unavailable' }
                try { $record.sha256 = (Get-FileHash -LiteralPath $location -Algorithm SHA256).Hash } catch {}
                if ($record.signature -notin @('Valid','Unavailable')) {
                    if ($location -match '(?i)\\AppData\\Local\\Temp\\') {
                        Finding 'Review' 'Modules' 'Unsigned module loaded from Temp' ($module.ModuleName + ' in PID ' + $p.pid + '; investigate its origin.') '' ('PID ' + $p.pid)
                    }
                }
            }
            $script:Modules.Add([pscustomobject]$record)
        }
    }
    Covered 'dlls' $(if ($attempted -gt 0) { 'Completed' } else { 'Unavailable' }) 'Lists loaded modules and checks non-system module signatures when accessible; no inline-hook integrity verification.'
}

function Scan-Timeline([string]$Root) {
    Section 'Minecraft file timeline'
    if (-not $Root) {
        Covered 'file-timeline' 'Skipped' 'No instance folder linked.'
        return
    }
    $recent = [datetime]::UtcNow.AddDays(-14)
    foreach ($relative in @('mods','config')) {
        $folder = Join-Path $Root $relative
        if (-not (Test-Path -LiteralPath $folder -PathType Container)) { continue }
        $files = @(Get-ChildItem -LiteralPath $folder -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTimeUtc -Descending | Select-Object -First 150)
        foreach ($f in $files) {
            if ($f.LastWriteTimeUtc -lt $recent) { continue }
            $script:Timeline.Add([pscustomobject]@{
                location = $relative
                file = $f.Name
                updatedUtc = $f.LastWriteTimeUtc.ToString('o')
                size = $f.Length
            })
        }
    }
    Say ('  {0} relevant recent file timestamps.' -f $script:Timeline.Count) 'Cyan'
    Covered 'file-timeline' 'Completed' '14-day mod/config timestamp listing only; timestamps can be modified and are not proof of execution.'
}

function Scan-Macros {
    Section 'Optional macro software context'
    $names = @('AutoHotkey','AutoHotkey64','AutoHotkey32','AutoIt3','PuloversMacroCreator')
    $found = @(Get-Process -Name $names -ErrorAction SilentlyContinue)
    foreach ($p in $found) {
        Finding 'Info' 'Macro' 'Macro-capable software running' ($p.ProcessName + ' (PID ' + $p.Id + '). May be unrelated to Minecraft.')
    }
    Covered 'macro-software' 'Completed' 'Only checks a small list of currently running process names; no keystroke capture, macros or settings are read.'
}

$memorySource = @'
using System;
using System.Text;
using System.Collections.Generic;
using System.Runtime.InteropServices;

public static class MewoMemory
{
    [StructLayout(LayoutKind.Sequential)]
    public struct Region
    {
        public ulong BaseAddress;
        public ulong AllocationBase;
        public uint AllocationProtect;
        public uint Alignment1;
        public ulong RegionSize;
        public uint State;
        public uint Protect;
        public uint Type;
        public uint Alignment2;
    }

    [DllImport("kernel32.dll", SetLastError = true)]
    static extern IntPtr OpenProcess(uint rights, bool inherit, int pid);

    [DllImport("kernel32.dll", SetLastError = true)]
    static extern bool CloseHandle(IntPtr handle);

    [DllImport("kernel32.dll", SetLastError = true)]
    static extern UIntPtr VirtualQueryEx(IntPtr handle, IntPtr address, out Region region, UIntPtr length);

    [DllImport("kernel32.dll", SetLastError = true)]
    static extern bool ReadProcessMemory(IntPtr handle, IntPtr address, byte[] destination, UIntPtr size, out UIntPtr read);

    public static string[] Check(int pid, string[] patterns, int limitMiB)
    {
        var results = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        if (IntPtr.Size != 8) throw new Exception("Use 64-bit Windows PowerShell for this check.");
        var handle = OpenProcess(0x0410, false, pid);
        if (handle == IntPtr.Zero) throw new Exception("Cannot read selected Minecraft process.");
        try
        {
            ulong address = 0x10000;
            ulong maximum = 0x00007FFFFFF00000UL;
            long scanned = 0;
            long cap = limitMiB * 1024L * 1024L;
            var block = new byte[131072];
            var structureSize = new UIntPtr((uint)Marshal.SizeOf(typeof(Region)));
            var latin = Encoding.GetEncoding(28591);
            while (address < maximum && scanned < cap)
            {
                Region region;
                var readRegion = VirtualQueryEx(handle, new IntPtr(unchecked((long)address)), out region, structureSize);
                if (readRegion == UIntPtr.Zero || region.RegionSize == 0) break;
                ulong next = region.BaseAddress + region.RegionSize;
                if (next <= address) break;
                bool readable = region.State == 0x1000 && (region.Protect & 0x100) == 0 && (region.Protect & 0x01) == 0 && (region.Protect & 0x02) == 0;
                if (readable)
                {
                    ulong offset = 0;
                    ulong sample = Math.Min(region.RegionSize, 16UL * 1024UL * 1024UL);
                    while (offset < sample && scanned < cap)
                    {
                        int requested = (int)Math.Min((ulong)block.Length, sample - offset);
                        requested = (int)Math.Min(requested, cap - scanned);
                        if (requested < 1) break;
                        UIntPtr length;
                        bool okay = ReadProcessMemory(handle, new IntPtr(unchecked((long)(region.BaseAddress + offset))), block, new UIntPtr((uint)requested), out length);
                        int size = (int)length.ToUInt64();
                        if (okay && size > 0)
                        {
                            scanned += size;
                            string ascii = latin.GetString(block, 0, size);
                            string unicode = Encoding.Unicode.GetString(block, 0, size - size % 2);
                            foreach (var pattern in patterns)
                            {
                                if (ascii.IndexOf(pattern, StringComparison.OrdinalIgnoreCase) >= 0 || unicode.IndexOf(pattern, StringComparison.OrdinalIgnoreCase) >= 0)
                                    results.Add(pattern);
                            }
                        }
                        offset += (ulong)requested;
                    }
                }
                address = next;
            }
            return new List<string>(results).ToArray();
        }
        finally { CloseHandle(handle); }
    }
}
'@

function Scan-Memory([object[]]$Processes) {
    Section 'Consented JVM memory signatures'
    if ($Processes.Count -eq 0) {
        Covered 'memory' 'Unavailable' 'No associated running Minecraft process.'
        return
    }
    Say '  Deep mode samples up to 256 MiB per selected Java process for configured strings.' 'Yellow'
    Say '  It does not keep raw memory, but private data may be encountered during inspection.' 'Yellow'
    if ((Read-Host '  Allow this additional memory inspection? [y/N]') -notmatch '^(?i:y|yes)$') {
        Covered 'memory' 'Skipped' 'Player declined optional process memory check.'
        return
    }
    try { Add-Type -TypeDefinition $memorySource -ErrorAction Stop } catch {
        Covered 'memory' 'Unavailable' ('Cannot initialize native API bindings: ' + $_.Exception.Message)
        return
    }
    $needles = @('meteordevelopment/meteorclient','meteordevelopment.meteorclient','net/wurstclient','net.wurstclient','net/ccbluex/liquidbounce','net.ccbluex.liquidbounce','org/bleachhack','org.bleachhack','thunder/hack','rusherhack','dev/fiki/forgehax','dev.fiki.forgehax','xyz/mathax/mathaxclient','xyz.mathax.mathaxclient','com/lambda/client','com.lambda.client','me/deftware','me.deftware')
    $checks = 0
    foreach ($p in $Processes) {
        try {
            $hits = @([MewoMemory]::Check([int]$p.pid, [string[]]$needles, 256))
            $checks++
            foreach ($hit in $hits) {
                $id = ''
                foreach ($rule in $script:Rules) {
                    if ($hit -match $rule.path -or $hit -match $rule.id) { $id = $rule.id; break }
                }
                Finding 'Review' 'Memory' 'Client-related string in JVM memory' ('PID ' + $p.pid + ': ' + $hit + '; strings alone are inconclusive.') $id ('PID ' + $p.pid)
            }
            if ($hits.Count -eq 0) { Say ('  PID {0}: no configured signatures in sampled pages.' -f $p.pid) 'Gray' }
        } catch {
            Finding 'Info' 'Memory' 'Inspection unavailable' ('PID ' + $p.pid + ': ' + $_.Exception.Message)
        }
    }
    Covered 'memory' $(if ($checks -gt 0) { 'Completed' } else { 'Unavailable' }) 'Read up to 256 MiB per process across sampled readable pages; this is not complete process memory coverage.'
}

function Scan-Dns {
    Section 'Optional client site traces'
    Say '  Checks only known client website names in the local Windows DNS cache.' 'Yellow'
    Say '  A cached domain can mean a website visit, not cheating or a client launch.' 'Gray'
    if ((Read-Host '  Check these limited DNS names? [y/N]') -notmatch '^(?i:y|yes)$') {
        Covered 'dns-cache' 'Skipped' 'Player declined DNS cache lookup.'
        return
    }
    $knownDomains = @(
        @{ id = 'meteor'; label = 'Meteor Client'; domain = 'meteorclient.com' },
        @{ id = 'wurst'; label = 'Wurst Client'; domain = 'wurstclient.net' },
        @{ id = 'liquidbounce'; label = 'LiquidBounce'; domain = 'liquidbounce.net' }
    )
    try {
        $entries = @(Get-DnsClientCache -ErrorAction Stop | Select-Object -ExpandProperty Entry -Unique)
        $hits = 0
        foreach ($domain in $knownDomains) {
            foreach ($entry in $entries) {
                if ($entry -ieq $domain.domain -or $entry.EndsWith('.' + $domain.domain, [StringComparison]::OrdinalIgnoreCase)) {
                    $hits++
                    Finding 'Info' 'DNS' 'Client website in Windows DNS cache' ($domain.label + ': ' + $entry + '; website resolution is not evidence the client ran.') $domain.id $entry
                }
            }
        }
        Say ('  Client-site cache records found: ' + $hits) 'Gray'
        Covered 'dns-cache' 'Completed' 'Only checked three known client website domains. Unrelated cached domain names are discarded.'
    } catch {
        Covered 'dns-cache' 'Unavailable' 'Windows DNS cache query unavailable.'
    }
}

function Correlate-Evidence {
    Section 'Evidence correlation'
    $groups = @($script:Findings.ToArray() | Where-Object { $_.ruleId })
    $correlated = [System.Collections.Generic.List[object]]::new()
    foreach ($id in @($groups | Select-Object -ExpandProperty ruleId -Unique)) {
        $items = @($groups | Where-Object { $_.ruleId -eq $id })
        $sources = @($items | Select-Object -ExpandProperty category -Unique)
        $conclusion = if ($sources.Count -ge 2) { 'Multiple independent categories require manual review' } else { 'Single-category evidence; insufficient to corroborate' }
        $correlated.Add([pscustomobject]@{
            ruleId = $id
            evidenceCategories = $sources
            findingCount = $items.Count
            interpretation = $conclusion
        })
        Say ('  {0}: {1} source category/categories - {2}' -f $id, $sources.Count, $conclusion) $(if ($sources.Count -ge 2) { 'Yellow' } else { 'Gray' })
    }
    if ($correlated.Count -eq 0) { Say '  No configured client identifiers detected in completed checks.' 'Green' }
    return @($correlated.ToArray())
}

function Get-ScanVerdict {
    $all = @($script:Findings.ToArray())
    $clientFiles = @($all | Where-Object { $_.category -eq 'Mods' -and $_.level -eq 'Indicator' })
    $clientNames = @($all | Where-Object { $_.category -eq 'Mods' -and $_.level -eq 'Review' })
    $strings = @($all | Where-Object { $_.category -eq 'Memory' -and $_.ruleId })
    $traces = @($all | Where-Object { $_.category -eq 'Artifacts' -and $_.ruleId })
    $agentFlags = @($all | Where-Object { $_.category -eq 'Runtime' -and $_.level -eq 'Review' })
    $otherFlags = @($all | Where-Object { $_.level -eq 'Review' -and $_.category -notin @('Mods','Memory','Artifacts','Runtime') })
    $checks = @($script:Coverage.ToArray())
    $jvmChecked = @($checks | Where-Object { $_.check -eq 'jvm' -and $_.status -eq 'Completed' }).Count -gt 0
    $modsChecked = @($checks | Where-Object { $_.check -eq 'mod-jars' -and $_.status -eq 'Completed' }).Count -gt 0
    $notFinished = @($checks | Where-Object { $_.status -eq 'Unavailable' }).Count
    if ($clientFiles.Count -gt 0) {
        $status = 'CLIENT JAR SIGNATURE FOUND'
        $reason = 'A known client package was found in a Minecraft mod JAR.'
    } elseif ($strings.Count -gt 0) {
        $status = 'CLIENT STRINGS DETECTED'
        $reason = 'A known client-related string was found in sampled JVM memory. It may be a reference rather than loaded code.'
    } elseif ($clientNames.Count -gt 0 -or $traces.Count -gt 0 -or $agentFlags.Count -gt 0 -or $otherFlags.Count -gt 0) {
        $status = 'POSSIBLE CHEAT INDICATORS'
        $reason = 'Unconfirmed names, runtime changes, or related traces need a closer look.'
    } elseif (-not $jvmChecked -and -not $modsChecked) {
        $status = 'SCAN INCOMPLETE'
        $reason = 'Neither the running JVM nor Minecraft mod files were checked successfully.'
    } else {
        $status = 'NO CHEAT INDICATORS FOUND'
        $reason = 'Nothing matched the current detection rules in the checks that completed.'
    }
    return [pscustomobject]@{
        status = $status
        explanation = $reason
        cheatModSignatures = $clientFiles.Count
        clientNameMatches = $clientNames.Count
        clientMemoryStrings = $strings.Count
        clientFileTraces = $traces.Count
        jvmAgentFlags = $agentFlags.Count
        otherReviewFlags = $otherFlags.Count
        liveJvmChecked = $jvmChecked
        modFilesChecked = $modsChecked
        unavailableChecks = $notFinished
        inlineHooks = 'NOT VERIFIED'
    }
}

function Write-Report([string]$Root, [object[]]$Correlations) {
    Section 'Local evidence report'
    $target = $OutputDirectory
    if (-not $target) {
        $documents = [Environment]::GetFolderPath('MyDocuments')
        if (-not $documents) { $documents = $env:TEMP }
        $target = Join-Path $documents 'Mewo-Reports'
    }
    New-Item -ItemType Directory -Path $target -Force | Out-Null
    $file = Join-Path $target ('Mewo-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '-' + $script:SessionId.Substring(0,8) + '.json')
    $indicatorCount = @($script:Findings | Where-Object { $_.level -eq 'Indicator' }).Count
    $reviewCount = @($script:Findings | Where-Object { $_.level -eq 'Review' }).Count
    $verdict = Get-ScanVerdict
    $report = [ordered]@{
        product = 'Mewo Client Fucker'
        version = $script:Version
        sessionId = $script:SessionId
        mode = $Mode
        startedUtc = $script:Started.ToString('o')
        finishedUtc = [datetime]::UtcNow.ToString('o')
        minecraftInstance = Private-Path $Root
        outcome = $verdict.status
        verdict = $verdict
        counts = @{ indicators = $indicatorCount; review = $reviewCount; mods = $script:Mods.Count; dlls = $script:Modules.Count }
        coverage = @($script:Coverage.ToArray())
        processes = @($script:Runtime.ToArray())
        mods = @($script:Mods.ToArray())
        modules = @($script:Modules.ToArray())
        timeline = @($script:Timeline.ToArray())
        findings = @($script:Findings.ToArray())
        correlations = @($Correlations)
        checksNotIncluded = @(
            'Not a verdict of innocence or cheating.'
            'A clean result cannot establish that a machine has no cheats.'
            'Windows timestamps can be altered or missing.'
            'DLL signatures, macro software, JVM agents, and obfuscation alone do not establish wrongdoing.'
            'This version does not implement inline-hook byte verification, persistent monitoring, deleted-file recovery, or a Paper server-side bridge.'
            'The report SHA-256 checksum detects accidental or subsequent changes only if independently retained; it does not authenticate scanner execution.'
        )
        privacy = 'Stored locally; not uploaded by this scanner.'
    }
    $report | ConvertTo-Json -Depth 15 | Set-Content -LiteralPath $file -Encoding UTF8
    $digest = (Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash
    Set-Content -LiteralPath ($file + '.sha256') -Value $digest -Encoding Ascii
    $summary = [System.Collections.Generic.List[string]]::new()
    $summary.Add('MEWO CLIENT FUCKER | v' + $script:Version)
    $summary.Add('Session: ' + $script:SessionId)
    $summary.Add('Instance: ' + (Private-Path $Root))
    $summary.Add('Mode: ' + $Mode)
    $summary.Add('Result: ' + $report.outcome)
    $summary.Add('Why: ' + $verdict.explanation)
    $summary.Add(('Client JARs: {0} | Client strings: {1} | File traces: {2} | Hook bytes: NOT VERIFIED' -f $verdict.cheatModSignatures, $verdict.clientMemoryStrings, $verdict.clientFileTraces))
    $summary.Add(('Indicators: {0} | Needs review: {1} | JARs: {2} | DLLs: {3}' -f $indicatorCount, $reviewCount, $script:Mods.Count, $script:Modules.Count))
    $summary.Add('')
    $summary.Add('FINDINGS')
    foreach ($finding in $script:Findings) {
        $summary.Add(('[{0}] {1}: {2}' -f $finding.level, $finding.title, $finding.detail))
    }
    $summary.Add('')
    $summary.Add('CHECK COVERAGE')
    foreach ($check in $script:Coverage) {
        $summary.Add(('[{0}] {1}: {2}' -f $check.status, $check.check, $check.explanation))
    }
    $summary.Add('')
    $summary.Add('This is not an automatic cheating verdict. No report was uploaded.')
    $summaryPath = [IO.Path]::ChangeExtension($file, '.txt')
    $summary.ToArray() | Set-Content -LiteralPath $summaryPath -Encoding UTF8
    Say ('  ' + $report.outcome) 'Magenta'
    Say ('  Indicators: {0} | Review: {1} | JARs: {2} | DLLs: {3}' -f $indicatorCount, $reviewCount, $script:Mods.Count, $script:Modules.Count) 'White'
    Say ('  JSON: ' + $file) 'Magenta'
    Say ('  Text: ' + $summaryPath) 'Magenta'
    Say ('  SHA-256: ' + $digest) 'DarkGray'
    Say '  Review the JSON report before sharing. No report was transmitted.' 'Gray'
}

function Show-Findings([object]$Game, [string]$Root) {
    $verdict = Get-ScanVerdict
    Section 'MEWO SCAN RESULT'
    $color = if ($verdict.cheatModSignatures -gt 0) { 'Red' } elseif ($verdict.clientMemoryStrings -gt 0 -or $verdict.clientFileTraces -gt 0 -or $verdict.otherReviewFlags -gt 0 -or $verdict.clientNameMatches -gt 0 -or $verdict.jvmAgentFlags -gt 0) { 'Yellow' } else { 'Green' }
    Say ('  ' + ('=' * 62)) $color
    Say ('  ' + $verdict.status) $color
    Say ('  ' + $verdict.explanation) 'White'
    Say ('  ' + ('=' * 62)) $color
    Say ('  Cheat mod package matches : ' + $verdict.cheatModSignatures) $(if ($verdict.cheatModSignatures) { 'Red' } else { 'Gray' })
    Say ('  Client-name matches       : ' + $verdict.clientNameMatches) 'Gray'
    Say ('  JVM client strings        : ' + $verdict.clientMemoryStrings) $(if ($verdict.clientMemoryStrings) { 'Yellow' } else { 'Gray' })
    Say ('  Client file traces        : ' + $verdict.clientFileTraces) 'Gray'
    Say ('  JVM agent flags           : ' + $verdict.jvmAgentFlags) 'Gray'
    Say ('  Other review flags        : ' + $verdict.otherReviewFlags) 'Gray'
    Say '  Native inline hooks       : NOT VERIFIED' 'DarkYellow'
    if ($Game) { Say ('  Minecraft PID             : ' + $Game.pid) 'White' }
    else { Say '  Minecraft PID             : NONE' 'Yellow' }
    if ($Root) { Say ('  Linked instance           : ' + (Private-Path $Root)) 'Gray' }
    else { Say '  Linked instance           : NONE' 'Yellow' }
    foreach ($group in @(
        @{ title = 'CLIENT SIGNATURES'; records = @($script:Findings.ToArray() | Where-Object { $_.level -eq 'Indicator' }); color = 'Red' },
        @{ title = 'NEEDS REVIEW'; records = @($script:Findings.ToArray() | Where-Object { $_.level -eq 'Review' }); color = 'Yellow' },
        @{ title = 'OTHER NOTES'; records = @($script:Findings.ToArray() | Where-Object { $_.level -eq 'Info' }); color = 'Gray' }
    )) {
        if ($group.records.Count -eq 0) { continue }
        Section $group.title
        foreach ($finding in $group.records) {
            Say ('  ' + $finding.title) $group.color
            Say ('    ' + $finding.detail) 'Gray'
        }
    }
    Section 'Check coverage'
    foreach ($check in $script:Coverage) {
        $color = if ($check.status -eq 'Completed') { 'Green' } elseif ($check.status -eq 'Skipped') { 'Yellow' } else { 'DarkYellow' }
        Say ('  [{0}] {1}: {2}' -f $check.status, $check.check, $check.explanation) $color
    }
    Say ''
    Say '  Detection result only. It cannot prove whether a player is cheating.' 'DarkGray'
}


function Report-Details {
    if ($script:Mods.Count -eq 0 -and $script:Modules.Count -eq 0 -and $script:Timeline.Count -eq 0) { return }
    do {
        Write-Host ''
        Say '  [M] Mods   [D] DLLs   [T] Timeline   [Enter] Exit' 'Magenta'
        $answer = Read-Host '  Show details'
        switch ($answer.ToLowerInvariant()) {
            'm' {
                Section 'Mods checked'
                foreach ($mod in $script:Mods) {
                    Say ('  {0}  [{1}] {2}  {3}' -f $mod.file, $mod.loader, $mod.id, $mod.version) 'White'
                    if ($mod.signatures.Count -gt 0) { Say ('    Client packages: ' + ($mod.signatures -join ', ')) 'Yellow' }
                }
            }
            'd' {
                Section 'Loaded DLLs'
                foreach ($module in $script:Modules) {
                    Say ('  PID {0}  {1}  {2}' -f $module.pid, $module.module, $module.signature) 'Gray'
                }
            }
            't' {
                Section 'Minecraft file timeline'
                foreach ($item in $script:Timeline) {
                    Say ('  {0}  {1}/{2}' -f $item.updatedUtc, $item.location, $item.file) 'Gray'
                }
            }
        }
    } while ($answer -ne '')
}

function Run-SelfTest {
    $script:Findings.Clear()
    $script:Coverage.Clear()
    Covered 'jvm' 'Completed' 'Test process'
    Covered 'mod-jars' 'Completed' 'Test JAR'
    $clean = Get-ScanVerdict
    if ($clean.status -ne 'NO CHEAT INDICATORS FOUND') { throw ('Clean verdict mismatch: ' + $clean.status) }
    Finding 'Indicator' 'Mods' 'Known client package identifier' 'Synthetic test client' 'meteor' 'test.jar'
    $identified = Get-ScanVerdict
    if ($identified.status -ne 'CLIENT JAR SIGNATURE FOUND' -or $identified.cheatModSignatures -ne 1) { throw 'Client JAR verdict did not work.' }
    $script:Findings.Clear()
    Finding 'Review' 'Memory' 'Client-related string in JVM memory' 'Synthetic memory signature' 'meteor' 'PID 1234'
    $memory = Get-ScanVerdict
    if ($memory.status -ne 'CLIENT STRINGS DETECTED' -or $memory.clientMemoryStrings -ne 1) { throw 'Memory-string verdict did not work.' }
    $script:Findings.Clear()
    Finding 'Review' 'Artifacts' 'Client-named file or config' 'Synthetic config trace' 'meteor' 'test.json'
    $trace = Get-ScanVerdict
    if ($trace.status -ne 'POSSIBLE CHEAT INDICATORS' -or $trace.clientFileTraces -ne 1) { throw 'Trace verdict did not work.' }
    $script:Findings.Clear()
    $script:Coverage.Clear()
    $empty = Get-ScanVerdict
    if ($empty.status -ne 'SCAN INCOMPLETE') { throw 'Incomplete verdict did not work.' }
    try { Add-Type -TypeDefinition $memorySource -ErrorAction Stop } catch { throw ('Memory helper could not compile: ' + $_.Exception.Message) }
    $script:Findings.Clear()
    $script:Coverage.Clear()
    Say '  MEWO SELF-TEST PASSED' 'Green'
}

function Main {
    if ($env:OS -ne 'Windows_NT') { throw 'Mewo requires Windows.' }
    try { $Host.UI.RawUI.WindowTitle = 'Mewo Client Fucker | Scanner' } catch {}
    if (-not $script:ModeWasProvided) {
        Say '  MEWO | PICK A SCAN MODE' 'Magenta'
        Say '  [1] Quick     JVM + mods' 'White'
        Say '  [2] Standard  DLLs + local timeline' 'White'
        Say '  [3] Deep      Optional JVM memory signatures' 'White'
        $choice = Read-Host '  Mode [2]'
        $Mode = switch ($choice) {
            '1' { 'Quick' }
            '3' { 'Deep' }
            default { 'Standard' }
        }
    }
    Banner
    Section 'Consent'
    Say '  Mewo checks the selected Minecraft process and, when linked,' 'White'
    Say '  its mods, JVM options, DLLs and recent local file timestamps.' 'White'
    Say '  Deep mode asks separately before sampling JVM memory and DNS names.' 'White'
    Say '  Nothing is uploaded. No keystrokes or screenshots are collected.' 'White'
    if ((Read-Host '  Allow this scan? [y/N]') -notmatch '^(?i:y|yes)$') {
        Say '  Scan cancelled.' 'Yellow'
        return
    }
    Section 'Running Minecraft'
    $running = @(Running-Games)
    $game = Choose-Game $running
    if (-not $game -and -not $InstancePath) {
        if ((Read-Host '  No live JVM found. Continue folder-only? [y/N]') -notmatch '^(?i:y|yes)$') {
            Say '  Scan cancelled.' 'Yellow'
            return
        }
    }
    $selected = @()
    if ($game) {
        $selected = @($game)
        Say ('  Checking PID {0}  {1}  {2}' -f $game.pid, $game.name, $game.startedUtc) 'Magenta'
    }
    $root = Choose-Instance $game
    if ($root) { Say ('  Folder: ' + (Private-Path $root)) 'White' }
    else { Say '  No instance folder linked. Live process checks will still run.' 'Yellow' }
    $total = if ($Mode -eq 'Quick') { 5 } elseif ($Mode -eq 'Deep') { 10 } else { 8 }
    Stage 1 $total 'JVM'
    Scan-Jvm $selected
    Stage 2 $total 'Mod JARs'
    Scan-Mods $root
    Stage 3 $total 'Mod folder artifacts'
    Scan-GameArtifacts $root
    if ($Mode -in @('Standard','Deep')) {
        Stage 4 $total 'DLLs'
        Scan-Modules $selected
        Stage 5 $total 'File timeline'
        Scan-Timeline $root
        Stage 6 $total 'Macro process names'
        Scan-Macros
    } else {
        Covered 'dlls' 'Skipped' 'Quick mode'
        Covered 'file-timeline' 'Skipped' 'Quick mode'
        Covered 'macro-software' 'Skipped' 'Quick mode'
    }
    if ($Mode -eq 'Deep') {
        Stage 7 $total 'Optional JVM memory'
        Scan-Memory $selected
        Stage 8 $total 'Optional DNS client-site traces'
        Scan-Dns
    } else {
        Covered 'memory' 'Skipped' 'Deep mode only'
        Covered 'dns-cache' 'Skipped' 'Deep mode only'
    }
    Stage ($total - 1) $total 'Evidence check'
    $correlations = @(Correlate-Evidence)
    Stage $total $total 'Save report'
    Write-Report $root $correlations
    Show-Findings $game $root
    Report-Details
    Say ''
    Say '  Mewo finished.' 'Magenta'
}

try {
    if ($SelfTest) { Run-SelfTest } else { Main }
} catch {
    Say ('  [ERROR] ' + $_.Exception.Message) 'Red'
    exit 1
}
