# scenario.json format

One JSON file drives the whole build. `build_reels.py` never changes between
projects — only this file (and the media it points to) does.

```json
{
  "output_name": "my-reel.mp4",
  "voice": "audio/voice.mp3",
  "music": "music/music.mp3",
  "width": 1080,
  "height": 1920,
  "fps": 30,
  "voice_volume_db": 0,
  "fonts": {
    "title":   { "family": "Arial", "size": 50, "color": "#FFE500", "margin_v": 200 },
    "caption": { "family": "Arial", "size": 58, "color": "#FFFFFF", "margin_v": 340 }
  },
  "scenes": [
    {
      "media": "media/01.png",
      "start": 0.0,
      "end": 4.0,
      "title": "SHORT TOP TITLE",
      "caption": "The narrator's line for this scene.",
      "type": "image",
      "effect": "zoom_in"
    }
  ]
}
```

## Top-level fields

| Field | Required | Default | Notes |
|---|---|---|---|
| `voice` | yes | — | Path to the voiceover track, relative to scenario.json. Its real measured duration (via ffprobe) is what every scene's timing gets proportionally rescaled to — write scene timings against your best guess of the read-aloud length, the script corrects for TTS drift automatically. |
| `scenes` | yes | — | Ordered list, see below. |
| `music` | no | none | Either a plain path string, or `{"file": "...", "volume_db": -20}` to override the default -20 dB mix level. |
| `output_name` | no | `output.mp4` | Filename written into `output/`. |
| `width`, `height` | no | 1080 x 1920 | Change only for a non-Reels aspect ratio. |
| `fps` | no | 30 | |
| `fonts.title` / `fonts.caption` | no | Arial, yellow title / white caption | See Fonts below. |
| `voice_volume_db` | no | `0` | Gain applied to the voiceover, in dB, before mixing (e.g. `3` to make the narration noticeably louder). Positive values can clip if the source is already near full volume - if it sounds distorted, try a smaller value rather than a larger one. |

## Scenes

Each scene is one segment of the video, in order. Timings are **nominal** —
they get scaled together so the last scene's `end` lands exactly on the
voice track's real duration. Write them as your best estimate of where each
line falls when read aloud; don't fuss over precision.

| Field | Required | Notes |
|---|---|---|
| `media` | yes | Path to an image or video file, relative to scenario.json. |
| `start`, `end` | yes | Seconds, nominal (see above). |
| `caption` | no | Bottom subtitle line, burned in. Omit or `null` for no caption. |
| `title` | no | Top title card, burned in. Omit or `null` for no title (e.g. a pause/transition beat). |
| `type` | no | `"image"` or `"video"` — auto-detected from the file extension if omitted. Only needed for an unusual extension. |
| `effect` | no, images only | `"zoom_in"` (default, alternates with `zoom_out` by scene index if you don't set it), `"zoom_out"`, or `"static"` for no motion. |

Video-clip scenes are trimmed/looped to exactly fill their `start`-`end`
window and scaled+cropped (cover, centered) to the frame size; their own
audio is dropped (only `voice` and `music` end up in the final mix).

## Fonts

`family` must be a font actually installed on the Windows machine doing the
build (Arial and Segoe UI are always present; anything fancier needs the
user to install the font first — double-click the `.ttf`/`.otf` and choose
Install). `color` accepts either a friendly `#RRGGBB` hex string, or a raw
ASS `&HAABBGGRR` string for anyone who already knows the format.

Title renders top-center, caption renders bottom-center — this matches the
Reels convention of a short label up top and the spoken line at the bottom,
and keeps the two from ever overlapping.

`margin_v` is the distance in pixels from the top edge (title) or bottom edge
(caption) of a 1920-tall frame. The defaults (200 top / 340 bottom) keep text
out of Instagram's own UI overlays — the profile picture/mute icon area at
the top, and the username/caption/like-comment-share buttons at the bottom.
Those overlap zones aren't pixel-exact or officially documented by Instagram
and shift between app versions, so treat the defaults as a safe starting
point and preview on an actual phone before publishing, especially if you
tighten them.
