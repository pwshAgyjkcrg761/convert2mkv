# ==============================================================================
# SCRIPT: convert2mkv.ps1
# VERSION: 2026.06.24__14.38.00
# TARGET: PowerShell 7.6.3 LTS
#
# Copyright (C) 2026 pwshAgyjkcrg761
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# ==============================================================================
# <PROTECTED>
# ==============================================================================
# AI INSTRUCTIONS v2026.06.24__06.54.45 : 
#
# 1. MESSAGE STAMP: 
#    - Every response containing code MUST begin with a standalone version stamp.
#    - Use CHICAGO TIME (Central Time), 24-hour clock.
#    - Format: YYYY.MM.DD__HH.MM.SS.
#    - CRITICAL: Use the time provided in the prompt or at https://www.timeanddate.com/worldclock/usa/chicago. Ensure minutes are exact.
#
# 2. VERSION SNIPPET PROHIBITION:
#    - DO NOT provide code snippets, anchors, or steps to update the script's internal VERSION comment or $scriptVersion variable. 
#    - The user handles internal file versioning manually based on the Message Stamp.
#
# 3. SCRIPT OUTPUT (SURGICAL FIXES ONLY):
#    - Provide minimal, highly targeted, surgical edits. Do not rewrite large blocks or entire functions.
#    - Always use a codebox with a copy button.
#    - Multiple modifications MUST be presented strictly ONE step at a time. Wait for user confirmation before proceeding to the next step. 
#    - DO NOT modify or refactor any code inside <PROTECTED> tags.
#
# 4. VERBATIM ANCHOR PROTOCOL (FOR NOTEPAD++):
#    - To facilitate "Find" in Notepad++, always structure edits with:
#      - "Verbatim Anchor (Before)" - The exact lines of existing code immediately before the change.
#      - "Verbatim Anchor (After)" - The exact lines of existing code immediately after the change.
#      - "Snippet to REPLACE" - The exact code block to be deleted.
#      - "What to PASTE in its place" - The new code block to be inserted.
#    - Do not summarize, truncate, or refactor the existing code used as an anchor.
#    - Match spaces, comments, and symbols exactly as they appear in the file.
#
# 5. CONTENT PRESERVATION:
#    - Do not remove, modify, or strip out telemetry data or DevDebug information from any provided code.
#==============================================================================
#==============================================================================
# </PROTECTED>

param(
    [Parameter(Mandatory=$false, Position=0, ValueFromRemainingArguments=$true)]
    [string[]]$Path,

    [Parameter(Mandatory=$false, ValueFromRemainingArguments=$false)]
    [string]$Save,

    [switch]$Search,

    [Alias("ep")]
    [switch]$excludePaths,

    [Alias("mkv")]
    [switch]$MkvWithExternalSubtitles,
    
    # Global Debugging Param
    [alias("Dev", "DevD", "DBG", "DDBG")]
    [switch]$DevDebug,

    [alias("h", "help")]
    [switch]$Manual
)

# --- GLOBAL VERSION DEFINITION ---
$scriptVersion = "2026.06.24__14.38.00"

# Force UTF-8 for international character support in terminal and pipelines
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

if ($DevDebug) {
    $ts = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $devLogDir = Join-Path $PSScriptRoot "convert2mkv_logs\DevDebug-Terminal_Logs"
    if (-not (Test-Path $devLogDir)) { New-Item -ItemType Directory -Path $devLogDir -Force | Out-Null }
    $devLogFile = Join-Path $devLogDir "convert2mkv_DevDebug-Terminal_$($ts)-log.txt"
    Start-Transcript -Path $devLogFile -Append -Force | Out-Null
}

if ($PSVersionTable.PSVersion -lt [version]"7.6.0") {
    Write-Host "ERROR: Running on version $($PSVersionTable.PSVersion). This script requires at least 7.6.0." -ForegroundColor DarkRed
    Read-Host "Press Enter to exit"; exit
}

function Initialize-NaturalSort {
    $NaturalSortDefinition = @'
    using System;
    using System.Collections;
    using System.Collections.Generic;
    using System.Runtime.InteropServices;

    public class NaturalSort : IComparer, IComparer<string> {
        [DllImport("shlwapi.dll", CharSet = CharSet.Unicode)]
        public static extern int StrCmpLogicalW(string psz1, string psz2);

        public int Compare(string x, string y) {
            return StrCmpLogicalW(x ?? string.Empty, y ?? string.Empty);
        }

        public int Compare(object x, object y) {
            string sx = x?.ToString() ?? string.Empty;
            string sy = y?.ToString() ?? string.Empty;
            return StrCmpLogicalW(sx, sy);
        }
    }
'@
    if (-not ([System.Management.Automation.PSTypeName]"NaturalSort").Type) {
        Add-Type -TypeDefinition $NaturalSortDefinition
    }
}

