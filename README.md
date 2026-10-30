# Mewo Client Fucker

A Minecraft screenshare scanner for Windows. One PowerShell script, no separate EXE to install.

Built for server staff who want actual evidence instead of banning somebody because their mods folder looks weird.

Inspired by **Meow Client Fucker** and **Yarp's Mod Analyzer**. Mewo's checks and code are independently implemented, not extracted from Meow's executable.

## Run it

The GitHub repository must be **public** for the CMD command below to work without a GitHub login.

Open Command Prompt and paste:

```cmd
powershell -NoProfile -Command "$ErrorActionPreference='Stop'; $u='https://raw.githubusercontent.com/Meowsilyy/MewoClientFucker/main/MewoClientFucker.ps1'; $p=Join-Path $env:TEMP 'MewoClientFucker.ps1'; Invoke-WebRequest -Uri $u -OutFile $p; & $p -Mode Standard"
```

This downloads a temporary `.ps1` file and runs it. If the download fails, it stops instead of trying to run a missing file. Review the script before running any remote code.

For a local copy:

```cmd
powershell -NoProfile -File MewoClientFucker.ps1 -Mode Standard
```

Your Windows PowerShell execution policy may require you to approve local scripts. Mewo doesn't install a service or keep running after the scan.

## Scan modes

| Mode | Checks |
| --- | --- |
| Quick | Minecraft instance, JVM launch arguments, JAR signatures, hashes, and selected installation artifacts |
| Standard | Quick plus DLL/module review, Minecraft mod/config timestamps, and known macro-software process names |
| Deep | Standard plus an optional, separately approved bounded live JVM memory check |

## What it checks

- Finds likely running Minecraft Java processes and game directories.
- Reads Fabric, Quilt, Forge, and NeoForge mod metadata.
- Hashes top-level mod JARs and checks known client class package identifiers.
- Flags recognizable generic module class names across combat, crystals, movement, automation, and ESP for **review**.
- Reviews duplicate mod identifiers and unusual filenames in the instance's mods folder.
- Identifies selected JVM agent and classpath override arguments.
- Lists accessible Minecraft DLLs and reviews selected native-module signatures.
- Builds a short timeline from mod/config file timestamps.
- Looks for a small set of running macro-capable applications.
- Deep mode can inspect up to 64 MiB of selected Java process memory for configured strings, after separate permission.
- Correlates configured client identifiers across available evidence categories.
- Saves JSON, a readable TXT summary, and a SHA-256 checksum to `Documents\Mewo-Reports`.

## What it doesn't check

- It doesn't read Discord messages, browsers, passwords, chats, screenshots, or keystrokes.
- It doesn't upload files or scan reports.
- It doesn't recover deleted files or search all Windows history.
- It doesn't implement byte-for-byte inline hook verification, a kernel driver, or a Paper server integration.
- It doesn't identify every cheat or prove someone is innocent.
- A class name, unfamiliar DLL, macro application, or modified timestamp isn't automatically cheating.

A player gets to review the requested scan and their report before they choose to share it. Staff should check the evidence and context themselves.

## Credits

- **Meowsilyy** — Mewo Client Fucker project.
- **Tonynoh** — original Meow Client Fucker; inspiration for the large purple console style and detection concepts.
- **YarpLetapStan** — Yarp's Mod Analyzer; inspiration for instance/JAR investigation.
- **OpenAI / ChatGPT** — assistance with the initial scanner implementation and documentation.

No private Meow executable code or undisclosed signature database has been copied into Mewo.

## Current version

**v0.4.0.** The code is committed, but this revision has not yet been runtime-tested on a Windows machine. Please report the full console error if you encounter one.

## Public CMD launcher

If raw.githubusercontent.com responds with 404, open your repository on GitHub, then go to **Settings → General → Danger Zone → Change repository visibility → Public**. Only do that if you're comfortable publishing the complete source.
