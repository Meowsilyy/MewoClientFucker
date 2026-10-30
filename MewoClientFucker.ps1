param(
    [ValidateSet('Quick','Standard','Deep')][string]$Mode = 'Standard',
    [int]$TargetPid = 0,
    [string]$InstancePath = '',
    [string]$OutputDirectory = '',
    [switch]$SelfTest
)

$ErrorActionPreference = 'Stop'
$script:ModeProvided = $PSBoundParameters.ContainsKey('Mode')
$script:Version = '1.1.0'
$script:Started = [DateTime]::UtcNow
$script:Session = [guid]::NewGuid().ToString('N')
$script:Findings = [Collections.Generic.List[object]]::new()
$script:Coverage = [Collections.Generic.List[object]]::new()
$script:Mods = [Collections.Generic.List[object]]::new()
$script:DLLs = [Collections.Generic.List[object]]::new()
$script:Timeline = [Collections.Generic.List[object]]::new()
$script:Processes = [Collections.Generic.List[object]]::new()
$script:MemoryBytes = 0L
$script:Target = $null
$script:Root = ''
$script:Rules = @(
    @{ id='meteor'; name='Meteor Client'; package='(?i)(^|/)meteordevelopment/meteorclient/'; names='(?i)(^|[-_. ])meteor([-_. ]|$)' },
    @{ id='liquidbounce'; name='LiquidBounce'; package='(?i)(^|/)net/ccbluex/liquidbounce/'; names='(?i)liquidbounce' },
    @{ id='wurst'; name='Wurst'; package='(?i)(^|/)net/wurstclient/'; names='(?i)(^|[-_. ])wurst([-_. ]|$)' },
    @{ id='bleachhack'; name='BleachHack'; package='(?i)(^|/)org/bleachhack/'; names='(?i)bleachhack' },
    @{ id='thunderhack'; name='ThunderHack'; package='(?i)(^|/)(thunder/hack|thunderhack)/'; names='(?i)thunderhack' },
    @{ id='rusherhack'; name='RusherHack'; package='(?i)(^|/)org/rusherhack/'; names='(?i)rusherhack' },
    @{ id='forgehax'; name='ForgeHax'; package='(?i)(^|/)dev/fiki/forgehax/'; names='(?i)forgehax' },
    @{ id='mathax'; name='MatHax'; package='(?i)(^|/)xyz/mathax/mathaxclient/'; names='(?i)mathax' },
    @{ id='lambda'; name='Lambda'; package='(?i)(^|/)com/lambda/client/'; names='(?i)(^|[-_. ])lambda([-_. ]|$)' },
    @{ id='kamiblue'; name='KAMI Blue'; package='(?i)(^|/)(me/zeroeightsix/kami|com/kamiblue)/'; names='(?i)(kami[-_. ]?blue|kamiblue)' },
    @{ id='aristois'; name='Aristois'; package='(?i)(^|/)me/deftware/'; names='(?i)aristois' },
    @{ id='jex'; name='Jex'; package='(?i)(^|/)dev/jexclient/'; names='(?i)(^|[-_. ])jex([-_. ]|$)' },
    @{ id='salhack'; name='SalHack'; package='(?i)(^|/)me/ionar/salhack/'; names='(?i)salhack' },
    @{ id='raven'; name='Raven'; package='(?i)(^|/)keystrokesmod/'; names='(?i)(^|[-_. ])raven([-_.+ ]|$)' },
    @{ id='fdp'; name='FDPClient'; package='(?i)(^|/)net/ccbluex/fdpclient/'; names='(?i)fdpclient' },
    @{ id='konas'; name='Konas'; package='(?i)(^|/)me/konas/'; names='(?i)(^|[-_. ])konas([-_. ]|$)' },
    @{ id='huzuni'; name='Huzuni'; package='(?i)(^|/)huzuni/'; names='(?i)huzuni' },
    @{ id='trollhack'; name='TrollHack'; package='(?i)(^|/)trollhack/'; names='(?i)trollhack' },
    @{ id='vape'; name='Vape'; package='(?!)'; names='(?i)(^|[-_. ])vape([-_. ]|$)' },
    @{ id='backdoored'; name='Backdoored'; package='(?i)(^|/)backdoored/'; names='(?i)backdoored' }
)
$script:Generic = [ordered]@{
    Combat=@('AimAssist','AimLock','KillAura','TriggerBot','SilentAim','BowAimbot','MaceAura','SilentMace','AutoMace','ShieldDisabler','ShieldBreaker','HitBox','Reach','WTap','JumpReset','SprintReset','AutoClicker','AutoPot','AntiWeakness','AutoWeapon')
    Crystal=@('AutoCrystal','AutoHitCrystal','CrystalAura','CrystalMacro','CrystalOptimizer','AutoAnchor','AnchorAura','AnchorMacro','DoubleAnchor','SafeAnchor','AutoDTap','MarlowAnchor','PistonAura','AutoObsidian','Surround','Burrow','HoleFiller','AutoTrap','AutoCity','AutoWeb')
    Totem=@('AutoTotem','AutoRetotem','TotemOffhand','HoverTotem','LegitTotem','ForceTotem','InventoryTotem','OffhandTotem','AutoDoubleHand')
    Movement=@('NoFall','InventoryMove','FastBridge','BridgeAssist','ElytraGlide','ElytraFly','Fly','SpeedHack','Jesus','Step','Phase','Spider','NoSlow','AntiKnockback','Velocity','FastPlace','FastSwim')
    Automation=@('AutoXP','AutoArmor','AutoMine','ChestStealer','AutoTool','AutoEat','AutoSell','AutoFish','AutoFarm','AutoRefill','AutoRestock','AutoPearl','AutoSwap','BedMacro','AutoFirework','AutoCraft','AuctionSniper','AutoLog')
    Vision=@('PlayerESP','StorageESP','EntityESP','XRay','BaseESP','ChunkFinder','Freecam','Tracers','ChestESP','HoleESP','MobESP','PearlESP','NameTags','Fullbright','HealthIndicators','StashFinder','BaseFinder','SpawnerFinder')
    Bypass=@('FakeLag','PingSpoof','Blink','Disabler','GrimBypass','VulcanBypass','MatrixBypass','WatchdogBypass','PacketCancel','NoPacket','Timer')
}
$script:GenericIndex = @{}
foreach ($category in $script:Generic.Keys) {
    foreach ($item in $script:Generic[$category]) {
        $script:GenericIndex[$item.ToLowerInvariant()] = [pscustomobject]@{ name=$item; category=$category }
    }
}

function Paint([string]$Value,[string]$Color='Gray') {
    Write-Host $Value -ForegroundColor $Color
}

function Heading([string]$Value) {
    Paint ''
    Paint ('  ' + ('─' * 60)) 'DarkMagenta'
    Paint ('  ' + $Value.ToUpperInvariant()) 'Magenta'
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
    Paint $art 'Magenta'
    Paint ('  v' + $script:Version + '  |  Meowsilyy  |  Local scanner') 'White'
    Paint '  Yarp-style mod analysis + independent Meow-style indicators' 'DarkGray'
}

function Hide-Home([string]$Value) {
    if (-not $Value) { return '' }
    $homePath = [Environment]::GetFolderPath('UserProfile')
    if ($homePath -and $Value.StartsWith($homePath,[StringComparison]::OrdinalIgnoreCase)) {
        return '~' + $Value.Substring($homePath.Length)
    }
    return $Value
}

