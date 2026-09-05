# Windows/PowerShell pitfalls hit while building this skill

These all came up for real, in order, while walking a non-technical user
through the first build. `build_reels.py` and `setup.ps1` already handle the
first two in code; the rest are process pitfalls to warn the user about
proactively, before they hit them.

## 1. Non-ASCII (e.g. Cyrillic) username breaks the ffmpeg concat demuxer

If the Windows path contains non-ASCII characters — very common, since the
Windows username is whatever the person typed at account setup
(`C:\Users\Виталий\...`) — the classic "concat demuxer" approach (write a
text file listing `file 'path'` lines, then `ffmpeg -f concat -i list.txt`)
silently corrupts those characters when ffmpeg reads the list file back,
and fails with `Impossible to open '...'` pointing at a mangled path.

**Fix already in `build_reels.py`**: segments are concatenated with the
concat *filter* instead — each segment passed as its own `-i` argument, fed
into `concat=n=...:v=1:a=0` in `-filter_complex`. Command-line arguments
survive non-ASCII fine; it's specifically the demuxer's separate text-file
parsing pass that doesn't. Don't reintroduce a concat list file.

## 2. The `ass` subtitle filter breaks on a Windows drive letter

`-vf ass=C:/Users/.../subs.ass` fails, because the filter's own option
parser splits on `:`, and a Windows drive letter's colon confuses it into
treating everything after `C` as the *next* option (`original_size`) rather
than part of the filename — even when the colon is backslash-escaped.

**Fix already in `build_reels.py`**: that one ffmpeg call runs with `cwd`
set to the temp build folder, referencing `subs.ass` and the input/output
video by bare filename — no drive letter ever appears in the filter string.
Don't switch back to an absolute path there.

## 3. Desktop can be redirected into OneDrive

`$env:USERPROFILE\Desktop` doesn't always exist — on many Windows setups
(OneDrive Folder Backup enabled) the real desktop is
`C:\Users\<name>\OneDrive\Desktop`. Guessing the plain path wastes a whole
round-trip of "path not found" with the user.

**Fix already in `setup.ps1`**: it resolves the real path via
`[Environment]::GetFolderPath("Desktop")` instead of string-building one,
and prints the resulting full path (with a ready-to-paste `cd "..."` line)
at the end — never make the user hunt for it or guess.

## 4. Windows hides known file extensions, so renamed downloads get a second one

When a user downloads an image or audio file and renames it to `01.png` or
`voice.mp3`, Windows Explorer often has "hide extensions for known file
types" on — so `01.png` typed into the rename box lands on top of the
already-hidden original extension, producing `01.png.jfif` or
`voice.mp3.mp3` on disk (invisible in Explorer, visible from PowerShell
`dir`). `build_reels.py` will report these as *missing* files (it looks for
exactly `01.png`, not `01.png.jfif`), which is confusing if you don't know
to expect it.

**When files are reported missing that the user swears they added**: ask
for `dir media` / `dir audio` output before anything else. If you see a
doubled extension, the fix is a one-line rename, not a re-download:
```powershell
Get-ChildItem media\*.jfif | Rename-Item -NewName { $_.Name -replace '\.jfif$', '' }
Rename-Item audio\voice.mp3.mp3 voice.mp3
```
(swap the actual stray extension in for `.jfif` — `.webp`, `.jpg` etc. show
the same way).

## 5. A new PowerShell window always starts in `system32`, not the project folder

Every time the user opens a *new* PowerShell window (as opposed to reusing
one), it starts in `C:\WINDOWS\system32` regardless of what folder they were
in last time. Running `python build_reels.py` there fails with "can't open
file" pointing at system32. Always confirm which window is active, and
re-send the `cd "<project path>"` command rather than assuming the session
remembers its location.

## 6. One command per Enter — never hand over two commands to paste as one block

A user copy-pasting multiple lines into PowerShell, or typing a new command
before the previous one finished, can concatenate them into one garbled
line (e.g. `python build_reels.py cd "C:\...\Reels-California"dir`) that
fails in a confusing way. Give commands one at a time, and if a screenshot
shows a suspiciously long single line with multiple recognizable commands
run together, that's almost always what happened — read the whole line
literally rather than assuming it's a new kind of error.

## General approach when something breaks

Ask for a screenshot of the actual PowerShell output rather than guessing
from a description — the exact wording, and which folder the prompt shows
(`PS C:\...>`), usually reveals which of the above it is immediately.
