# Mewo's Client Fucker

Minecraft mod analyzer and screenshare checker for Windows. One CMD command, no installed app.

Built around a Yarp-style mod review: what JARs are present, which ones have recognizable cheat-client packages, which class files contain PvP module names, and which files have no public release match. Mewo also checks the active Java process and provides optional Windows execution-trace checks.

## Run

Open CMD and paste:

```cmd
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $u='https://raw.githubusercontent.com/Meowsilyy/MewoClientFucker/main/MewoLauncher.ps1'; $p=Join-Path $env:TEMP 'MewoLauncher.ps1'; Invoke-WebRequest -UseBasicParsing -Uri $u -OutFile $p; & $p"
```

Choose Quick, Standard or Deep when prompted. For Deep directly, add `-Mode Deep` after `& $p`. Read [the launcher](MewoLauncher.ps1) and [the scanner](MewoClientFucker.ps1) before running downloaded scripts. The command uses a process-scoped execution-policy override.

## What it checks

**Active Minecraft:** Finds running Minecraft Java processes by launch arguments and window title, then identifies the active PID. It uses that game's directory when available; otherwise you choose a folder or skip folder inspection.

**Mod JARs:** Reads Fabric, Quilt, Forge and NeoForge metadata. Checks up to 500 top-level JARs and small embedded JARs. Records SHA-256/SHA-512 hashes, recognizable client packages, class names, and names inside Java class constant pools.

**Module flags:** Groups names like AimAssist, KillAura, AutoCrystal, TriggerBot, AutoTotem, ESP modules, movement modules and bypass modules. Shows the exact JAR, class path and whether each hit was a class name or embedded string. A class existing does not prove it was enabled.

**Public file verification:** Standard and Deep can optionally compare SHA-512 hashes to the Modrinth API. This **sends only JAR hashes**, not files. An exact match means the file is recorded there; an unmatched file may simply be private, custom or hosted elsewhere. An unmatched file is **not** labeled tampered.

**Injection indicators:** Looks at Java agent launch options and loaded DLLs. Matches recognizable client names in loaded DLLs and running executable names, including Prestige Client. A matching filename is evidence to review, not confirmation of a native hook.

**Execution traces:** Deep mode can optionally inspect only filenames in Windows Prefetch and the top level of the temporary directory. A matching entry can suggest earlier execution, but it does not establish self-destruct, recent use, or cheating.

**Deep memory:** With separate consent, checks bounded samples from the selected JVM's readable memory pages for known client and module strings. Memory strings are references, not necessarily active code. Deep also offers a limited DNS-cache check for four public client domains.

## Result categories

| Section | What it shows |
| --- | --- |
| Client JAR signatures | Recognized client packages inside mod archives |
| Module flags | Named module classes and weaker embedded strings |
| Live injection indicators | Client-named running processes and loaded DLLs |
| Past execution traces | Matching Prefetch or temp filenames |
| Public mod verification | Exact Modrinth hashes, unmatched JARs, or skipped check |
| Coverage | What finished, what was skipped, and what was inaccessible |

Results appear inside CMD. You can also press **M** (mods), **L** (DLLs), **T** (Minecraft file timeline) or **F** (all findings) after the scan. Reports are saved locally as TXT and JSON under `Documents\Mewo-Reports`.

## What a result means

A detected client package is evidence that a matching JAR exists. A live matching DLL name or memory string is worth investigating. None of these alone prove the user cheated during a fight.

A clean scan isn't a guarantee. The scanner **does not currently verify native inline-hook bytes**, reconstruct memory after a client has completely unloaded, or prove that a self-destruct happened. Windows Prefetch may be disabled or inaccessible.

No chat messages, password data, keystrokes, screenshots or general browser history are read. The scanner doesn't upload its report.

## Credits

- **Meowsilyy** — Mewo project
- **YarpLetapStan** — Yarp's Mod Analyzer; inspiration for the mod review workflow and module-oriented findings
- **Tonynoh** — Meow Client Fucker; inspiration for some memory signature ideas
- **OpenAI / ChatGPT** — engineering and Windows test support

Yarp's public repository does not include a redistribution license. Mewo uses an independent implementation rather than rebranding or redistributing its source. There are no NaPvP promotions or server-specific mod-ban lists.

## Development

**v1.2.0.** The GitHub Actions workflow runs PowerShell 5.1 and PowerShell 7 parser checks and self-tests, including synthetic Fabric JARs, class-string matches, reports, and verdict logic. Real-world detection reliability still depends on the client, launcher and evidence available.