function Add-Finding([string]$Kind,[string]$Category,[string]$Title,[string]$Detail,[string]$Rule='', [string]$Evidence='') {
    $entry = [pscustomobject]@{ kind=$Kind; category=$Category; title=$Title; detail=$Detail; rule=$Rule; evidence=$Evidence }
    $script:Findings.Add($entry)
    $color = switch ($Kind) { 'Client' { 'Red' } 'Module' { 'Yellow' } 'Memory' { 'Yellow' } 'String' { 'DarkYellow' } 'Review' { 'DarkYellow' } default { 'Gray' } }
    if ($Kind -ne 'Info') { Paint ('  [' + $Kind.ToUpperInvariant() + '] ' + $Title + ' — ' + $Detail) $color }
}

function Mark([string]$Name,[string]$Status,[string]$Detail) {
    $script:Coverage.Add([pscustomobject]@{ check=$Name; status=$Status; detail=$Detail })
}

function Confirm([string]$Prompt) {
    return ((Read-Host ('  ' + $Prompt + ' [y/N]')) -match '^(?i:y|yes)$')
}

function Get-GameDir([string]$Command) {
    if (-not $Command) { return '' }
    foreach ($pattern in @('--gameDir\s+"([^"]+)"','--gameDir\s+([^\s]+)','-Dfabric\.gameDir="([^"]+)"','-Dfabric\.gameDir=([^\s]+)')) {
        if ($Command -match $pattern) { return $Matches[1] }
    }
    return ''
}

function Root-At([string]$Path) {
    if (-not $Path) { return '' }
    $value = [Environment]::ExpandEnvironmentVariables($Path.Trim(' ','"',"'"))
    if (-not (Test-Path -LiteralPath $value -PathType Container)) { return '' }
    if ((Split-Path $value -Leaf) -ieq 'mods') { $value = Split-Path $value -Parent }
    foreach ($path in @($value,(Join-Path $value '.minecraft'),(Join-Path $value 'minecraft'),(Join-Path $value 'game'))) {
        foreach ($sub in @('mods','config','versions','logs')) {
            if (Test-Path -LiteralPath (Join-Path $path $sub) -PathType Container) {
                return (Get-Item -LiteralPath $path).FullName
            }
        }
    }
    return ''
}

function Running-Games {
    $items = [Collections.Generic.List[object]]::new()
    $cim = @()
    try { $cim = @(Get-CimInstance Win32_Process -Filter "Name = 'java.exe' OR Name = 'javaw.exe'" -ErrorAction Stop) } catch {
        Paint '  Could not read Java process launch details.' 'Yellow'
    }
    foreach ($p in $cim) {
        $command = [string]$p.CommandLine
        $game = Get-GameDir $command
        $windowTitle = ''
        $started = ''
        try {
            $ps = Get-Process -Id ([int]$p.ProcessId) -ErrorAction Stop
            $windowTitle = [string]$ps.MainWindowTitle
            $started = $ps.StartTime.ToUniversalTime().ToString('o')
        } catch {}
        if (-not $game -and $command -notmatch '(?i)(minecraft|fabricmc|quiltmc|lwjgl|neoforge|forge|optifine|lunar)' -and $windowTitle -notmatch '(?i)minecraft') { continue }
        $items.Add([pscustomobject]@{
            pid=[int]$p.ProcessId
            process=[string]$p.Name
            started=$started
            title=$windowTitle
            gameDir=Root-At $game
            path=Hide-Home ([string]$p.ExecutablePath)
            cmd=$command
        })
    }
    return @($items.ToArray())
}

function Known-Instances {
    $folders = [Collections.Generic.List[string]]::new()
    if ($env:APPDATA) {
        foreach ($part in @('.minecraft','ModrinthApp\profiles','PrismLauncher\instances','MultiMC\instances','PolyMC\instances','ATLauncher\instances','.feather\profiles','gdlauncher_next\instances')) {
            $folders.Add((Join-Path $env:APPDATA $part))
        }
    }
    if ($env:USERPROFILE) { $folders.Add((Join-Path $env:USERPROFILE 'curseforge\minecraft\Instances')) }
    $seen = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($folder in $folders) {
        $one = Root-At $folder
        if ($one) { [void]$seen.Add($one) }
        if (-not (Test-Path -LiteralPath $folder -PathType Container)) { continue }
        foreach ($child in @(Get-ChildItem -LiteralPath $folder -Directory -ErrorAction SilentlyContinue | Select-Object -First 100)) {
            $one = Root-At $child.FullName
            if ($one) { [void]$seen.Add($one) }
        }
    }
    return @($seen)
}

function Choose-Target {
    Heading 'Active Minecraft'
    $list = @(Running-Games)
    if ($TargetPid -gt 0) {
        $matched = @($list | Where-Object { $_.pid -eq $TargetPid })
        if ($matched.Count -ne 1) { throw ('PID ' + $TargetPid + ' was not detected as a running Minecraft JVM.') }
        $script:Target = $matched[0]
    } elseif ($list.Count -eq 1) {
        $script:Target = $list[0]
    } elseif ($list.Count -gt 1) {
        for ($i=0;$i -lt $list.Count;$i++) {
            $item = $list[$i]
            Paint ('  [{0}] PID {1}  {2}  {3}' -f ($i+1),$item.pid,$item.title,(Hide-Home $item.gameDir)) 'White'
        }
        $choice=0
        $answer=Read-Host '  Choose the running instance number'
        if (-not [int]::TryParse($answer,[ref]$choice) -or $choice -lt 1 -or $choice -gt $list.Count) { throw 'Invalid process selection.' }
        $script:Target = $list[$choice - 1]
    } else {
        Paint '  No active Minecraft JVM found.' 'Yellow'
        if (-not (Confirm 'Continue with folder-only checks?')) { throw 'No process selected.' }
    }
    if ($script:Target) {
        Paint ('  Selected PID ' + $script:Target.pid + '  |  ' + $script:Target.title) 'Magenta'
        $script:Processes.Add([pscustomobject]@{
            pid=$script:Target.pid
            started=$script:Target.started
            title=$script:Target.title
            java=Hide-Home $script:Target.path
        })
    }
    if ($InstancePath) {
        $script:Root = Root-At $InstancePath
        if (-not $script:Root) { throw 'Specified -InstancePath does not look like a Minecraft game folder.' }
    } elseif ($script:Target -and $script:Target.gameDir) {
        $script:Root = $script:Target.gameDir
    } else {
        $found = @(Known-Instances)
        if ($found.Count -gt 0) {
            Paint '  Game directory was not identifiable from the active process.' 'Yellow'
            for ($i=0;$i -lt $found.Count;$i++) { Paint ('  [{0}] {1}' -f ($i+1),(Hide-Home $found[$i])) 'Gray' }
            $answer = Read-Host '  Choose a matching folder, enter a full path, or press Enter to skip'
            if ($answer) {
                $n=0
                if ([int]::TryParse($answer,[ref]$n) -and $n -ge 1 -and $n -le $found.Count) {
                    $script:Root = $found[$n - 1]
                } else { $script:Root = Root-At $answer }
                if (-not $script:Root) { throw 'Minecraft folder was not recognized.' }
            }
        } else {
            $answer=Read-Host '  Minecraft folder path, or Enter to skip'
            if ($answer) {
                $script:Root=Root-At $answer
                if (-not $script:Root) { throw 'Minecraft folder was not recognized.' }
            }
        }
    }
    if ($script:Root) { Paint ('  Linked instance: ' + (Hide-Home $script:Root)) 'White' }
    else { Paint '  No game folder linked. Live process checks can still run.' 'Yellow' }
}

