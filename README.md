# Mewo Client Fucker

A Windows Minecraft screenshare scanner. One CMD command, a purple terminal, and an actual result at the end instead of a wall of random warnings.

It checks a running Minecraft process first. If it finds the game folder, it also inspects the mods and relevant files. Nothing gets uploaded.

## One-command launcher (Mewo + original Meow)

If you're testing a client that Mewo still misses, use the launcher. It can run both scanners from one CMD command:

```cmd
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $u='https://raw.githubusercontent.com/Meowsilyy/MewoClientFucker/main/MewoLauncher.ps1'; $p=Join-Path $env:TEMP 'MewoLauncher.ps1'; Invoke-WebRequest -UseBasicParsing -Uri $u -OutFile $p; & $p"
```

Choose **1** to run Mewo and then the official Meow Client Fucker, **2** for Mewo only, or **3** for Meow only. Each scanner asks permission. You can also run the launcher with `-Mode Deep` to make Mewo start in Deep mode.

The Meow option downloads **Meow Client Fucker V1.1 directly from [Tonynoh's release](https://github.com/MeowTonynoh/MeowClientFucker/releases/tag/V1.1)**. It checks the file's SHA-256 against the checksum published in GitHub release metadata and refuses to execute a mismatch. It is a closed-source third-party EXE: verification only confirms matching bytes, **not that the software is safe**. Read the original release information before agreeing.

This isn't a secretly renamed copy of Meow. Meow runs as Meow, gets proper credit, and its output stays separate from Mewo's. We haven't been given permission or source code to modify and redistribute Meow's binary as our own.

## Run

Open **Command Prompt** and paste:

```cmd
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $u='https://raw.githubusercontent.com/Meowsilyy/MewoClientFucker/main/MewoClientFucker.ps1'; $p=Join-Path $env:TEMP 'MewoClientFucker.ps1'; Invoke-WebRequest -Uri $u -OutFile $p; & $p"
```

This downloads and runs the PowerShell script. No separate EXE needs installing. You can read [the script](MewoClientFucker.ps1) before running it. PowerShell's execution-policy override only applies to this session; don't run random scripts you haven't checked.

Pick **Quick**, **Standard** or **Deep** when it opens, then approve the scope of the scan. When more than one Minecraft process is running, select the PID. Mewo won't quietly choose some unrelated launcher folder.

If you already know the mode, replace `& $p` with `& $p -Mode Deep`.

## What it checks

| Mode | Included checks |
| --- | --- |
| Quick | Current Minecraft Java process, JVM launch options, mod JAR names/classes/metadata/hashes, linked instance artifacts |
| Standard | Quick plus loaded DLLs, selected DLL signatures, mod/config file timestamps, macro-program process names |
| Deep | Standard plus separate opt-in JVM-memory signature scanning and limited Windows DNS-cache checks for three known client-site domains |

Mewo reads Java client-related package paths from mod JARs and compares them to its built-in known-client rules. It checks recognizable filenames, mod IDs, and some generic module class names too. Name-only hits are weaker and deliberately shown separately.

Deep mode looks for specific known-client and generic module strings inside **bounded, sampled portions of the selected JVM's memory**. A memory string might only be referenced by other software, so it isn't automatically treated as an active cheat.

The optional DNS check only keeps matching records for `meteorclient.com`, `wurstclient.net` and `liquidbounce.net`. Visiting a website is not evidence of running its client.

## Reading the result

Mewo displays a result in the CMD window:

| Result | Meaning |
| --- | --- |
| **CLIENT JAR SIGNATURE FOUND** | A known client package was found inside a scanned mod JAR |
| **CLIENT STRINGS DETECTED** | A client-related string matched in sampled JVM memory; the source needs review |
| **POSSIBLE CHEAT INDICATORS** | A name, leftover config, JVM-agent flag, or similar unconfirmed indicator appeared |
| **NO CHEAT INDICATORS FOUND** | Nothing matched the configured rules in checks that actually ran |
| **SCAN INCOMPLETE** | Neither the JVM nor mod files could be checked successfully |

Underneath, it shows **cheat mod matches, client memory strings, generic module strings, file traces, agent flags, and scan coverage**.

For hook-related checks, it reports JVM agent flags. Native inline hooks are marked **NOT VERIFIED** because Mewo does not yet compare live executable bytes to a trusted baseline. An unsigned DLL is not proof of hooking.

To browse the full local report in CMD, press **M** for mod JARs, **D** for loaded DLLs, or **T** for the file timeline. Press Enter to exit.

It also writes JSON and a readable text summary under `Documents\Mewo-Reports`, with a separate SHA-256 checksum.

## What it doesn't do

It doesn't scan all RAM, recover deleted files, check every possible cheat, or make a guaranteed guilty/innocent decision. It doesn't secretly read chats, browser history, passwords, screenshots, or keystrokes. It doesn't upload reports. Players choose whether to share their results with staff.

A client package inside a JAR is meaningful evidence about that file. It does **not**, by itself, prove that someone enabled cheats during a fight. A leftover config or generic class name is weaker evidence.

## Testing

The repository runs Windows GitHub Actions on each push:

- PowerShell 5.1 parser and self-tests
- PowerShell 7 parser and self-tests
- Synthetic clean, client-signature, memory-string, leftover-trace and incomplete-scan verdict tests
- A generated Fabric JAR fixture to check mod metadata, class counting and client-package detection
- Compilation of the native-memory C# helper

These tests catch parser, classification and basic JAR-handling problems. They don't replace testing on real Minecraft installations with different launchers and mods.

## Credits

- **Meowsilyy** — Mewo project
- **Tonynoh** — Meow Client Fucker, inspiration for the terminal look and detection concepts
- **YarpLetapStan** — Yarp's Mod Analyzer, inspiration for launcher and mod investigation
- **OpenAI / ChatGPT** — assistance with implementation and tests

Mewo uses its own scanner implementation. Meow's unpublished executable, private detection strings and hidden database haven't been extracted or copied.

## Version

**v0.6.0**. See [GitHub Actions](../../actions) for the latest Windows test results.
