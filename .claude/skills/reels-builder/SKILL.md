---
name: reels-builder
description: Build a vertical (1080x1920) Instagram Reels-style video from a scenario (timed scenes with a title, a caption, and an image or video clip each), a voiceover track, and optional background music - burning in titles/captions with configurable fonts and colors, applying Ken Burns motion to still images, and syncing everything to the voiceover's real length. Use this whenever the user wants to turn a script/storyboard plus generated images (Gemini, Midjourney, etc.), video clips, and a TTS voiceover (ElevenLabs, etc.) into a finished vertical video for Instagram/TikTok/Shorts - even if they just say "собери ролик", "сделай Reels", "смонтируй видео из этих картинок и озвучки", or describe a scene-by-scene script without naming this skill. The actual ffmpeg/Python build always runs on the user's own Windows machine (this skill produces/updates the project files and walks them through running it), not in this session.
---

# Reels builder

Turns a scene-by-scene script into a finished vertical video: still images get
a slow Ken Burns zoom, video clips get scaled/cropped to fill the frame, a
title card burns in at the top and a caption at the bottom of each scene, and
every timing is auto-corrected to match the real length of the voiceover
track. The heavy lifting is one generic script, `scripts/build_reels.py`,
driven entirely by a `scenario.json` you write fresh for each new video -
**never edit the Python between projects**, only the JSON and the media it
points to.

Read `references/scenario-schema.md` for the full JSON format before writing
one - it documents every field, the defaults, and how scene timings get
rescaled to the voiceover.

## Why this exists / how to think about it

The actual video assembly (ffmpeg) has to run on the user's own Windows PC -
this session has no access to their machine. So this skill's job splits into
two halves: **you** turn the user's idea into a `scenario.json` and hand them
files; **they** run PowerShell commands you give them, one at a time, on
their own computer. Treat every interaction with a "run this" instruction as
something you're walking a possibly non-technical person through live, not
as background automation - see the workflow below and
`references/windows-gotchas.md` for the specific ways this goes sideways and
how to head it off.

## Workflow for a new Reels video

1. **Gather the scenario from the user.** You need, per scene: roughly how
   long it runs, the title card text (or none), the caption/narration line,
   and what media it uses (an image you'll write a generation prompt for, a
   video clip they have, or one they'll shoot/source). Also ask: any
   background music preference, and any font/color preference (default is
   Arial, yellow title, white caption - fine for most cases, no need to push
   for a choice if they don't care).

2. **Write `scenario.json`** for the project (see the schema reference).
   Scene timings only need to be a reasonable estimate of the spoken pacing -
   the build rescales everything to the voiceover's actual length
   automatically, so don't over-engineer precise timing by hand.

3. **Also write, as separate plain files** (people paste these into other
   tools - keep them free of JSON/markdown syntax):
   - `voice-text.txt` - just the narration, one flowing text, for pasting
     into a TTS tool (ElevenLabs etc).
   - `image-prompts.txt` - one image-generation prompt per image scene, for
     pasting into Gemini/Midjourney/etc, numbered to match the `media`
     filenames you used in scenario.json.

4. **Get the project folder set up on their machine.** If this is their
   first Reels project ever, send `scripts/setup.ps1` and have them run:
   ```powershell
   .\setup.ps1 -ProjectName "Reels-WhateverTopic"
   ```
   This creates `<Desktop>\Reels-WhateverTopic\{media,audio,music,output}`,
   drops in `build_reels.py` (generic, reusable), and installs `ffmpeg`
   (`Gyan.FFmpeg`) and `Python` (`Python.Python.3.12`) via `winget` if either
   is missing. It's safe to re-run for a new project name any time - it
   won't touch an unrelated existing folder, and doesn't need re-sending if
   they still have the file from last time. It prints the real project path
   at the end (handling OneDrive-redirected Desktops) with a ready-to-paste
   `cd` command - always use that path verbatim, never assume
   `C:\Users\<name>\Desktop\...`.

5. **Send them `scenario.json`** (plus `voice-text.txt` /
   `image-prompts.txt`) to drop directly into that project folder.

6. **Walk them through populating media and building.** They generate images
   from your prompts, get a voiceover, optionally pick music, and drop it
   all into `media/`, `audio/voice.mp3`, `music/music.mp3` per your
   scenario.json. Then:
   ```powershell
   cd "<the exact path setup.ps1 printed>"
   python build_reels.py
   ```
   (or `.\build.ps1`, which does the same thing with friendlier error
   messages). The result lands in `output\<output_name>`.

7. **When something breaks, check `references/windows-gotchas.md` first.**
   Every issue in there was hit for real while developing this skill - a
   Cyrillic username corrupting ffmpeg's file list, a Windows drive letter
   breaking the subtitle filter, a OneDrive-redirected Desktop, doubled file
   extensions from Explorer's hidden-extensions setting, a new PowerShell
   window resetting to `system32`, multiple commands run together. Ask for a
   screenshot of the actual terminal output before guessing - the exact
   wording and the prompt's current folder usually identify the issue
   immediately.

## Iterating / improving between videos

The user explicitly wants to keep improving this over time. Since
`build_reels.py` is generic, most improvements are either (a) a new
`scenario.json` capability worth adding as a first-class field rather than a
one-off hack, or (b) a genuine change to the shared script. When you change
`scripts/build_reels.py` itself:
- Keep the three Windows fixes intact (concat filter not demuxer; ass filter
  run via `cwd` + bare filenames; OneDrive-aware Desktop resolution in
  `setup.ps1`) - they're easy to accidentally regress by "simplifying" back
  toward the more obvious-looking approach.
- Test the change end-to-end before handing it over, ideally under a
  non-ASCII (e.g. Cyrillic) directory name, since that's what surfaces most
  Windows-only ffmpeg bugs - this session's sandbox can install ffmpeg
  (`apt-get update && apt-get install -y --no-install-recommends ffmpeg`) to
  actually run the pipeline against synthetic test images/audio rather than
  just reading the code.
- After editing `scripts/build_reels.py`, regenerate `scripts/setup.ps1` by
  running `python3 scripts/gen_setup.py` (it embeds the new
  `build_reels.py` into `scripts/setup.ps1.tmpl`'s here-string and writes
  `scripts/setup.ps1` with UTF-8 BOM + CRLF, which Windows PowerShell 5.1
  needs to parse the embedded Cyrillic text correctly). Edit
  `setup.ps1.tmpl`, never `setup.ps1` directly - it's a generated file.