$script:ClassPoolSource=@'
using System;
using System.IO;
using System.Text;
using System.Collections.Generic;
public static class MewoClassConstants
{
    static int U2(byte[] b, ref int i)
    {
        if (i + 2 > b.Length) throw new InvalidDataException("Truncated class.");
        int v = (b[i] << 8) | b[i + 1];
        i += 2;
        return v;
    }
    public static string[] Read(Stream stream)
    {
        using (var data = new MemoryStream())
        {
            var chunk = new byte[65536];
            int n;
            while ((n = stream.Read(chunk, 0, chunk.Length)) > 0)
            {
                if (data.Length + n > 2097152) return new string[0];
                data.Write(chunk, 0, n);
            }
            byte[] b = data.ToArray();
            if (b.Length < 10 || b[0] != 0xCA || b[1] != 0xFE || b[2] != 0xBA || b[3] != 0xBE) return new string[0];
            int i = 8, count = U2(b, ref i);
            var result = new List<string>();
            if (count > 12000) return result.ToArray();
            for (int cp = 1; cp < count; cp++)
            {
                if (i >= b.Length) break;
                int tag = b[i++];
                int advance = 0;
                if (tag == 1)
                {
                    int length = U2(b, ref i);
                    if (i + length > b.Length) break;
                    if (length <= 512) result.Add(Encoding.UTF8.GetString(b, i, length));
                    i += length;
                    continue;
                }
                if (tag == 3 || tag == 4 || tag == 9 || tag == 10 || tag == 11 || tag == 12 || tag == 17 || tag == 18) advance = 4;
                else if (tag == 5 || tag == 6) { advance = 8; cp++; }
                else if (tag == 7 || tag == 8 || tag == 16 || tag == 19 || tag == 20) advance = 2;
                else if (tag == 15) advance = 3;
                else break;
                if (i + advance > b.Length) break;
                i += advance;
            }
            return result.ToArray();
        }
    }
}
'@

function Module-Match([string]$Value) {
    if (-not $Value -or $Value.Length -gt 512) { return @() }
    $found = [Collections.Generic.List[object]]::new()
    $parts = @($Value -split '[\\./;:$\s<>()\[\],=\-]+')
    foreach ($part in $parts) {
        $key = ($part -replace '[^a-zA-Z0-9]', '').ToLowerInvariant()
        if ($script:GenericIndex.ContainsKey($key)) {
            $found.Add($script:GenericIndex[$key])
        }
    }
    return @($found.ToArray())
}

function Read-ClassConstants([IO.Compression.ZipArchiveEntry]$Entry) {
    if ($Entry.Length -gt 2097152) { return @() }
    if (-not ('MewoClassConstants' -as [type])) {
        Add-Type -TypeDefinition $script:ClassPoolSource -ErrorAction Stop
    }
    $stream=$Entry.Open()
    try { return @([MewoClassConstants]::Read($stream)) } finally { $stream.Dispose() }
}

