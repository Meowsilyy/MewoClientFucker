# Mewo Client Fucker

Minecraft screenshare scanner for Windows. Run it from CMD, pick a mode, choose the running game, and read the findings right in the terminal. Nothing gets uploaded.

The purple console UI takes inspiration from Meow Client Fucker. The scanner code is its own project.

## Run it

Open CMD and paste this:

```cmd
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $u='https://raw.githubusercontent.com/Meowsilyy/MewoClientFucker/main/MewoClientFucker.ps1'; $p=Join-Path $env:TEMP 'MewoClientFucker.ps1'; Invoke-WebRequest -Uri $u -OutFile $p; & $p"
```

The command downloads the latest script, then runs it. You can inspect [the script](MewoClientFucker.ps1) before you execute it. `-ExecutionPolicy Bypass` is limited to that PowerShell session; don't run code from people you don't trust.

Choose **Quick**, **Standard**, or **Deep** when Mewo starts. To skip the menu, add `-Mode Deep` (or `Quick` / `Standard`) after `& $p`.

## How the scan works

Mewo looks for **running Minecraft Java processes first**. If there's more than one, choose the PID you want. You can also specify `-ProcessId 1234` when running the script directly.

It tries to identify that process's game folder using its launch arguments. If it can't, you choose a matching folder or skip folder checks. It no longer assumes some random launcher profile is the active game.

| Mode | Checks |
| --- | --- |
| Quick | Current JVM launch settings, mod JAR hashes and metadata, selected Minecraft folder artifacts |
| Standard | Quick + loaded DLLs, local mod/config timestamps, macro-capable process names |
| Deep | Standard + optional sampled JVM-memory signature inspection, with a second consent prompt |

## What it can find

- Known public cheat-client names and class package identifiers in installed JARs.
- Combat, crystal, movement and other module-like class names for review, not as proof of cheating.
- Fabric, Quilt, Forge and NeoForge mod IDs, versions and hashes.
- Possible leftover client-named entries in the linked Minecraft `mods` and `config` directories.
- JVM launch options such as Java agents or additional Fabric mods.
- Accessible loaded DLLs and selected digital signature checks.
- Recent timestamps of relevant Minecraft mods and config files.
- A few known running macro-program process names.
- Optional bounded samples of the selected JVM's memory in Deep mode.

A filename or a string match isn't the same as catching a running cheat. Some mods share class names, unsigned DLLs can be legitimate, and a leftover folder doesn't prove recent use.

## Results

Everything is shown at the end of the scan in CMD: what was checked, which checks were skipped, client indicators, and things that need a closer look.

A copy is also saved in `Documents\Mewo-Reports` as JSON and TXT, with a SHA-256 checksum. Reports stay local unless the player chooses to share them.

## What it doesn't do

Mewo doesn't read passwords, Discord messages, browser history, screenshots or keystrokes, and doesn't silently upload data.

It doesn't currently recover deleted files, verify every inline hook byte, or detect every injection and private client. It won't give a reliable guilty/innocent verdict by itself.

## Credits

- **Meowsilyy** — Mewo project
- **Tonynoh** — Meow Client Fucker, the inspiration for the console look and detection approach
- **YarpLetapStan** — Yarp's Mod Analyzer, inspiration for local mod inspection
- **OpenAI / ChatGPT** — implementation help

Meow's unpublished executable signatures and private source code have not been copied.

## Development status

v0.5.0 is available in this repository. The code has been inspected, but a complete Windows PowerShell 5.1 test is still needed. If it throws an error, please open an issue with the console error and which scan mode you selected. Don't post reports containing personal information.
