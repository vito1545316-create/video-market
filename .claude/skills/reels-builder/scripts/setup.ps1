#Requires -Version 5.1
# Reels-builder: generic project setup script.
# Creates <Desktop>\<ProjectName>\{media, audio, music, output}, drops in the
# generic build_reels.py, and makes sure ffmpeg + Python are installed via winget.
# Re-running this script (e.g. for a new project) is always safe.
#
# Usage:
#   .\setup.ps1 -ProjectName "Reels-MyTopic"

param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectName
)

$ErrorActionPreference = "Stop"

# Desktop\ can be redirected into OneDrive - GetFolderPath resolves the real
# location instead of guessing "$env:USERPROFILE\Desktop" (which breaks when
# OneDrive Backup redirects the desktop, a common Windows setup).
$Desktop = [Environment]::GetFolderPath("Desktop")
$Root    = Join-Path $Desktop $ProjectName
$Media   = Join-Path $Root "media"
$Audio   = Join-Path $Root "audio"
$Music   = Join-Path $Root "music"
$Output  = Join-Path $Root "output"

Write-Host "=== Reels-builder: настройка проекта '$ProjectName' ===" -ForegroundColor Cyan
Write-Host ""

foreach ($d in @($Root, $Media, $Audio, $Music, $Output)) {
    if (-not (Test-Path $d)) {
        New-Item -ItemType Directory -Path $d -Force | Out-Null
        Write-Host "Создана папка: $d"
    } else {
        Write-Host "Папка уже есть:  $d"
    }
}

$Utf8Bom = New-Object System.Text.UTF8Encoding($true)

$buildPyContent = @'
#!/usr/bin/env python3
"""Generic vertical-Reels builder, driven entirely by scenario.json.

Usage (from inside a project folder that has scenario.json + its media):
    python build_reels.py [path/to/scenario.json]

Project folder layout expected by default (paths in scenario.json are
relative to the scenario.json file itself, so this is a convention, not
a requirement):
    project/
      scenario.json
      images/   (or clips/, or anything - paths are whatever scenario.json says)
      audio/voice.mp3
      music/music.mp3        (optional)
      output/                (created automatically)

See references/scenario-schema.md (in this skill) for the full JSON format.
This script never needs to be edited between projects - only scenario.json
(and the media it points to) changes.
"""
import json
import subprocess
import sys
from pathlib import Path


def run(cmd, cwd=None):
    print("+", " ".join(str(c) for c in cmd))
    subprocess.run(cmd, check=True, cwd=cwd)


def ffprobe_duration(path: Path) -> float:
    out = subprocess.run(
        ["ffprobe", "-v", "error", "-show_entries", "format=duration",
         "-of", "default=noprint_wrappers=1:nokey=1", str(path)],
        check=True, capture_output=True, text=True,
    )
    return float(out.stdout.strip())


def ass_escape(text: str) -> str:
    return text.replace("\\", r"\\").replace("{", r"\{").replace("}", r"\}")