function Get-ArchiveInfo([IO.Compression.ZipArchive]$Archive,[string]$Label) {
    $result = [ordered]@{ loader='Unknown'; modId=''; name=''; version=''; classes=0; packages=@(); modules=@(); embedded=0; error='' }
    if ($Archive.Entries.Count -gt 45000) { $result.error = 'Archive has too many entries.'; return [pscustomobject]$result }
    $clientHits = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    $moduleMap = @{}
    foreach ($item in $Archive.Entries) {
        $entryPath = $item.FullName.Replace('\','/')
        if ($entryPath.EndsWith('.class',[StringComparison]::OrdinalIgnoreCase)) {
            $result.classes++
            foreach ($rule in $script:Rules) {
                if ($entryPath -match $rule.package) { [void]$clientHits.Add($rule.id) }
            }
            $stem = [IO.Path]::GetFileNameWithoutExtension($entryPath)
            $stem = ($stem -split '\$')[0]
            foreach ($flag in @(Module-Match $stem)) {
                $key = $flag.name.ToLowerInvariant()
                if (-not $moduleMap.ContainsKey($key)) {
                    $moduleMap[$key] = [pscustomobject]@{ name=$flag.name; category=$flag.category; source='Class'; location=$entryPath }
                }
            }
            if ($item.Length -gt 0 -and $item.Length -le 2097152) {
                try {
                    foreach ($constant in @(Read-ClassConstants $item)) {
                        foreach ($flag in @(Module-Match $constant)) {
                            $key = $flag.name.ToLowerInvariant()
                            if (-not $moduleMap.ContainsKey($key)) {
                                $moduleMap[$key] = [pscustomobject]@{ name=$flag.name; category=$flag.category; source='Constant'; location=$entryPath }
                            }
                        }
                    }
                } catch {}
            }
        }
        if ($item.Length -gt 262144) { continue }
        if ($entryPath -in @('fabric.mod.json','quilt.mod.json','META-INF/mods.toml','META-INF/neoforge.mods.toml')) {
            try {
                $reader = [IO.StreamReader]::new($item.Open())
                try { $content = $reader.ReadToEnd() } finally { $reader.Dispose() }
                if ($entryPath -eq 'fabric.mod.json') {
                    $data = ConvertFrom-Json $content
                    $result.loader = 'Fabric'
                    $result.modId = [string]$data.id
                    $result.name = [string]$data.name
                    $result.version = [string]$data.version
                } elseif ($entryPath -eq 'quilt.mod.json') {
                    $data = ConvertFrom-Json $content
                    $result.loader = 'Quilt'
                    $result.modId = [string]$data.quilt_loader.id
                    $result.version = [string]$data.quilt_loader.version
                } else {
                    $result.loader = if ($entryPath -match 'neoforge') { 'NeoForge' } else { 'Forge' }
                    if ($content -match 'modId\s*=\s*"([^"]+)"') { $result.modId = $Matches[1] }
                    if ($content -match 'displayName\s*=\s*"([^"]+)"') { $result.name = $Matches[1] }
                    if ($content -match 'version\s*=\s*"([^"]+)"') { $result.version = $Matches[1] }
                }
            } catch {
                $result.error = 'Could not parse mod metadata.'
            }
        }
    }
    $result.packages = @($clientHits)
    $result.modules = @($moduleMap.Values)
    return [pscustomobject]$result
}

function Inspect-Jar([string]$Path) {
    $zip=$null
    try {
        $zip = [IO.Compression.ZipFile]::OpenRead($Path)
        $info = Get-ArchiveInfo $zip (Split-Path $Path -Leaf)
        $extra = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
        $modules = @{}
        foreach ($m in @($info.modules)) { $modules[$m.name.ToLowerInvariant()]=$m }
        $embeddedCount=0
        foreach ($entry in @($zip.Entries | Where-Object { $_.FullName -match '(?i)\.jar$' -and $_.Length -gt 0 -and $_.Length -le 8388608 } | Select-Object -First 8)) {
            try {
                $buffer=[IO.MemoryStream]::new()
                $stream=$entry.Open()
                try { $stream.CopyTo($buffer) } finally { $stream.Dispose() }
                $buffer.Position=0
                $nested=[IO.Compression.ZipArchive]::new($buffer,[IO.Compression.ZipArchiveMode]::Read,$true)
                try {
                    $embedded = Get-ArchiveInfo $nested $entry.FullName
                    $embeddedCount++
                    foreach ($id in @($embedded.packages)) { [void]$extra.Add($id) }
                    foreach ($m in @($embedded.modules)) {
                        $key=$m.name.ToLowerInvariant()
                        if (-not $modules.ContainsKey($key)) {
                            $modules[$key]=[pscustomobject]@{ name=$m.name; category=$m.category; source=$m.source; location=($entry.FullName + ' > ' + $m.location) }
                        }
                    }
                } finally { $nested.Dispose(); $buffer.Dispose() }
            } catch {}
        }
        $all=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
        foreach ($id in @($info.packages)) { [void]$all.Add($id) }
        foreach ($id in $extra) { [void]$all.Add($id) }
        return [pscustomobject]@{
            loader=$info.loader; modId=$info.modId; name=$info.name; version=$info.version
            classes=$info.classes; clientPackages=@($all); genericModules=@($modules.Values)
            embeddedJars=$embeddedCount; error=$info.error
        }
    } catch {
        return [pscustomobject]@{
            loader='Unknown'; modId=''; name=''; version=''; classes=0
            clientPackages=@(); genericModules=@(); embeddedJars=0; error=($_.Exception.Message + ' [line ' + $_.InvocationInfo.ScriptLineNumber + ': ' + $_.InvocationInfo.Line.Trim() + ']')
        }
    } finally { if ($zip) { $zip.Dispose() } }
}

function Check-Mods {
    Heading 'Mod and JAR analysis'
    if (-not $script:Root) {
        Mark 'mods' 'Skipped' 'No linked Minecraft instance.'
        return
    }
    $folder=Join-Path $script:Root 'mods'
    if (-not (Test-Path -LiteralPath $folder -PathType Container)) {
        Paint '  This Minecraft instance has no mods folder.' 'Gray'
        Mark 'mods' 'Unavailable' 'No mods directory.'
        return
    }
    $jars=@(Get-ChildItem -LiteralPath $folder -File -Filter '*.jar' -ErrorAction SilentlyContinue | Sort-Object Name | Select-Object -First 500)
    Paint ('  Checking ' + $jars.Count + ' mod JARs (including small embedded JARs).') 'Magenta'
    $done=0
    foreach ($file in $jars) {
        $done++
        $hash=''
        try { $hash = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash } catch {}
        $details = Inspect-Jar $file.FullName
        $mod = [pscustomobject]@{
            file=$file.Name; sha256=$hash; bytes=$file.Length
            modifiedUtc=$file.LastWriteTimeUtc.ToString('o'); loader=$details.loader
            id=$details.modId; name=$details.name; version=$details.version
            classes=$details.classes; embeddedJars=$details.embeddedJars
            clientPackages=@($details.clientPackages); genericModules=@($details.genericModules)
            error=$details.error
        }
        $script:Mods.Add($mod)
        if ($details.error) {
            Add-Finding 'Review' 'Mod' 'Unreadable mod archive' $file.Name '' $file.Name
            continue
        }
        foreach ($id in @($details.clientPackages)) {
            $rule=@($script:Rules | Where-Object { $_.id -eq $id } | Select-Object -First 1)
            $label=if ($rule.Count) { $rule[0].name } else { $id }
            Add-Finding 'Client' 'Mod' ($label + ' package') ($file.Name + ' contains a recognized package.') $id $file.Name
        }
        $text=($file.BaseName + ' ' + $details.modId + ' ' + $details.name)
        foreach ($rule in $script:Rules) {
            if ($text -match $rule.names -and @($details.clientPackages) -notcontains $rule.id) {
                Add-Finding 'Review' 'ModName' ($rule.name + ' name') ($file.Name + ' matches the client name; its class package did not match.') $rule.id $file.Name
            }
        }
        foreach ($flag in @($details.genericModules | Select-Object -First 35)) {
            $kind = if ($flag.source -eq 'Class') { 'Module' } else { 'String' }
            Add-Finding $kind $flag.category $flag.name ($file.Name + ' -> ' + $flag.location + ' [' + $flag.source + ']') '' $file.Name
        }
        if ($done % 10 -eq 0 -or $done -eq $jars.Count) {
            $percent=[int][Math]::Floor(100*$done/[Math]::Max(1,$jars.Count))
            Paint ('  JARs: ' + $done + '/' + $jars.Count + '  ' + $percent + '%') 'DarkMagenta'
        }
    }
    foreach ($duplicate in @($script:Mods.ToArray() | Where-Object { $_.id } | Group-Object -Property id | Where-Object { $_.Count -gt 1 })) {
        Add-Finding 'Info' 'Mods' 'Duplicate mod ID' ($duplicate.Name + ' occurs in multiple JARs.')
    }
    Mark 'mods' 'Completed' ($script:Mods.Count.ToString() + ' JARs checked; nested JARs up to 8 MiB, maximum eight per JAR.')
}

function Check-Jvm {
    Heading 'Live JVM'
    if (-not $script:Target) {
        Mark 'jvm' 'Skipped' 'No active process.'
        return
    }
    $cmd=[string]$script:Target.cmd
    foreach ($check in @(
        @{ label='Java agent'; pattern='(?i)(?:^|\s)-javaagent(?::|\s)' },
        @{ label='Native Java agent'; pattern='(?i)(?:^|\s)-agent(?:path|lib):' },
        @{ label='Bootstrap override'; pattern='(?i)-Xbootclasspath' },
        @{ label='Fabric additional mods'; pattern='(?i)-Dfabric\.(?:addMods|loadMods|classPathGroups)=' },
        @{ label='Mixin config override'; pattern='(?i)-D(?:mixin\.configs|fabric\.mixin\.configs)=' }
    )) {
        if ($cmd -match $check.pattern) {
            Add-Finding 'Review' 'JVM' $check.label ('PID ' + $script:Target.pid + ' uses this launch option; it can be legitimate.')
        }
    }
    foreach ($rule in $script:Rules) {
        if ($cmd -match $rule.names) {
            Add-Finding 'Review' 'Launch' ($rule.name + ' in JVM launch') 'Matching client name in launch options; confirm the target and path.' $rule.id ('PID ' + $script:Target.pid)
        }
    }
    Paint ('  PID ' + $script:Target.pid + '  |  Launch options checked') 'White'
    Mark 'jvm' 'Completed' 'Active process checked; raw launch arguments not saved.'
}

function Check-Modules {
    Heading 'Native DLLs'
    if (-not $script:Target) {
        Mark 'dlls' 'Skipped' 'No active process.'
        return
    }
    try { $loaded=@((Get-Process -Id $script:Target.pid -ErrorAction Stop).Modules) } catch {
        Mark 'dlls' 'Unavailable' 'Windows denied loaded module enumeration.'
        return
    }
    foreach ($item in @($loaded | Select-Object -First 550)) {
        $path=[string]$item.FileName
        if (-not $path) { continue }
        $system = ($env:WINDIR -and $path.StartsWith($env:WINDIR,[StringComparison]::OrdinalIgnoreCase))
        $program = ($env:ProgramFiles -and $path.StartsWith($env:ProgramFiles,[StringComparison]::OrdinalIgnoreCase))
        $signature='NotChecked'
        if (-not $system -and -not $program) {
            try { $signature=[string](Get-AuthenticodeSignature -LiteralPath $path).Status } catch { $signature='Unavailable' }
        }
        $script:DLLs.Add([pscustomobject]@{ name=[string]$item.ModuleName; path=Hide-Home $path; signature=$signature })
        if ($path -match '(?i)\\AppData\\Local\\Temp\\' -and $signature -notin @('Valid','Unavailable')) {
            Add-Finding 'Review' 'DLL' 'Unverified DLL from Temp' ($item.ModuleName + ' loaded into Minecraft; check the origin.')
        }
    }
    Paint ('  ' + $script:DLLs.Count + ' DLLs enumerated; unexpected locations reviewed.') 'White'
    Mark 'dlls' 'Completed' 'Loaded modules enumerated; native inline hooks are not byte-verified.'
}

function Check-Traces {
    Heading 'Leftover Minecraft traces'
    if (-not $script:Root) {
        Mark 'traces' 'Skipped' 'No linked game directory.'
        return
    }
    $looked=0
    foreach ($relative in @('mods','config')) {
        $path=Join-Path $script:Root $relative
        if (-not (Test-Path -LiteralPath $path -PathType Container)) { continue }
        foreach ($f in @(Get-ChildItem -LiteralPath $path -Force -ErrorAction SilentlyContinue | Select-Object -First 400)) {
            $looked++
            foreach ($rule in $script:Rules) {
                if ($f.Name -match $rule.names) {
                    Add-Finding 'Review' 'Trace' ($rule.name + ' file/config') ($relative + '/' + $f.Name + ' remains in this instance; it may be old.') $rule.id $f.Name
                    break
                }
            }
        }
        foreach ($f in @(Get-ChildItem -LiteralPath $path -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTimeUtc -Descending | Select-Object -First 200)) {
            if ($f.LastWriteTimeUtc -ge [DateTime]::UtcNow.AddDays(-30)) {
                $script:Timeline.Add([pscustomobject]@{ directory=$relative; name=$f.Name; modifiedUtc=$f.LastWriteTimeUtc.ToString('o') })
            }
        }
    }
    Paint ('  ' + $looked + ' mod/config names checked; ' + $script:Timeline.Count + ' recent timestamps.') 'White'
    Mark 'traces' 'Completed' 'Scoped to the selected Minecraft mods/config directory, not personal files.'
}

function Check-MacroTools {
    Heading 'Macro-capable software'
    $known=@('AutoHotkey','AutoHotkey64','AutoHotkey32','AutoIt3','PuloversMacroCreator')
    $found=@(Get-Process -Name $known -ErrorAction SilentlyContinue)
    foreach ($item in $found) {
        Add-Finding 'Info' 'Macros' 'Macro-capable process running' ($item.ProcessName + ' PID ' + $item.Id + '; not evidence that a Minecraft macro was active.')
    }
    Paint ('  ' + $found.Count + ' known macro-tool processes observed.') 'Gray'
    Mark 'macros' 'Completed' 'Checks process names only; no keyboard activity or macro files collected.'
}

function Check-Dns {
    Heading 'Optional DNS cache traces'
    if (-not (Confirm 'Look for three known client websites in the Windows DNS cache?')) {
        Mark 'dns' 'Skipped' 'Declined by player.'
        return
    }
    $sites=@(
        @{ name='Meteor Client'; rule='meteor'; domain='meteorclient.com' },
        @{ name='Wurst'; rule='wurst'; domain='wurstclient.net' },
        @{ name='LiquidBounce'; rule='liquidbounce'; domain='liquidbounce.net' }
    )
    try {
        $entries=@(Get-DnsClientCache -ErrorAction Stop | Select-Object -ExpandProperty Entry -Unique)
        $count=0
        foreach ($site in $sites) {
            foreach ($hostName in $entries) {
                if ($hostName -ieq $site.domain -or $hostName.EndsWith('.'+$site.domain,[StringComparison]::OrdinalIgnoreCase)) {
                    $count++
                    Add-Finding 'Info' 'DNS' 'Client website DNS record' ($site.name + ' website was resolved. This does not prove client use.') $site.rule $hostName
                }
            }
        }
        Paint ('  Matching client-site DNS records: ' + $count) 'White'
        Mark 'dns' 'Completed' 'Only three known website domains compared; other records discarded.'
    } catch {
        Mark 'dns' 'Unavailable' 'Windows DNS cache query unavailable.'
    }
}

$script:MemorySource=@'
using System;
using System.Text;
using System.Collections.Generic;
using System.Runtime.InteropServices;
public static class MewoMemoryScanner
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
    public class Result
    {
        public string[] Hits;
        public long Bytes;
        public int Pages;
    }
    [DllImport("kernel32.dll", SetLastError=true)]
    static extern IntPtr OpenProcess(uint rights, bool inherit, int pid);
    [DllImport("kernel32.dll", SetLastError=true)]
    static extern bool CloseHandle(IntPtr handle);
    [DllImport("kernel32.dll", SetLastError=true)]
    static extern UIntPtr VirtualQueryEx(IntPtr handle, IntPtr address, out Region region, UIntPtr size);
    [DllImport("kernel32.dll", SetLastError=true)]
    static extern bool ReadProcessMemory(IntPtr handle, IntPtr address, byte[] data, UIntPtr size, out UIntPtr received);
    public static Result Scan(int pid, string[] needles, int maxMiB)
    {
        if (IntPtr.Size != 8) throw new Exception("64-bit PowerShell required.");
        var handle = OpenProcess(0x0410, false, pid);
        if (handle == IntPtr.Zero) throw new Exception("Windows denied access to this Java process.");
        var hits = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        var buffer = new byte[262144];
        var bytes = 0L;
        var pages = 0;
        var max = maxMiB * 1024L * 1024L;
        try
        {
            var address = 0x10000UL;
            var limit = 0x00007FFFFFF00000UL;
            var regionSize = new UIntPtr((uint)Marshal.SizeOf(typeof(Region)));
            var singleByte = Encoding.GetEncoding(28591);
            while (address < limit && bytes < max)
            {
                Region region;
                if (VirtualQueryEx(handle, new IntPtr(unchecked((long)address)), out region, regionSize) == UIntPtr.Zero) break;
                if (region.RegionSize == 0) break;
                var next = region.BaseAddress + region.RegionSize;
                if (next <= address) break;
                var readAllowed = region.State == 0x1000 && (region.Protect & 0x100) == 0 && (region.Protect & 0x01) == 0 && (region.Protect & 0x02) == 0;
                if (readAllowed)
                {
                    var sample = Math.Min(region.RegionSize, 64UL * 1024UL * 1024UL);
                    var offset = 0UL;
                    var priorAscii = "";
                    var priorUnicode = "";
                    while (offset < sample && bytes < max)
                    {
                        var take = (int)Math.Min((ulong)buffer.Length, sample - offset);
                        take = (int)Math.Min(take, max - bytes);
                        if (take <= 0) break;
                        UIntPtr count;
                        var ok = ReadProcessMemory(handle, new IntPtr(unchecked((long)(region.BaseAddress+offset))), buffer, new UIntPtr((uint)take), out count);
                        var got = (int)count.ToUInt64();
                        if (ok && got > 0)
                        {
                            pages++;
                            bytes += got;
                            var ascii = priorAscii + singleByte.GetString(buffer,0,got);
                            var unicode = priorUnicode + Encoding.Unicode.GetString(buffer,0,got-got%2);
                            foreach (var needle in needles)
                            {
                                if (ascii.IndexOf(needle,StringComparison.OrdinalIgnoreCase)>=0 || unicode.IndexOf(needle,StringComparison.OrdinalIgnoreCase)>=0)
                                    hits.Add(needle);
                            }
                            priorAscii = ascii.Substring(Math.Max(0,ascii.Length-256));
                            priorUnicode = unicode.Substring(Math.Max(0,unicode.Length-256));
                        }
                        offset += (ulong)take;
                    }
                }
                address=next;
            }
        }
        finally { CloseHandle(handle); }
        return new Result { Hits=new List<string>(hits).ToArray(), Bytes=bytes, Pages=pages };
    }
}
'@

