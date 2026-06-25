# convert2mkv
**A high-speed media conversion and external subtitle consolidation suite for PowerShell 7.6.3 LTS.**

---

## Overview
`convert2mkv.ps1` is a high-speed media conversion utility designed to batch-convert various video containers into the Matroska (MKV) format. It automatically identifies external subtitle files and remuxes them into the final output, ensuring all media assets are consolidated into a single, high-fidelity file.

### Operational Modes
The script logic supports two primary modes:
1. **SEARCH Mode**: Scans directories to identify compatible video files and matching external subtitles, logging the results to a text file without performing conversions.
2. **CONVERT Mode**: Performs the physical remuxing operations using `mkvmerge` to bundle video streams and external subtitle tracks into a clean MKV container.

### Subtitle Prioritization & Language Mapping
During conversion, the script automatically parses external subtitle files, prioritizing format layouts by checking `.ass` and `.ssa` over `.srt` extensions. It dynamically matches track language codes and custom track names based on dot-separated file suffixes (e.g., `video.eng.full dialogue.srt`), stripping default flag configurations from internal streams to guarantee proper default mapping of the new external tracks.

---

## Usage Examples
```powershell
# Standard Conversion (Create _updated-mkv sibling)
.\convert2mkv.ps1 -Path 'G:\Media\Movies'

# Convert and Save to Specific Directory
.\convert2mkv.ps1 -Path 'G:\Media\Movies' -Save 'D:\Final_MKVs'

# Search Mode (Search for containers and external subs)
.\convert2mkv.ps1 -Search -Path 'G:\Media\TV'

# Process MKVs with External Subtitles
.\convert2mkv.ps1 -mkv -Path 'G:\Media\Anime'
```
---

## Parameter Reference

### Core Flags
| Flag | Description |
| :--- | :--- |
| `-Path <string[]>` | Defines the target directory or directories. The script recursively scans all subfolders for supported video files. |
| `-Save <string>` | Optional destination directory. If used, all converted files will be mirrored into this location while preserving subfolder structures. |

### Mode & Search Flags
| Flag | Description |
| :--- | :--- |
| `-Search` | **Search Mode:** Instead of converting, the script logs all found video files and their matching external subtitles to a text file. |
| `-excludePaths \| -ep` | **Exclusion Engine:** Enables the suppression engine. Skips directories explicitly listed in `convert2mkv__Excluded-Paths.txt`. |
| `-MkvWithExternalSubtitles \| -mkv` | **Extended Scanner:** Extends the scanner to include existing MKV files, but only if matching external subtitle files are found in the same folder. |

### Advanced & Log Management Flags
| Flag | Description |
| :--- | :--- |
| `-DevDebug \| -Dev \| -DevD \| -DBG` | **Global Debugging:** Exposes internal logic, file evaluation traces, and mkvmerge discovery processes for troubleshooting. Displays active PowerShell environment versioning. |
| `-Manual \| -h \| -help` | **Usage Guide:** Displays the internal manual and usage guide. |

---

## Dependencies
* **MKVToolNix (mkvmerge):** Required for remuxing video streams, parsing internal track flags, and attaching external subtitle tracks to the MKV container.

## Support & Maintenance
**This repository is provided "as-is" for archival purposes.** The author is not actively looking for feedback, feature requests, or bug reports. The issue tracker is disabled, and the author will not be responding to inquiries regarding setup or usage.

## Disclaimer
*This script executes conversion and container operations using external tools. While designed for structural safety, always ensure you have backups of your media before running batch operations across your storage volumes.*

---
> **Document Control** > *This document is up-to-date with the following version of convert2mkv.* > *2026.06.24__08.51.52*