def to_ass_time(t: float) -> str:
    h = int(t // 3600)
    m = int((t % 3600) // 60)
    s = t % 60
    return f"{h:d}:{m:02d}:{s:05.2f}"


def to_ass_color(value: str) -> str:
    """Accepts '#RRGGBB' (friendly) or a raw ASS '&HAABBGGRR' string (advanced)."""
    if value.upper().startswith("&H"):
        return value
    v = value.lstrip("#")
    if len(v) != 6:
        raise ValueError(f"Bad color '{value}': expected '#RRGGBB' or '&HAABBGGRR'")
    r, g, b = v[0:2], v[2:4], v[4:6]
    return f"&H00{b}{g}{r}".upper()


IMAGE_EXTS = {".png", ".jpg", ".jpeg", ".webp", ".bmp"}
VIDEO_EXTS = {".mp4", ".mov", ".mkv", ".webm", ".avi", ".m4v"}


def detect_type(media_path: Path, declared: str | None) -> str:
    if declared in ("image", "video"):
        return declared
    ext = media_path.suffix.lower()
    if ext in IMAGE_EXTS:
        return "image"
    if ext in VIDEO_EXTS:
        return "video"
    raise ValueError(f"Can't tell if '{media_path.name}' is an image or a video - "
                      f"add \"type\": \"image\" or \"video\" to its scene in scenario.json")


def load_config(scenario_path: Path) -> dict:
    cfg = json.loads(scenario_path.read_text(encoding="utf-8"))
    cfg.setdefault("width", 1080)
    cfg.setdefault("height", 1920)
    cfg.setdefault("fps", 30)
    cfg.setdefault("output_name", "output.mp4")
    fonts = cfg.setdefault("fonts", {})
    title_font = fonts.setdefault("title", {})
    title_font.setdefault("family", "Arial")
    title_font.setdefault("size", 50)
    title_font.setdefault("color", "#FFE500")
    # 200px keeps the title clear of Instagram's top UI (profile pic, mute icon)
    # on a 1920-tall frame - see references/scenario-schema.md for sources.
    title_font.setdefault("margin_v", 200)
    caption_font = fonts.setdefault("caption", {})
    caption_font.setdefault("family", "Arial")
    caption_font.setdefault("size", 58)
    caption_font.setdefault("color", "#FFFFFF")
    # 340px keeps the caption clear of Instagram's bottom UI (username, caption,
    # like/comment/share buttons) on a 1920-tall frame.
    caption_font.setdefault("margin_v", 340)
    cfg.setdefault("voice_volume_db", 0)
    music_cfg = cfg.get("music")
    if isinstance(music_cfg, str):
        cfg["music"] = {"file": music_cfg, "volume_db": -20}
    elif isinstance(music_cfg, dict):
        music_cfg.setdefault("volume_db", -20)
    if not cfg.get("scenes"):
        raise ValueError("scenario.json has no scenes")
    return cfg


def build(scenario_path: Path):
    project = scenario_path.resolve().parent
    cfg = load_config(scenario_path)
    W, H, FPS = cfg["width"], cfg["height"], cfg["fps"]

    voice = (project / cfg["voice"]).resolve()
    if not voice.exists():
        sys.exit(f"Не найден файл озвучки: {voice}")

    scenes = cfg["scenes"]
    missing = []
    for sc in scenes:
        p = project / sc["media"]
        if not p.exists():
            missing.append(str(p))
    if missing:
        print("Не хватает файлов:")
        for m in missing:
            print(" -", m)
        sys.exit(1)

    tmp = project / "_tmp_build"
    output_dir = project / "output"
    tmp.mkdir(exist_ok=True)
    output_dir.mkdir(exist_ok=True)

    voice_dur = ffprobe_duration(voice)
    nominal_total = scenes[-1]["end"]
    scale = voice_dur / nominal_total
    print(f"Длительность озвучки: {voice_dur:.2f} с (сценарий рассчитан на {nominal_total:.0f} с, "
          f"коэффициент подгонки {scale:.4f})")

    adj = []
    for sc in scenes:
        adj.append({**sc, "start": sc["start"] * scale, "end": sc["end"] * scale})
    adj[-1]["end"] = voice_dur

    segment_files = []
    for i, sc in enumerate(adj):
        media = (project / sc["media"]).resolve()
        kind = detect_type(media, sc.get("type"))
        dur = sc["end"] - sc["start"]
        seg = tmp / f"seg_{i:02d}.mp4"

        if kind == "image":
            nframes = max(1, round(dur * FPS))
            effect = sc.get("effect") or ("zoom_in" if i % 2 == 0 else "zoom_out")
            step = 0.35 / nframes
            if effect == "static":
                zexpr = "1.0"
            elif effect == "zoom_out":
                zexpr = f"if(eq(on,0),1.18,max(zoom-{step:.6f},1.0))"
            else:  # zoom_in (default)
                zexpr = f"min(zoom+{step:.6f},1.18)"
            vf = (
                f"scale={W*3}:{H*3}:force_original_aspect_ratio=increase,"
                f"crop={W*3}:{H*3},"
                f"zoompan=z='{zexpr}':d={nframes}:"
                f"x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':s={W}x{H}:fps={FPS},"
                f"format=yuv420p"
            )
            run([
                "ffmpeg", "-y", "-loop", "1", "-i", str(media),
                "-t", f"{dur:.3f}", "-vf", vf,
                "-c:v", "libx264", "-preset", "veryfast", "-crf", "18",
                "-r", str(FPS), str(seg),
            ])
        else:  # video
            vf = (
                f"scale={W}:{H}:force_original_aspect_ratio=increase,"
                f"crop={W}:{H},setsar=1,fps={FPS},format=yuv420p"
            )
            run([
                "ffmpeg", "-y", "-stream_loop", "-1", "-i", str(media),
                "-t", f"{dur:.3f}", "-vf", vf, "-an",
                "-c:v", "libx264", "-preset", "veryfast", "-crf", "18",
                str(seg),
            ])
        segment_files.append(seg)

    # Concat via the concat *filter* (direct -i inputs), not the concat demuxer's
    # text-list file - the demuxer misreads non-ASCII (e.g. Cyrillic) paths on Windows.
    n = len(segment_files)
    concat_inputs = []
    for f in segment_files:
        concat_inputs += ["-i", str(f)]
    filter_str = "".join(f"[{i}:v]" for i in range(n)) + f"concat=n={n}:v=1:a=0[outv]"
    video_novoice = tmp / "video_novoice.mp4"
    run([
        "ffmpeg", "-y", *concat_inputs,
        "-filter_complex", filter_str,
        "-map", "[outv]",
        "-c:v", "libx264", "-preset", "veryfast", "-crf", "18",
        str(video_novoice),
    ])

    title_font = cfg["fonts"]["title"]
    caption_font = cfg["fonts"]["caption"]
    ass_path = tmp / "subs.ass"
    header = f"""[Script Info]
ScriptType: v4.00+
PlayResX: {W}
PlayResY: {H}
WrapStyle: 0
ScaledBorderAndShadow: yes

[V4+ Styles]
Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding
Style: Caption,{caption_font['family']},{caption_font['size']},{to_ass_color(caption_font['color'])},&H000000FF,&H00000000,&H96000000,1,0,0,0,100,100,0,0,1,3,0,2,60,60,{caption_font['margin_v']},1
Style: Title,{title_font['family']},{title_font['size']},{to_ass_color(title_font['color'])},&H000000FF,&H00000000,&H96000000,1,0,0,0,100,100,0,0,1,3,0,8,60,60,{title_font['margin_v']},1

[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
"""
    lines = [header]
    for sc in adj:
        caption = sc.get("caption")
        if caption:
            lines.append(f"Dialogue: 0,{to_ass_time(sc['start'])},{to_ass_time(sc['end'])},"
                          f"Caption,,0,0,0,,{ass_escape(caption)}\n")
        title = sc.get("title")
        if title:
            lines.append(f"Dialogue: 1,{to_ass_time(sc['start'])},{to_ass_time(sc['end'])},"
                          f"Title,,0,0,0,,{ass_escape(title)}\n")
    ass_path.write_text("".join(lines), encoding="utf-8")

    video_subs = tmp / "video_subs.mp4"
    # The ass filter's own option parser splits on ':', which breaks on a Windows
    # drive letter ("C:") even when escaped. Run from inside tmp/ with plain
    # filenames so no path ever needs a drive letter or an absolute prefix.
    run([
        "ffmpeg", "-y", "-i", video_novoice.name,
        "-vf", f"ass={ass_path.name}",
        "-c:v", "libx264", "-preset", "veryfast", "-crf", "18",
        video_subs.name,
    ], cwd=str(tmp))

    final_out = output_dir / cfg["output_name"]
    voice_db = cfg.get("voice_volume_db", 0)
    music_cfg = cfg.get("music")
    music_path = (project / music_cfg["file"]).resolve() if music_cfg else None
    if music_path and music_path.exists():
        db = music_cfg.get("volume_db", -20)
        print(f"Найдена фоновая музыка — добавляю тихо ({db} дБ относительно голоса).")
        run([
            "ffmpeg", "-y",
            "-i", str(video_subs), "-i", str(voice), "-i", str(music_path),
            "-filter_complex",
            f"[1:a]volume={voice_db}dB[vc];"
            f"[2:a]volume={db}dB,aloop=loop=-1:size=2e9[bg];"
            "[vc][bg]amix=inputs=2:duration=first:dropout_transition=2:normalize=0[aout]",
            "-map", "0:v", "-map", "[aout]",
            "-c:v", "copy", "-c:a", "aac", "-b:a", "192k",
            "-shortest", str(final_out),
        ])
    else:
        run([
            "ffmpeg", "-y",
            "-i", str(video_subs), "-i", str(voice),
            "-map", "0:v", "-map", "1:a",
            "-af", f"volume={voice_db}dB",
            "-c:v", "copy", "-c:a", "aac", "-b:a", "192k",
            "-shortest", str(final_out),
        ])

    print()
    print("ГОТОВО:", final_out)
    print("Длительность:", round(ffprobe_duration(final_out), 2), "с")


if __name__ == "__main__":
    scenario_arg = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("scenario.json")
    if not scenario_arg.exists():
        sys.exit(f"Не найден файл сценария: {scenario_arg.resolve()}")
    build(scenario_arg)

'@
[System.IO.File]::WriteAllText((Join-Path $Root "build_reels.py"), $buildPyContent, $Utf8Bom)
Write-Host "Записан build_reels.py"

$buildPs1Content = @'
$ErrorActionPreference = "Stop"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $here

$py = Get-Command python -ErrorAction SilentlyContinue
if (-not $py) {
    Write-Host "Python не найден. Установи: winget install --id Python.Python.3.12 -e" -ForegroundColor Red
    Read-Host "Нажмите Enter, чтобы закрыть"
    exit 1
}

python build_reels.py
if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host ("Готово! Смотри папку output внутри: " + $here) -ForegroundColor Green
} else {
    Write-Host "Что-то пошло не так, смотри сообщение об ошибке выше." -ForegroundColor Red
}
Read-Host "Нажмите Enter, чтобы закрыть"
'@
[System.IO.File]::WriteAllText((Join-Path $Root "build.ps1"), $buildPs1Content, $Utf8Bom)
Write-Host "Записан build.ps1"

Write-Host ""
Write-Host "Проверяю ffmpeg..."
$ffmpegCmd = Get-Command ffmpeg -ErrorAction SilentlyContinue
if (-not $ffmpegCmd) {
    $wingetCmd = Get-Command winget -ErrorAction SilentlyContinue
    if (-not $wingetCmd) {
        Write-Host "ffmpeg не найден, а winget недоступен." -ForegroundColor Red
        Write-Host "Установи вручную: https://www.gyan.dev/ffmpeg/builds/" -ForegroundColor Yellow
    } else {
        Write-Host "ffmpeg не найден. Устанавливаю через winget..."
        winget install --id Gyan.FFmpeg -e --source winget --accept-source-agreements --accept-package-agreements
        Write-Host "ffmpeg установлен. Открой новое окно PowerShell, чтобы обновился PATH." -ForegroundColor Green
    }
} else {
    Write-Host "ffmpeg уже установлен: $($ffmpegCmd.Source)"
}

Write-Host ""
Write-Host "Проверяю Python..."
$pyCmd = Get-Command python -ErrorAction SilentlyContinue
if (-not $pyCmd) {
    $wingetCmd = Get-Command winget -ErrorAction SilentlyContinue
    if (-not $wingetCmd) {
        Write-Host "Python не найден, а winget недоступен." -ForegroundColor Red
        Write-Host "Установи вручную: https://www.python.org/downloads/" -ForegroundColor Yellow
    } else {
        Write-Host "Python не найден. Устанавливаю через winget..."
        winget install --id Python.Python.3.12 -e --source winget --accept-source-agreements --accept-package-agreements
        Write-Host "Python установлен. Открой новое окно PowerShell, чтобы обновился PATH." -ForegroundColor Green
    }
} else {
    Write-Host "Python уже установлен: $($pyCmd.Source)"
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "ГОТОВО. Папка проекта:" -ForegroundColor Cyan
Write-Host "  $Root"
Write-Host ""
Write-Host "Чтобы перейти в неё в PowerShell, скопируй и вставь ровно эту строку:"
Write-Host "  cd `"$Root`"" -ForegroundColor Yellow
Write-Host ""
Write-Host "Дальше:"
Write-Host "  1. Положи scenario.json (пришлёт Claude) прямо в эту папку"
Write-Host "  2. Положи картинки/видео в media, озвучку в audio, музыку (по желанию) в music"
Write-Host "  3. Запусти build.ps1 (или 'python build_reels.py') из этой папки"
Write-Host "     Результат появится в output\"
Write-Host "==========================================" -ForegroundColor Cyan
Read-Host "Нажмите Enter, чтобы закрыть"