function Check-Memory {
    Heading 'Live JVM signature scan'
    if (-not $script:Target) { Mark 'memory' 'Skipped' 'No running Minecraft process.'; return }
    Paint '  Deep checks up to 512 MiB of readable JVM pages.' 'Yellow'
    Paint '  It inspects selected process memory; it does not save raw memory.' 'Gray'
    if (-not (Confirm 'Allow this additional JVM memory check?')) { Mark 'memory' 'Skipped' 'Declined by player.'; return }
    try {
        if (-not ('MewoMemoryScanner' -as [type])) { Add-Type -TypeDefinition $script:MemorySource -ErrorAction Stop }
    } catch {
        Mark 'memory' 'Unavailable' 'Native memory scanner could not be initialized.'
        return
    }
    $clientNeedles=@(
        'meteordevelopment/meteorclient','meteordevelopment.meteorclient',
        'net/ccbluex/liquidbounce','net.ccbluex.liquidbounce',
        'net/wurstclient','net.wurstclient','org/bleachhack','org.bleachhack',
        'thunder/hack','rusherhack','dev/fiki/forgehax','xyz/mathax/mathaxclient',
        'com/lambda/client','me/deftware','keystrokesmod'
    )
    $moduleNeedles=@('AimAssist','KillAura','TriggerBot','SilentAim','BowAimbot','MaceAura','ShieldBreaker','AutoCrystal','CrystalAura','CrystalMacro','AutoHitCrystal','AnchorAura','AnchorMacro','DoubleAnchor','AutoDTap','AutoTotem','AutoRetotem','HoverTotem','InventoryMove','NoFall','AutoClicker','AutoMine','ChestStealer','PlayerESP','StorageESP','BaseESP','XRay','Freecam','FakeLag','PingSpoof','GrimBypass')
    try {
        $out=[MewoMemoryScanner]::Scan([int]$script:Target.pid,[string[]](@($clientNeedles)+@($moduleNeedles)),512)
        $script:MemoryBytes=[long]$out.Bytes
        foreach ($hit in @($out.Hits)) {
            if ($moduleNeedles -contains $hit) {
                Add-Finding 'String' 'MemoryModule' $hit ('PID ' + $script:Target.pid + ' [Memory string]; not proof of an enabled module.') '' ('PID ' + $script:Target.pid)
            } else {
                $id=''
                foreach ($rule in $script:Rules) {
                    if ($hit -match $rule.package -or $hit -match $rule.id) { $id=$rule.id; break }
                }
                Add-Finding 'Memory' 'MemoryClient' 'Client package string' ($hit + ' found in sampled JVM memory.') $id ('PID ' + $script:Target.pid)
            }
        }
        Paint ('  Read ' + [Math]::Round($out.Bytes/1MB,1) + ' MiB across ' + $out.Pages + ' blocks. Found ' + @($out.Hits).Count + ' distinct strings.') 'Magenta'
        Mark 'memory' 'Completed' ('Sampled ' + [Math]::Round($out.Bytes/1MB,1) + ' MiB; not the entire heap.')
    } catch {
        Mark 'memory' 'Unavailable' ('Could not inspect the selected process: ' + $_.Exception.Message)
    }
}