function Get-ExclusionList {
    param([string]$ExcludeFile)
    
    if (-not (Test-Path $ExcludeFile)) {
        @("# FILE: convert2mkv__Excluded-Paths.txt",
          "# SCRIPT: convert2mkv.ps1",
          "# DESCRIPTION: Add full folder paths here to skip them during audit.",
          "# FORMAT: One path per line. No wildcards. No trailing slashes.",
          "# ",
          "# Example below this line. Remove the # to enable the line.",
          "# B:\Media\Movies\Sample_Folder",
          "") | Out-File $ExcludeFile -Encoding utf8BOM -Force
        return @()
    }

    return Get-Content $ExcludeFile | ForEach-Object { $_.Trim() } | Where-Object { 
        -not [string]::IsNullOrWhiteSpace($_) -and -not $_.StartsWith("#") 
    } | ForEach-Object { $_.TrimEnd('\') }
}

function Show-ProjectManual {
    param($scriptVersion)

    # $True means DarkCyan, $False means DarkMagenta
    $global:altColorToggle = $true  

    $PrintManualBlock = {
        param(
            [string]$FlagLine,
            [string[]]$DescLines,
            [string]$ForceDescColor = $null
        )
        
        # 1. Print the Flag in DarkGreen
        Write-Host $FlagLine -ForegroundColor DarkGreen
        
        # 2. Determine description color
        $currentColor = if ($ForceDescColor) { $ForceDescColor } else { 
            if ($global:altColorToggle) { "DarkCyan" } else { "DarkMagenta" } 
        }
        
        # 3. Print the description lines
        foreach ($line in $DescLines) {
            Write-Host $line -ForegroundColor $currentColor
        }
        
        if (-not $ForceDescColor) {
            $global:altColorToggle = -not $global:altColorToggle
        }
    }

    Clear-Host


    Write-Host "============================================================" -ForegroundColor Cyan
               " convert2mkv.ps1 v$scriptVersion  ",
               " MANUAL & USAGE GUIDE" | ForEach-Object { Write-Host $_ -ForegroundColor DarkMagenta }
    Write-Host " Copyright (C) 2026 pwshAgyjkcrg761`n" -ForegroundColor DarkCyan
    
     " This program is free software: you can redistribute it and/or",
     " modify it under the terms of the GNU General Public License as",
     " published by the Free Software Foundation, either version 3 of",
     " the License, or (at your option) any later version."  | ForEach-Object { Write-Host $_ -ForegroundColor DarkMagenta }
    Write-Host "============================================================" -ForegroundColor Cyan
    
    Write-Host "`n OVERVIEW:" -ForegroundColor DarkYellow
     "  This utility is a high-speed media conversion tool designed to batch-convert",
     "  various video containers into the Matroska (MKV) format. It automatically",
     "  identifies external subtitle files and remuxes them into the final output,",
     "  ensuring all media assets are consolidated into a single, high-fidelity file.",
     "",
     "  The script logic supports two primary modes:",
     "  1. SEARCH: Scans directories to identify compatible video and subtitle files.",
     "  2. CONVERT: Performs the remuxing operation using mkvmerge.`n" | ForEach-Object { Write-Host $_ -ForegroundColor DarkMagenta }
    
    Write-Host " DEPENDENCIES:" -ForegroundColor DarkYellow
    "  • MKVToolNix (mkvmerge): Required for remuxing streams and attaching", 
    "    external subtitle tracks to the MKV container.`n" | ForEach-Object { Write-Host $_ -ForegroundColor DarkGray }
    
    Write-Host "`n USAGE:" -ForegroundColor DarkYellow
    Write-Host "  .\convert2mkv.ps1 [Flags] -Path 'G:\Media'" -ForegroundColor DarkGreen
    
    Write-Host "`n USAGE EXAMPLES:`n" -ForegroundColor DarkYellow
    
    Write-Host "  Standard Conversion (Create _updated-mkv sibling):`n" -ForegroundColor DarkGray
    Write-Host "    .\convert2mkv.ps1 -Path 'G:\Media\Movies'`n" -ForegroundColor DarkMagenta
    
    Write-Host "  Convert and Save to Specific Directory:`n" -ForegroundColor DarkGray
    Write-Host "    .\convert2mkv.ps1 -Path 'G:\Media\Movies' -Save 'D:\Final_MKVs'`n" -ForegroundColor DarkCyan
    
    Write-Host "  Search Mode (Search for containers and external subs):`n" -ForegroundColor DarkGray
    Write-Host "    .\convert2mkv.ps1 -Search -Path 'G:\Media\TV'`n" -ForegroundColor DarkMagenta

    Write-Host "  Process MKVs with External Subtitles:`n" -ForegroundColor DarkGray
    Write-Host "    .\convert2mkv.ps1 -mkv -Path 'G:\Media\Anime'`n" -ForegroundColor DarkCyan
    
    Write-Host "`n CORE FLAGS:`n" -ForegroundColor DarkYellow

    &$PrintManualBlock "  -Path <string>" @(
    "      Defines the target directory or directories. The script recursively",
    "      scans all subfolders for supported video files.`n"
)

    &$PrintManualBlock "  -Save <string>" @(
    "      Optional destination directory. If used, all converted files will be",
    "      mirrored into this location while preserving subfolder structures.`n"
)    
                        
    &$PrintManualBlock "  -Search" @(
    "      Enables 'Search Mode'. Instead of converting, the script logs all",
    "      found video files and their matching external subtitles to a text file.`n"
)
    
    &$PrintManualBlock "  -excludePaths | -ep" @(
    "      Enables the exclusion engine. Skips directories listed in",
    "      'convert2mkv__Excluded-Paths.txt'.`n"
)

    &$PrintManualBlock "  -MkvWithExternalSubtitles | -mkv" @(
    "      Extends the scanner to include existing MKV files, but only if",
    "      matching external subtitle files are found in the same folder.`n"
)

    &$PrintManualBlock "  -DevDebug | -Dev | -DevD | -DBG" @(
    "      Exposes internal logic, file evaluation traces, and mkvmerge",
    "      discovery processes for troubleshooting.`n"
)

    &$PrintManualBlock "  -Manual | -h | -help" @(
    "      Displays this manual. The one you are reading right now.`n"
)

    Write-Host "`n NOTES:" -ForegroundColor DarkYellow
    "  * SUBTITLES: Automatically prioritizes .ass and .ssa over .srt.",
    "  * LOGS: Search reports are saved to: convert2mkv_logs\Search_Logs" | ForEach-Object { Write-Host $_ -ForegroundColor DarkGray }
    
    Write-Host "`n============================================================" -ForegroundColor Cyan
    Write-Host " Press any key to exit..." -ForegroundColor DarkYellow
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit
}

function Write-InlineProgress {
    param(
        [int]$Current,
        [int]$Total,
        [string]$Message
    )
    # Prevent Divide-by-Zero if no files are found
    if ($Total -eq 0) { $percent = 0 } 
    else { $percent = [Math]::Min(100, [Math]::Max(0, [int]($Current / $Total * 100))) }
    $width = 30 
    $done = [Math]::Min($width, [int]($percent / 100 * $width))
    $left = $width - $done
    
    $bar = ("█" * $done) + ("░" * $left)
    # Time Calculations
    $elapsed = [DateTime]::Now - $script:SessionStartTime
    $te = "{0:hh\:mm\:ss}" -f $elapsed
    
    $tr = "--:--:--"
    if ($Current -gt 0) {
        $secPerFile = $elapsed.TotalSeconds / $Current
        $remainingSecs = $secPerFile * ($Total - $Current)
        $tr = "{0:hh\:mm\:ss}" -f [TimeSpan]::FromSeconds($remainingSecs)
    }

    $progressLine = "         $Message`r`n[SHIELD] : [$bar] $percent% ($Current/$Total) | TE: $te | ETR: $tr"

    Write-Host "`n$progressLine`n" -ForegroundColor Cyan
}

function Get-MKVToolPaths {
    $Resolve = {
        param($cmd)
        $path = Get-Command $cmd -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source
        if ($path -and (Test-Path -LiteralPath $path)) { return $path }
        return $null
    }

    $tools = @{
        merge = &$Resolve "mkvmerge.exe"
    }

    # Fallback
    if (-not $tools.merge -or -not (Test-Path -LiteralPath $tools.merge)) { 
        $tools.merge = "C:\Program Files\MKVToolNix\mkvmerge.exe" 
    }
    
    return $tools
}

# Initialize the function and create the comparer variable
Initialize-NaturalSort
$naturalSortComparer = [NaturalSort]::new()

# --- DEPENDENCY CHECK ---
# Tool Discovery
$tools = Get-MKVToolPaths
$mkvmerge = $tools.merge

# --- FINAL VALIDATION ---
$missingTools = New-Object System.Collections.Generic.List[string]
if ([string]::IsNullOrWhiteSpace($mkvmerge) -or -not (Test-Path -LiteralPath $mkvmerge)) { 
    [void]$missingTools.Add("mkvmerge.exe (MKVToolNix)") 
}

if ($missingTools.Count -gt 0) {
    Write-Host "`n [!] ERROR: The following dependencies are missing:" -ForegroundColor DarkRed
    $missingTools | ForEach-Object { Write-Host "     -> $_" -ForegroundColor DarkYellow }
    
    Write-Host "`n [TIP] If you recently installed MKVToolNix or modified your System PATH," -ForegroundColor Cyan
    Write-Host "       please reboot your computer to ensure the changes are applied." -ForegroundColor Cyan
    Write-Host "`n Please install MKVToolNix to proceed." -ForegroundColor Gray
    Read-Host "Press Enter to exit"; exit
}

if ($DevDebug) {
    Write-Host "`n [DevDebug-Main] Tool Discovery:" -ForegroundColor DarkYellow
    Write-Host "  -> mkvmerge:    $mkvmerge`n" -ForegroundColor Gray
}

# --- EXCLUSION LOGIC ---
$exclusionList = @()
if ($excludePaths) {
    $excludeFile = Join-Path $PSScriptRoot "convert2mkv__Excluded-Paths.txt"
    $exclusionList = Get-ExclusionList -ExcludeFile $excludeFile
}

$script:SessionStartTime = [DateTime]::Now

# --- HELP & MANUAL SYSTEM ---
if ($Manual) {
    Show-ProjectManual -scriptVersion $scriptVersion
}

if (-not $Path) {
    Write-Host "ERROR: -Path is required for conversion or search operations." -ForegroundColor Red
    Write-Host "Use -help or -Manual to see usage instructions." -ForegroundColor Gray
    exit
}

# Define file extensions
$videoExtensions = @('.mp4', '.m4v', '.mov', '.m2ts', '.asf', '.mxf', '.webm')
$subExtensions = @('.srt', '.ass', '.ssa', '.sub', '.idx', '.sup')

# --- STARTUP DISPLAY ---
if (-not $DevDebug) { Clear-Host }
$uiversion = $scriptVersion

$displayMode = if ($Search) { "Search Mode" } else { "Convert Mode" }

# Sort the input paths array naturally using our custom comparer class
[System.Array]::Sort($Path, $naturalSortComparer)

Write-Host "=================================================="
Write-Host "convert2mkv.ps1 v$uiversion" -ForegroundColor Cyan
if ($DevDebug) {
    Write-Host "PS Version: $($PSVersionTable.PSVersion)" -ForegroundColor Cyan
}
Write-Host "=================================================="
Write-Host $displayMode -ForegroundColor Blue
Write-Host "--------------------------------------------------"
$hasOptions = $Search -or $excludePaths -or $MkvWithExternalSubtitles -or $DevDebug
if ($hasOptions) {
    Write-Host "LOADED OPTIONS:" -ForegroundColor DarkGreen
    $displayContainers = New-Object System.Collections.Generic.List[string]
    if ($MkvWithExternalSubtitles) { $displayContainers.Add("mkv") }
    foreach ($ext in $videoExtensions) { $displayContainers.Add($ext.TrimStart('.')) }
    
    Write-Host "  Containers: " -NoNewline; Write-Host ($displayContainers -join ', ') -ForegroundColor DarkGray
    Write-Host "  MKV:        " -NoNewline; Write-Host "$(if ($MkvWithExternalSubtitles) { 'Yes' } else { 'No' })" -ForegroundColor DarkGray
    Write-Host "  Subtitles:  " -NoNewline; Write-Host "ass, ssa, srt, pgs(sup), vob(idx,sub)" -ForegroundColor DarkGray
    Write-Host "--------------------------------------------------"
}

if ($DevDebug) { 
    Write-Host "  Global Debug: " -NoNewline; Write-Host "Active (-Dev)" -ForegroundColor DarkYellow 
    Write-Host "--------------------------------------------------"
}

if ($excludePaths) {
    Write-Host "Exclusions Loaded: " -NoNewline -ForegroundColor Blue
    Write-Host "$($exclusionList.Count)" -ForegroundColor DarkGray
    Write-Host "--------------------------------------------------"
}

Write-Host "Source Folder(s):" -ForegroundColor Green
foreach ($p in $Path) {
    if (Test-Path -LiteralPath $p) { 
        Write-Host "  -> $p" -ForegroundColor Blue 
    } else { 
        Write-Host "  [!] NOT FOUND: $p" -ForegroundColor DarkRed 
    }
}

if (-not $Search) {
    Write-Host "Destination Folder(s):" -ForegroundColor Green
    if ($Save) {
     Write-Host "  -> $Save" -ForegroundColor Blue
    } else {
        foreach ($p in $Path) {
            if (Test-Path -LiteralPath $p) {
                $normalizedPath = $p.TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
                if ($DevDebug) {
                    Write-Host "  [DevDebug-Main] Processing raw path: '$p'" -ForegroundColor Gray
                    Write-Host "  [DevDebug-Main] Normalized path: '$normalizedPath'" -ForegroundColor Gray
                }
                
                if (Test-Path -LiteralPath $normalizedPath -PathType Container) {
                    $parentDir = [System.IO.Path]::GetDirectoryName($normalizedPath)
                    if ([string]::IsNullOrEmpty($parentDir)) {
                        $parentDir = [System.IO.Path]::GetPathRoot($normalizedPath)
                    }
                    $leafName = [System.IO.Path]::GetFileName($normalizedPath)
                    $newName = "${leafName}_updated-mkv"
                    
                    if ($DevDebug) {
                        Write-Host "  [DevDebug-Main] Parent dir calculated: '$parentDir'" -ForegroundColor Gray
                        Write-Host "  [DevDebug-Main] Leaf name calculated: '$leafName'" -ForegroundColor Gray
                    }
                    
                    if ([string]::IsNullOrEmpty($parentDir) -or [string]::IsNullOrEmpty($newName)) {
                        Write-Host "  [!] ERROR: Cannot determine parent directory or name for path: '$p'" -ForegroundColor Red
                    } else {
                        Write-Host "  -> $([System.IO.Path]::Combine($parentDir, $newName))" -ForegroundColor Blue
                    }
                } else {
                    $parentDir = [System.IO.Path]::GetDirectoryName($normalizedPath)
                    if ([string]::IsNullOrEmpty($parentDir)) {
                        $parentDir = [System.IO.Path]::GetPathRoot($normalizedPath)
                    }
                    
                    if ($DevDebug) {
                        Write-Host "  [DevDebug-Main] File Parent dir calculated: '$parentDir'" -ForegroundColor Gray
                    }
                    
                    if ([string]::IsNullOrEmpty($parentDir)) {
                        Write-Host "  [!] ERROR: Cannot determine parent directory for path: '$p'" -ForegroundColor Red
                    } else {
                        Write-Host "  -> $([System.IO.Path]::Combine($parentDir, "_updated-mkv"))" -ForegroundColor Blue
                    }
                }
            }
        }
    }
}
Write-Host "--------------------------------------------------"

# Determine Start Message
$startMessage = if ($Search) { 
    "Begin Search?" 
} elseif ($Save) { 
    "Begin Converting to Save Directory?" 
} else { 
    "Begin Converting?" 
}

# Print message without a newline, then call Read-Host
Write-Host "$startMessage " -ForegroundColor Gray -NoNewline
$choice = Read-Host "(Y/N)"

if ($choice -notmatch "^[yY]$") {
    Write-Host "Operation cancelled by user." -ForegroundColor DarkYellow
    exit
}
Write-Host "Starting..." -ForegroundColor DarkGreen
# --- END STARTUP DISPLAY ---

# --- Search Mode ---
if ($Search) {
    $ts = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $logDir = Join-Path $PSScriptRoot "convert2mkv_logs\Search_Logs"
    if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
    $logFile = Join-Path $logDir "convert2mkv_Search_$($ts)-log.txt"
    $foundFiles = New-Object System.Collections.Generic.List[string]

    Write-Host "Searching in $Path..." -ForegroundColor Cyan

    Write-Host " [i] Initializing session: Counting video files..." -ForegroundColor DarkCyan
    $allFiles = Get-ChildItem -Path $Path -Recurse -File
    $files = New-Object System.Collections.Generic.List[System.IO.FileInfo]
    $excludedCount = 0
    $loggedExclusionsTerminal = @()
    $excludedRulesForLog = New-Object System.Collections.Generic.List[string]

    foreach ($f in $allFiles) {
        if ($DevDebug) { Write-Host " [DevDebug-Search] Evaluating File: $($f.Name)" -ForegroundColor Gray }
        $isExcluded = $false
        foreach ($excludePath in $exclusionList) {
            if ($f.FullName.StartsWith($excludePath, [System.StringComparison]::OrdinalIgnoreCase)) {
                $isExcluded = $true
                if ($loggedExclusionsTerminal -notcontains $excludePath) {
                    Write-Host " [SKIP] Path excluded by rule: $excludePath" -ForegroundColor DarkGray
                    $loggedExclusionsTerminal += $excludePath
                    $excludedRulesForLog.Add("EXCLUDED PATH: $excludePath")
                    $excludedCount++
                }
                break
            }
        }
        if ($isExcluded) { continue }
        $files.Add($f)
    }
    Write-Host " [i] Total video files found: $($files.Count)" -ForegroundColor DarkGreen

    # Generate Header
    $border = "-" * 99
    $foundFiles.Add($border)
    $foundFiles.Add("convert2mkv.ps1 v$scriptVersion")
    $foundFiles.Add("Log File: $(Split-Path $logFile -Leaf)")
    $foundFiles.Add("convert2mkv__Excluded-Paths.txt: $(if ($excludePaths) { 'Loaded' } else { 'Not Loaded' })")
    $foundFiles.Add("Paths Excluded: $excludedCount")
    $foundFiles.Add($border)
    $foundFiles.Add("")

    # List the excluded paths (rules) that triggered skips
    foreach ($entry in $excludedRulesForLog) {
        $foundFiles.Add($entry)
    }
    if ($excludedRulesForLog.Count -gt 0) { $foundFiles.Add("") }

    $files = [System.IO.FileInfo[]]$files
    if ($files.Count -eq 0) {
        Write-Host "No files matching criteria were found. No log file created." -ForegroundColor Yellow
        Write-Host "--------------------------------------------------"
        Read-Host "Press Enter to exit"
        exit
    }

    if ($files.Count -gt 0) {
        $keys = [string[]]($files.FullName)
        if ($null -ne $keys) {
            [System.Array]::Sort($keys, $files, $naturalSortComparer)
        }
    }

    $lastWriteTime = [System.Diagnostics.Stopwatch]::StartNew()
    $headerWritten = $false

    $currentFileIndex = 0
    $lastPercent = 0
    foreach ($file in $files) {
        $currentFileIndex++
        $currentPercent = [Math]::Floor(($currentFileIndex / $files.Count) * 100)
        if ($currentPercent -ge ($lastPercent + 5)) {
            $lastPercent = $currentPercent
            Write-InlineProgress -Current $currentFileIndex -Total $files.Count -Message "Searching: $($file.Name)"
        }
        # Check if 60 seconds have passed to flush current findings to log
        if ($lastWriteTime.Elapsed.TotalSeconds -ge 60) {
            Write-Host " [i] 60s Elapsed: Flushing discoveries to disk for safety..." -ForegroundColor Cyan
            if (-not $headerWritten) {
                $foundFiles | Out-File -FilePath $logFile -Encoding utf8
                $headerWritten = $true
            } else {
                $foundFiles | Out-File -FilePath $logFile -Append -Encoding utf8
            }
            $foundFiles.Clear()
            $lastWriteTime.Restart()
        }
        $isMkvWithSubs = $false
        if ($MkvWithExternalSubtitles -and ($file.Extension -eq '.mkv')) {
            if ($DevDebug) { Write-Host "  [DevDebug-Search] Checking MKV: $($file.Name)" -ForegroundColor Gray }
            $potentialSubs = Get-ChildItem -LiteralPath $file.DirectoryName -Filter ($file.BaseName + "*") | 
                Where-Object { $subExtensions -contains $_.Extension }
            if ($potentialSubs) {
                $isMkvWithSubs = $true
                if ($DevDebug) { Write-Host "  [DevDebug-Search] [MATCH] External sub found for: $($file.Name)" -ForegroundColor Magenta }
            }
        }

        if (($videoExtensions -contains $file.Extension) -or $isMkvWithSubs) {
            $foundFiles.Add("`r`n$($file.FullName)")
            if ($DevDebug) { Write-Host "[FOUND] $($file.FullName)" -ForegroundColor Yellow }
            Write-InlineProgress -Current $currentFileIndex -Total $files.Count -Message "Match Found: $($file.Name)"
            
            # Check for matching subtitle files
            $foundSubs = Get-ChildItem -LiteralPath $file.DirectoryName -Filter ($file.BaseName + "*") | 
                Where-Object { $subExtensions -contains $_.Extension }
            
            foreach ($sub in $foundSubs) {
                $subLabel = switch ($sub.Extension.ToLower()) {
                    '.ass' { "📕[Sub Found ASS]" }
                    '.ssa' { "📘[Sub Found SSA]" }
                    '.srt' { "📗[Sub Found SRT]" }
                    '.sup' { "📙[Sub Found PGS]" }
                    { $_ -in '.idx', '.sub' } { "📒[Sub Found VOB]" }
                    Default { "❔[Sub Found UNK]" }
                }
                $foundFiles.Add(" $($subLabel): $($sub.FullName)")
            }
        }
    }
    Write-Host "" # Clear line from progress bar

    # Final write to log. If header was never written (short scan), write everything.
    # If header was written, append the remaining findings.
    if (-not $headerWritten) {
        $foundFiles | Out-File -FilePath $logFile -Encoding utf8
    } else {
        $foundFiles | Out-File -FilePath $logFile -Append -Encoding utf8
    }
    Write-Host "Search complete. Results written to $logFile" -ForegroundColor Green
}

# --- Convert Mode ---
else {
    Write-Host " [i] Initializing session: Counting video files..." -ForegroundColor DarkCyan
    $allFiles = Get-ChildItem -Path $Path -Recurse -File
    $files = New-Object System.Collections.Generic.List[System.IO.FileInfo]
    $loggedExclusions = @()

    foreach ($f in $allFiles) {
        $isExcluded = $false
        $matchedRule = ""
        foreach ($excludePath in $exclusionList) {
            if ($f.FullName.StartsWith($excludePath, [System.StringComparison]::OrdinalIgnoreCase)) {
                $isExcluded = $true
                $matchedRule = $excludePath
                break
            }
        }

        if ($isExcluded) {
            if ($loggedExclusions -notcontains $matchedRule) {
                Write-Host " [SKIP] Path excluded by rule: $matchedRule" -ForegroundColor DarkGray
                $loggedExclusions += $matchedRule
            }
            continue
        }
        $files.Add($f)
    }
    $files = [System.IO.FileInfo[]]$files
    $videoFiles = [System.IO.FileInfo[]]@($files | Where-Object { 
        if ($videoExtensions -contains $_.Extension) { return $true }
        if ($MkvWithExternalSubtitles -and $_.Extension -eq '.mkv') {
            if ($DevDebug) { Write-Host " [DevDebug-Conversion] Checking MKV: $($_.Name)" -ForegroundColor Gray }
            $potentialSubs = Get-ChildItem -LiteralPath $_.DirectoryName -Filter ($_.BaseName + "*") | 
                Where-Object { $subExtensions -contains $_.Extension }
            if ($potentialSubs) {
                if ($DevDebug) { Write-Host " [DevDebug-Conversion] [MATCH] External sub(s) found for: $($_.Name)" -ForegroundColor Magenta }
                return $true
            }
        }
        return $false
    })
    Write-Host " [i] Total video files found: $($videoFiles.Count)" -ForegroundColor DarkGreen
    if ($videoFiles.Count -gt 0) {
        $keys = [string[]]($videoFiles.FullName)
        if ($null -ne $keys) {
            [System.Array]::Sort($keys, $videoFiles, $naturalSortComparer)
        }
    }

    $currentFileIndex = 0
    foreach ($file in $videoFiles) {
        $currentFileIndex++
        Write-InlineProgress -Current $currentFileIndex -Total $videoFiles.Count -Message "Converting: $($file.Name)"
        # Calculate dynamic destination path based on the presence of -Save and directory structure
        if ($Save) {
            if (-not (Test-Path $Save)) {
                New-Item -ItemType Directory -Path $Save | Out-Null
            }
            
            $matchedPath = $Path | Where-Object { 
                $normalizedParam = (Get-Item -LiteralPath $_).FullName.TrimEnd('\')
                $normalizedFileDir = $file.DirectoryName.TrimEnd('\')
                $normalizedFileDir -eq $normalizedParam -or $normalizedFileDir.StartsWith($normalizedParam + '\', [System.StringComparison]::OrdinalIgnoreCase)
            } | Select-Object -First 1
            if ($matchedPath -and (Test-Path -Path $matchedPath -PathType Container)) {
                $literalMatchedLength = (Get-Item -LiteralPath $matchedPath).FullName.Length
                if ($file.DirectoryName.Length -gt $literalMatchedLength) {
                    $relativePath = $file.DirectoryName.Substring($literalMatchedLength).TrimStart('\')
                } else {
                    $relativePath = ""
                }
            } else {
                $relativePath = ""
            }
            $targetDir = Join-Path $Save $relativePath
        } else {
            $matchedPath = $Path | Where-Object { 
                $normalizedParam = (Get-Item -LiteralPath $_.TrimEnd('\')).FullName
                $normalizedFileDir = $file.DirectoryName
                $normalizedFileDir -eq $normalizedParam -or $normalizedFileDir.StartsWith($normalizedParam + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase)
            } | Select-Object -First 1
            $isFolderInput = if ($matchedPath) { Test-Path -LiteralPath $matchedPath -PathType Container } else { $false }
            
            if ($isFolderInput) {
                $literalMatchedLength = (Get-Item -LiteralPath $matchedPath).FullName.Length
                if ($file.DirectoryName.Length -gt $literalMatchedLength) {
                    $relativePath = $file.DirectoryName.Substring($literalMatchedLength).TrimStart('\')
                } else {
                    $relativePath = ""
                }
                $folderItem = Get-Item -LiteralPath $matchedPath
                $parentDir = if ($null -ne $folderItem.Parent) { $folderItem.Parent.FullName } else { $folderItem.Root.FullName }
                $baseTargetDir = Join-Path $parentDir "$($folderItem.Name)_updated-mkv"
                $targetDir = Join-Path $baseTargetDir $relativePath
            } else {
                $targetDir = Join-Path $file.DirectoryName "_updated-mkv"
            }
        }
        
        if (-not (Test-Path $targetDir)) {
                New-Item -ItemType Directory -Path $targetDir | Out-Null
            }
            
            $outputFile = Join-Path $targetDir ($file.BaseName + ".mkv")
            
            # Identify and prioritize subtitles based on extension order
            $priorityOrder = @('.ass', '.ssa', '.srt', '.sup', '.idx', '.sub')
            $allSubs = Get-ChildItem -Path $file.DirectoryName -Filter ($file.BaseName + "*") | 
                Where-Object { $priorityOrder -contains $_.Extension }

            # Filter out .sub files if a matching .idx file exists to avoid duplicate tracks
            $subs = @()
            foreach ($s in $allSubs) {
                if ($s.Extension -eq '.sub') {
                    $matchingIdx = Join-Path $s.DirectoryName ($s.BaseName + '.idx')
                    if (Test-Path $matchingIdx) { continue }
                }
                $subs += $s
            }
            $subs = $subs | Sort-Object { $priorityOrder.IndexOf($_.Extension) }

            # Track if a default subtitle has already been assigned
            $defaultAssigned = $false
            
            # Dynamically identify internal tracks to clear forced default flags
            $fileInfoJson = & $tools.merge -J $file.FullName | Out-String | ConvertFrom-Json
            
            # Initialize mkvmerge arguments with output file
            $args = @("-o", $outputFile)
            
            # Loop through all detected internal tracks and clear their default flags
            if ($fileInfoJson -and $fileInfoJson.tracks) {
                foreach ($track in $fileInfoJson.tracks) {
                    if ($track.type -eq "audio" -or $track.type -eq "video" -or $track.type -eq "subtitles") {
                        $args += "--default-track-flag"
                        $args += "$($track.id):no"
                    }
                }
            }
            
            # Append the input video file
            $args += $file.FullName
            foreach ($sub in $subs) {
                # Extract the suffix between BaseName and Extension
                # e.g., "video.eng.full dialogue.srt" -> ".eng.full dialogue"
                $suffix = $sub.BaseName.Substring($file.BaseName.Length)
                
                $lang = "und"
                $trackName = ""
                
                if ($suffix -like ".*") {
                    # Split by '.' and remove empty entries
                    $parts = $suffix.Split('.', [System.StringSplitOptions]::RemoveEmptyEntries)
                    
                    if ($parts.Count -gt 0) {
                        # First part is expected to be the language code (e.g., en, eng)
                        if ($parts[0].Length -eq 2 -or $parts[0].Length -eq 3) {
                            $lang = $parts[0]
                            # Remaining parts form the track name
                            if ($parts.Count -gt 1) {
                                $trackName = $parts[1..($parts.Count - 1)] -join " "
                            }
                        } else {
                            # If the first part isn't a 2/3 letter lang code, treat the whole suffix as the name
                            $trackName = $parts -join " "
                        }
                    }
                }
                
                # Determine default track status based on name and format priority
                $isDefault = "no"
                if (-not $defaultAssigned -and (-not $trackName -or $trackName -like "*full dialogue*")) {
                    $isDefault = "yes"
                    $defaultAssigned = $true
                }

                # Append mkvmerge track properties for the subtitle file
                $args += "--language"
                $args += "0:$lang"
                $args += "--default-track-flag"
                $args += "0:$isDefault"
                if ($trackName) {
                    $args += "--track-name"
                    $args += "0:$trackName"
                }
                $args += $sub.FullName
            }

            # (Progress handled by Write-InlineProgress)
            if ($DevDebug) {
                & $tools.merge @args | ForEach-Object { Write-Host " [DevDebug-Conversion] $_" -ForegroundColor Gray }
            } else {
                & $tools.merge @args | Out-Null
            }
        }
        Write-Host "" # Clear line from progress bar
    }
    Write-Host "--------------------------------------------------"
    Write-Host "Conversion complete." -ForegroundColor Green
    Write-Host "=================================================="
    Read-Host "Press Enter to exit"
