# Mewo Client Fucker

Consent-based, read-only Minecraft screenshare inspection for Windows. The scanner is a standalone PowerShell script and does not require an installed executable.

## Run locally

Download `MewoClientFucker.ps1`, inspect the source, then run from CMD:

```cmd
powershell -NoProfile -File MewoClientFucker.ps1 -Mode Standard
```

Modes: `Quick`, `Standard`, and `Deep`. Deep mode requests separate consent before bounded JVM memory inspection. All modes request consent and store a local JSON report.

## One-command launcher

Once this repository is made public, the following CMD command downloads the script and launches it. Review the source first. Avoid blindly running changed remote code; an immutable commit URL and expected SHA-256 are safer for production distribution.

```cmd
powershell -NoProfile -Command "$u='https://raw.githubusercontent.com/Meowsilyy/MewoClientFucker/main/MewoClientFucker.ps1'; $p=Join-Path $env:TEMP 'MewoClientFucker.ps1'; Invoke-WebRequest -Uri $u -OutFile $p; Get-FileHash -Algorithm SHA256 $p; & $p -Mode Standard"
```

The command only works for unauthenticated users when the repository is public. It downloads a temporary `.ps1` script, not an EXE. It uses no ExecutionPolicy bypass; a machine's policy may prevent execution. A PowerShell script has the same need for trust, consent, and software review as any downloaded executable.

## Implemented

- Minecraft game-directory and running Java process discovery
- Fabric/Quilt/Forge/NeoForge mod JAR metadata and SHA-256 hashes
- Built-in client package/name indicators
- JVM argument indicators without saving full command lines
- Loaded native module enumeration, available signature checks, and selected file hashes
- Standard/Deep: recent selected instance mod/config file timestamps and basic macro-software process presence
- Deep: optional 64 MiB-per-process sampled memory signature check using embedded C# / Win32 APIs
- Correlation of identified client rule hits across available evidence categories
- Local-only JSON report and SHA-256 checksum

## Limitations

- A clean scan does not establish that no cheat exists.
- Positive indicators are not automatic proof of cheating.
- Legitimate mods, overlays, agents, and automation tools can produce findings.
- Version 0.2 does not perform byte-level inline hook comparison, comprehensive execution artifact recovery, cryptographic signing of scan reports, rule-update verification, or server/Paper integration.
- A locally generated SHA-256 checksum is not an authentication signature.
- A private repository cannot serve a public raw GitHub script without authentication.
- The script has not yet been runtime-tested on a Windows host, and Windows permission and process architecture restrictions can limit inspection.

The report is written to Documents\Mewo-Reports. Nothing is uploaded by the scanner. Players should review files before voluntarily sharing reports with staff.