function Verdict {
    $f=@($script:Findings.ToArray())
    $clients=@($f | Where-Object { $_.kind -eq 'Client' })
    $modules=@($f | Where-Object { $_.kind -eq 'Module' })
    $strings=@($f | Where-Object { $_.kind -eq 'Memory' })
    $moduleStrings=@($f | Where-Object { $_.kind -eq 'String' })
    $suspicious=@($f | Where-Object { $_.kind -eq 'Review' })
    $notes=@($f | Where-Object { $_.kind -eq 'Info' })
    $checked=@($script:Coverage.ToArray() | Where-Object { $_.status -eq 'Completed' })
    if ($clients.Count -gt 0) {
        $label='CHEAT CLIENT SIGNATURE FOUND'
        $meaning='Recognized client packages were found inside scanned JARs; that does not establish the client was enabled in combat.'
    } elseif ($modules.Count -gt 0) {
        $label='CHEAT MODULE FLAGS FOUND'
        $meaning='Classes named after known cheat modules were found in installed JARs. This identifies classes, not proof that a module ran.'
    } elseif ($strings.Count -gt 0) {
        $label='CLIENT STRINGS FOUND IN MEMORY'
        $meaning='Recognized client strings were found in sampled JVM memory. References can also produce matches.'
    } elseif ($moduleStrings.Count -gt 0 -or $suspicious.Count -gt 0) {
        $label='SUSPICIOUS STRINGS OR ARTIFACTS'
        $meaning='Module strings, mod names or other unconfirmed indicators need contextual review.'
    } elseif ($checked.Count -eq 0) {
        $label='SCAN INCOMPLETE'
        $meaning='No scan stage completed successfully.'
    } else {
        $label='NO DETECTIONS IN COMPLETED CHECKS'
        $meaning='Configured signatures did not match; this does not prove the machine is clean.'
    }
    return [pscustomobject]@{
        status=$label; meaning=$meaning; clientSignatures=$clients.Count
        moduleClasses=$modules.Count; moduleStrings=$moduleStrings.Count
        memoryStrings=$strings.Count; reviewFlags=$suspicious.Count; notes=$notes.Count
        hooks='NOT VERIFIED'; checksCompleted=$checked.Count; coverageCount=$script:Coverage.Count
    }
}

