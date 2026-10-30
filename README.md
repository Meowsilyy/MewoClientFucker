# Mewo Client Fucker

Minecraft screenshare scanner for Windows. Run one command, select the Minecraft process, and see what Mewo actually found.

Rebuilt from scratch for v1. No separate Meow EXE, no two-tool launcher, and no random folder selected behind your back.

## Run

Open CMD and paste:

```cmd
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $u='https://raw.githubusercontent.com/Meowsilyy/MewoClientFucker/main/MewoLauncher.ps1'; $p=Join-Path $env:TEMP 'MewoLauncher.ps1'; Invoke-WebRequest -UseBasicParsing -Uri $u -OutFile $p; & $p"
```

That downloads a short Mewo launcher, which downloads and starts the main PowerShell scanner. You can inspect [the launcher](MewoLauncher.ps1) and [the scanner](MewoClientFucker.ps1) first. This runs remote code, so only use it if you've reviewed and trust the repository. `-ExecutionPolicy Bypass` changes the policy for that process, not permanently.

For Deep mode, add `-Mode Deep` after `& $p`. Or just choose your mode from the menu.

## How Mewo scans

**Running Minecraft first.** It uses Windows process information to identify running Java Minecraft instances and choose the correct PID. If it can read the game directory from its launch options, it links that folder. If it can't, you choose the folder yourself or skip folder checks.

**Mod analyzer and module flags.** Checks up to 500 top-level mod JARs, including up to eight small embedded JARs per archive. Reads Fabric, Quilt, Forge and NeoForge metadata, class packages and SHA-256 hashes. It also inspects Java class names and class constant-pool strings for recognizable cheat-module names such as `AimAssist`, `KillAura`, `AutoCrystal`, `TriggerBot`, `AutoTotem`, `PlayerESP` and others. The terminal groups module flags by category and displays the mod JAR, class path and whether each match was a class name or embedded string.

**Live runtime.** Checks JVM launch options and accessible loaded native DLLs. Standard and Deep also note known macro-capable processes without reading keyboard input or scripts. Deep mode can scan bounded samples of readable JVM memory for client-package and module strings, with separate consent.

**Scoped traces.** Checks selected Minecraft mods/config names and recent file timestamps. Deep mode can optionally check three known client website domains in the local Windows DNS cache. A leftover file or DNS record is not proof a client was used.

## Scan modes

| Mode | What runs |
| --- | --- |
| Quick | Active Minecraft process, JVM launch, linked mod JARs, leftover config/mod names |
| Standard | Quick + loaded DLL review |
| Deep | Standard + optional JVM memory strings and optional client-site DNS cache |

## Results

Mewo prints a verdict directly in CMD, including a dedicated **MODULE FLAGS** section grouped by Combat, Crystal, Totem, Movement, Automation, Vision and Bypass. A module class name is a stronger artifact than an embedded string, but neither proves the module was enabled during gameplay.

Mewo prints these verdict labels:

- **CHEAT CLIENT SIGNATURE FOUND** — recognizable client package in a scanned JAR
- **CHEAT MODULE FLAGS FOUND** — classes named after known cheat modules were found in scanned JARs
- **CLIENT STRINGS FOUND IN MEMORY** — client-related strings matched sampled JVM memory
- **SUSPICIOUS STRINGS OR ARTIFACTS** — weaker names, constant-pool strings, traces, or runtime findings
- **NO DETECTIONS IN COMPLETED CHECKS** — no configured signatures matched the checks that completed
- **SCAN INCOMPLETE** — no scan stage completed

It shows the actual evidence and which checks succeeded or were skipped. Native inline hooks are marked **NOT VERIFIED**: DLL enumeration and Java agents are not the same thing as byte-level hook detection.

Press **M**, **L**, **T**, or **F** after the scan to browse mod files, DLLs, recent Minecraft file timestamps, or all findings. Press Enter to close the viewer.

Reports also go to `Documents\Mewo-Reports` as TXT and JSON. Everything is local. Nothing gets uploaded.

## What Mewo doesn't do

It does not give guaranteed guilty/innocent judgments, recover deleted files, prove when cheats were used, or detect every private/injected client. A negative scan is not an innocence certificate. A package signature means a matching artifact was found; it doesn't prove someone used it in a fight.

No passwords, chat messages, browser history, screenshots, or keystrokes are collected. The scanner doesn't install a service or persist in the background.

## Credits

- **Meowsilyy** — Mewo Client Fucker
- **YarpLetapStan** — Yarp's Mod Analyzer; inspiration for instance and JAR investigation
- **Tonynoh** — Meow Client Fucker; inspiration for memory signature and generic detection concepts, and the console aesthetic
- **OpenAI / ChatGPT** — development and testing assistance

This is an independent implementation. Meow's closed-source EXE and unpublished signature database aren't repackaged here.

## Development

v1.1.0 module-flag update. Windows PowerShell 5.1 and PowerShell 7 syntax and self-tests run through [GitHub Actions](../../actions). The tests cover synthetic verdicts, Fabric JAR recognition and memory helper compilation. Actual launcher/runtime accuracy still needs real Minecraft test cases.