function Show-Result {
    $v=Verdict
    Heading 'MEWO VERDICT'
    $color=if ($v.clientSignatures -gt 0) { 'Red' } elseif ($v.moduleClasses -gt 0 -or $v.moduleStrings -gt 0 -or $v.memoryStrings -gt 0 -or $v.reviewFlags -gt 0) { 'Yellow' } else { 'Green' }
    Paint ('  ' + ('═' * 60)) $color
    Paint ('  ' + $v.status) $color
    Paint ('  ' + $v.meaning) 'White'
    Paint ('  ' + ('═' * 60)) $color
    Paint ('  Client JAR signatures  : ' + $v.clientSignatures) 'White'
    Paint ('  Cheat module classes  : ' + $v.moduleClasses) $(if ($v.moduleClasses) { 'Yellow' } else { 'Gray' })
    Paint ('  Module name strings   : ' + $v.moduleStrings) 'Gray'
    $memoryChecked=@($script:Coverage | Where-Object { $_.check -eq 'memory' -and $_.status -eq 'Completed' }).Count -gt 0
    $memoryText=if ($memoryChecked) { [string]$v.memoryStrings } else { 'NOT SCANNED' }
    Paint ('  JVM client strings    : ' + $memoryText) 'White'
    Paint ('  Other review flags    : ' + $v.reviewFlags) 'Gray'
    Paint '  Native inline hooks   : NOT VERIFIED' 'DarkYellow'
    Paint ('  Minecraft PID         : ' + $(if ($script:Target) { $script:Target.pid } else { 'NONE' })) 'Gray'
    if ($script:Root) { Paint ('  Game folder           : ' + (Hide-Home $script:Root)) 'Gray' }
    $moduleFindings=@($script:Findings | Where-Object { $_.kind -in @('Module','String') })
    Heading ('MODULE FLAGS (' + $moduleFindings.Count + ')')
    if ($moduleFindings.Count -eq 0) {
        Paint '  No configured module names found in checked class files or sampled memory.' 'Gray'
    } else {
        foreach ($category in @('Combat','Crystal','Totem','Movement','Automation','Vision','Bypass','MemoryModule')) {
            $items=@($moduleFindings | Where-Object { $_.category -eq $category })
            if ($items.Count -eq 0) { continue }
            Paint ('  ' + $category.ToUpperInvariant() + '  (' + $items.Count + ')') 'Magenta'
            foreach ($item in $items) {
                $source = if ($item.kind -eq 'Module') { 'CLASS' } else { 'STRING' }
                Paint ('    [' + $source + '] ' + $item.title) $(if ($item.kind -eq 'Module') { 'Yellow' } else { 'DarkYellow' })
                Paint ('      ' + $item.detail) 'Gray'
            }
        }
    }
    foreach ($kind in @('Client','Memory','Review')) {
        $group=@($script:Findings | Where-Object { $_.kind -eq $kind })
        if ($group.Count -eq 0) { continue }
        Heading ($kind + ' matches')
        foreach ($item in $group) { Paint ('  ' + $item.title + '  |  ' + $item.detail) $(if ($kind -eq 'Client') { 'Red' } else { 'Yellow' }) }
    }
    Heading 'Check coverage'
    foreach ($item in $script:Coverage) {
        $c=if ($item.status -eq 'Completed') { 'Green' } else { 'DarkYellow' }
        Paint ('  [' + $item.status + '] ' + $item.check + ' — ' + $item.detail) $c
    }
}

function Save-Report {
    $folder=$OutputDirectory
    if (-not $folder) {
        $docs=[Environment]::GetFolderPath('MyDocuments')
        if (-not $docs) { $docs=$env:TEMP }
        $folder=Join-Path $docs 'Mewo-Reports'
    }
    New-Item -ItemType Directory -Path $folder -Force | Out-Null
    $name=('Mewo-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '-' + $script:Session.Substring(0,8))
    $jsonPath=Join-Path $folder ($name+'.json')
    $txtPath=Join-Path $folder ($name+'.txt')
    $verdict=Verdict
    $data=[ordered]@{
        tool='Mewo Client Fucker'; version=$script:Version
        session=$script:Session; startedUtc=$script:Started.ToString('o')
        finishedUtc=[DateTime]::UtcNow.ToString('o'); mode=$Mode
        targetPid=if ($script:Target) { $script:Target.pid } else { $null }
        instance=Hide-Home $script:Root
        verdict=$verdict; process=@($script:Processes.ToArray())
        mods=@($script:Mods.ToArray()); dlls=@($script:DLLs.ToArray())
        timeline=@($script:Timeline.ToArray())
        coverage=@($script:Coverage.ToArray()); findings=@($script:Findings.ToArray())
        note='A positive artifact is not a cheating conviction; a negative result is not proof the system is clean.'
        privacy='Report stored locally; nothing uploaded.'
    }
    $data | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $jsonPath -Encoding UTF8
    $lines=[Collections.Generic.List[string]]::new()
    $lines.Add('MEWO CLIENT FUCKER  '+$script:Version)
    $lines.Add('VERDICT: '+$verdict.status)
    $lines.Add($verdict.meaning)
    $lines.Add(('Client JARs: {0} | Module classes: {1} | Module strings: {2} | JVM strings: {3} | Review: {4}' -f $verdict.clientSignatures,$verdict.moduleClasses,$verdict.moduleStrings,$verdict.memoryStrings,$verdict.reviewFlags))
    $lines.Add('Native inline hooks: NOT VERIFIED')
    $lines.Add('Target PID: '+$(if ($script:Target) { $script:Target.pid } else { 'Not selected' }))
    $lines.Add('Instance: '+(Hide-Home $script:Root))
    $lines.Add('')
    $lines.Add('FINDINGS')
    foreach ($finding in $script:Findings) { $lines.Add(('['+$finding.kind+'] '+$finding.title+' — '+$finding.detail)) }
    $lines.Add('')
    $lines.Add('CHECK COVERAGE')
    foreach ($check in $script:Coverage) { $lines.Add(('['+$check.status+'] '+$check.check+' — '+$check.detail)) }
    $lines.ToArray() | Set-Content -LiteralPath $txtPath -Encoding UTF8
    $hash=(Get-FileHash -LiteralPath $jsonPath -Algorithm SHA256).Hash
    $hash | Set-Content -LiteralPath ($jsonPath+'.sha256') -Encoding Ascii
    Heading 'Reports'
    Paint ('  TXT  ' + $txtPath) 'Gray'
    Paint ('  JSON ' + $jsonPath) 'Gray'
    Paint ('  SHA-256 ' + $hash) 'DarkGray'
    Paint '  Saved locally. No upload was made.' 'Green'
}

function Details {
    do {
        Paint ''
        Paint '  [M] Mods   [L] DLLs   [T] Timeline   [F] All findings   [Enter] Done' 'Magenta'
        $answer=Read-Host '  View'
        switch ($answer.ToUpperInvariant()) {
            'M' {
                Heading 'Mod files'
                foreach ($item in $script:Mods) {
                    Paint ('  '+$item.file+'  ['+$item.loader+'] '+$item.id+' '+$item.version) 'White'
                    if (@($item.clientPackages).Count) { Paint ('    Client packages: '+(@($item.clientPackages)-join ', ')) 'Red' }
                }
            }
            'L' {
                Heading 'DLLs'
                foreach ($item in $script:DLLs) { Paint ('  '+$item.name+'  '+$item.signature) 'Gray' }
            }
            'T' {
                Heading '30-day Minecraft file timeline'
                foreach ($item in $script:Timeline) { Paint ('  '+$item.modifiedUtc+' '+$item.directory+'/'+$item.name) 'Gray' }
            }
            'F' {
                Heading 'All observations'
                foreach ($item in $script:Findings) { Paint ('  ['+$item.kind+'] '+$item.title+': '+$item.detail) 'Gray' }
            }
        }
    } while ($answer -ne '')
}

function Run-Tests {
    Add-Type -AssemblyName System.IO.Compression
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $script:Coverage.Clear()
    $script:Findings.Clear()
    Mark 'mods' 'Completed' 'Fixture'
    if ((Verdict).status -ne 'NO DETECTIONS IN COMPLETED CHECKS') { throw 'Clean verdict failed.' }
    Add-Finding 'Client' 'Mod' 'Synthetic Meteor package' 'Fixture only' 'meteor' 'test.jar'
    if ((Verdict).status -ne 'CHEAT CLIENT SIGNATURE FOUND') { throw 'Client verdict failed.' }
    $script:Findings.Clear()
    Add-Finding 'Memory' 'MemoryClient' 'Synthetic client string' 'Fixture only' 'meteor' 'PID 1'
    if ((Verdict).status -ne 'CLIENT STRINGS FOUND IN MEMORY') { throw 'Memory verdict failed.' }
    $script:Findings.Clear()
    Add-Finding 'Module' 'Combat' 'AimAssist' 'fixture.jar -> classes/AimAssist.class [Class]' '' 'fixture.jar'
    if ((Verdict).status -ne 'CHEAT MODULE FLAGS FOUND') { throw 'Module class verdict failed.' }
    $script:Findings.Clear()
    Add-Finding 'String' 'Crystal' 'AutoCrystal' 'fixture.jar -> classes/Normal.class [Constant]' '' 'fixture.jar'
    if ((Verdict).status -ne 'SUSPICIOUS STRINGS OR ARTIFACTS') { throw 'Module string verdict failed.' }
    $script:Findings.Clear()
    $fixture=Join-Path ([IO.Path]::GetTempPath()) ('mewo-'+[guid]::NewGuid().ToString('N')+'.jar')
    try {
        $archive=[IO.Compression.ZipFile]::Open($fixture,[IO.Compression.ZipArchiveMode]::Create)
        try {
            $class=$archive.CreateEntry('meteordevelopment/meteorclient/Fixture.class')
            $class.Open().Dispose()
            $aim=$archive.CreateEntry('test/modules/AimAssist.class')
            $aim.Open().Dispose()
            $constantEntry=$archive.CreateEntry('test/modules/OtherModule.class')
            $constantStream=$constantEntry.Open()
            try {
                [byte[]]$header=@(0xCA,0xFE,0xBA,0xBE,0x00,0x00,0x00,0x41,0x00,0x02,0x01,0x00,0x0B)
                $constantStream.Write($header,0,$header.Length)
                $payload=[Text.Encoding]::ASCII.GetBytes('AutoCrystal')
                $constantStream.Write($payload,0,$payload.Length)
            } finally { $constantStream.Dispose() }
            $writer=[IO.StreamWriter]::new($archive.CreateEntry('fabric.mod.json').Open(),[Text.Encoding]::UTF8)
            try { $writer.Write('{"id":"fixture","name":"Test Mod","version":"1.0"}') } finally { $writer.Dispose() }
        } finally { $archive.Dispose() }
        $parsed=Inspect-Jar $fixture
        if ($parsed.loader -ne 'Fabric' -or $parsed.modId -ne 'fixture') { throw ('Fabric metadata test failed: ' + ($parsed | ConvertTo-Json -Compress -Depth 3)) }
        if (@($parsed.clientPackages) -notcontains 'meteor') { throw 'Client class match test failed.' }
        if (@($parsed.genericModules | Where-Object { $_.name -eq 'AimAssist' -and $_.source -eq 'Class' }).Count -ne 1) { throw ('AimAssist class match not detected: ' + ($parsed.genericModules | ConvertTo-Json -Compress)) }
        if (@($parsed.genericModules | Where-Object { $_.name -eq 'AutoCrystal' -and $_.source -eq 'Constant' }).Count -ne 1) { throw ('AutoCrystal constant pool match not detected: ' + ($parsed.genericModules | ConvertTo-Json -Compress)) }
        $testRoot=Join-Path ([IO.Path]::GetTempPath()) ('mewo-instance-'+[guid]::NewGuid().ToString('N'))
        try {
            $modsPath=Join-Path $testRoot 'mods'
            New-Item -Path $modsPath -ItemType Directory -Force | Out-Null
            Copy-Item -LiteralPath $fixture -Destination (Join-Path $modsPath 'fixture.jar')
            $script:Root=$testRoot
            $script:Findings.Clear()
            $script:Coverage.Clear()
            $script:Mods.Clear()
            $script:DLLs.Clear()
            $script:Timeline.Clear()
            Check-Mods
            if ((Verdict).status -ne 'CHEAT CLIENT SIGNATURE FOUND') { throw 'Full mod scan did not produce a client verdict.' }
            if ((Verdict).moduleClasses -lt 1 -or (Verdict).moduleStrings -lt 1) { throw 'Full mod scan did not expose module class and constant flags.' }
            Show-Result
            $script:OutputDirectory=Join-Path $testRoot 'reports'
            Save-Report
            if (@(Get-ChildItem -LiteralPath $script:OutputDirectory -Filter '*.json' -File).Count -ne 1) { throw 'JSON report was not saved.' }
            if (@(Get-ChildItem -LiteralPath $script:OutputDirectory -Filter '*.txt' -File).Count -ne 1) { throw 'Text report was not saved.' }
        } finally {
            Remove-Item -LiteralPath $testRoot -Recurse -Force -ErrorAction SilentlyContinue
            $script:Root=''
            $script:OutputDirectory=''
        }
    } finally { Remove-Item -LiteralPath $fixture -Force -ErrorAction SilentlyContinue }
    if (-not ('MewoMemoryScanner' -as [type])) { Add-Type -TypeDefinition $script:MemorySource -ErrorAction Stop }
    $script:Coverage.Clear()
    $script:Findings.Clear()
    Paint '  MEWO REBUILD SELF-TEST PASSED' 'Green'
}

function Main {
    if ($env:OS -ne 'Windows_NT') { throw 'Windows is required.' }
    Add-Type -AssemblyName System.IO.Compression
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    if (-not $script:ModeProvided) {
        Paint '  MEWO  —  CHOOSE MODE' 'Magenta'
        Paint '  [1] Quick  [2] Standard  [3] Deep' 'White'
        $answer=Read-Host '  Mode [2]'
        $script:Mode=switch ($answer) { '1' { 'Quick' } '3' { 'Deep' } default { 'Standard' } }
    }
    Banner
    Heading 'Consent'
    Paint '  Scans a selected Minecraft JVM and its linked mods/config files.' 'White'
    Paint '  Standard checks loaded DLLs. Deep optionally samples JVM memory' 'White'
    Paint '  and checks three client website names in local DNS cache.' 'White'
    Paint '  No unrelated files, browser activity, messages or passwords are collected.' 'White'
    Paint '  Findings stay on this computer until you choose to share them.' 'White'
    if (-not (Confirm 'Start this scan?')) { Paint '  Cancelled.' 'Yellow'; return }
    Choose-Target
    Heading 'Phase 1 | Running game'
    Check-Jvm
    Heading 'Phase 2 | Installed mods'
    Check-Mods
    Heading 'Phase 3 | Instance traces'
    Check-Traces
    if ($Mode -in @('Standard','Deep')) {
        Heading 'Phase 4 | Native modules'
        Check-Modules
        Check-MacroTools
    } else {
        Mark 'dlls' 'Skipped' 'Quick mode.'
        Mark 'macros' 'Skipped' 'Quick mode.'
    }
    if ($Mode -eq 'Deep') {
        Heading 'Phase 5 | Memory signatures'
        Check-Memory
        Heading 'Phase 6 | Client domain traces'
        Check-Dns
    } else {
        Mark 'memory' 'Skipped' 'Deep mode only.'
        Mark 'dns' 'Skipped' 'Deep mode only.'
    }
    Show-Result
    Save-Report
    Details
    Paint ''
    Paint '  Mewo finished.' 'Magenta'
}

try {
    if ($SelfTest) { Run-Tests } else { Main }
} catch {
    Paint ('  ERROR: '+$_.Exception.Message) 'Red'
    exit 1
}
