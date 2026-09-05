#!/usr/bin/env python3
"""Assembles reels-california.mp4 from images/voice/music per the fixed scenario timings.
Run this from inside the Reels-California project folder (or anywhere - it locates
the folder by its own location) after images/01..11.png and audio/voice.mp3 are in place.
"""
import subprocess
import sys
from pathlib import Path

PROJECT = Path(__file__).resolve().parent
IMAGES = PROJECT / "images"
AUDIO = PROJECT / "audio"
MUSIC = PROJECT / "music"
OUTPUT = PROJECT / "output"
TMP = PROJECT / "_tmp_build"

W, H, FPS = 1080, 1920, 30

# (image, nominal_start, nominal_end, title_or_None, caption)
SCENES = [
    ("01.png", 0.0, 4.0, "15 000 000 $ ЗА ЦЕЛЫЙ ШТАТ",
     "США купили Калифорнию за 15 миллионов долларов."),
    ("02.png", 4.0, 9.0, "ЗА 9 ДНЕЙ ДО ДОГОВОРА",
     "А золото там нашли за девять дней до сделки — и о нём не знала ни одна из сторон."),
    ("03.png", 9.0, 15.0, "ПРЕДЛОЖЕНИЕ: 30 МЛН + ДОЛГИ",
     "Сначала Америка предложила купить Калифорнию по-хорошему — 30 миллионов наличными плюс мексиканские долги."),
    ("04.png", 15.0, 20.0, "ОТКАЗ ПРИНЯТЬ ПОСЛА",
     "Но ни один министр в Мехико даже не захотел встретиться с американским посланником."),
    ("05.png", 20.0, 25.0, "ВОЙНА 1846–1848",
     "В 1846-м началась война с США — и Мексика её проиграла."),
    ("06.png", 25.0, 33.0, "4 ПРЕЗИДЕНТА ЗА 1 ГОД",
     "Огромная страна — но власть менялась постоянно: за один только 1846 год в Мехико сменилось "
     "четыре президента, шесть военных министров и шестнадцать министров финансов."),
    ("07.png", 33.0, 38.0, "ГУАДАЛУПЕ-ИДАЛЬГО · 1848",
     "Итог — мирный договор Гуадалупе-Идальго, февраль 1848 года."),
    ("08.png", 38.0, 44.0, "ВДВОЕ ДЕШЕВЛЕ",
     "Америка забрала всю Калифорнию за 15 миллионов плюс 3 миллиона долга. "
     "Почти вдвое дешевле первого предложения."),
    ("09.png", 44.0, 47.0, None,
     "А теперь самое обидное для Мексики."),
    ("10.png", 47.0, 53.0, "81 МЛН $ ЗА 1 ГОД",
     "В 1852 году золотоискатели намыли в Калифорнии золота на 81 миллион долларов. За один год."),
    ("11.png", 53.0, 58.0, "ХУДШАЯ СДЕЛКА В ИСТОРИИ?",
     "Штат окупился золотом примерно за пару месяцев. Худшая сделка в истории?"),
]


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


def check_inputs():
    missing = []
    for img, *_ in SCENES:
        if not (IMAGES / img).exists():
            missing.append(f"images/{img}")
    voice = AUDIO / "voice.mp3"
    if not voice.exists():
        missing.append("audio/voice.mp3")
    if missing:
        print("Не хватает файлов:")
        for m in missing:
            print(" -", m)
        sys.exit(1)
    return voice


def build():
    TMP.mkdir(exist_ok=True)
    OUTPUT.mkdir(exist_ok=True)
    voice = check_inputs()

    voice_dur = ffprobe_duration(voice)
    nominal_total = SCENES[-1][2]
    scale = voice_dur / nominal_total
    print(f"Длительность озвучки: {voice_dur:.2f} с (сценарий рассчитан на {nominal_total:.0f} с, "
          f"коэффициент подгонки {scale:.4f})")

    adj = []
    for img, s, e, title, caption in SCENES:
        adj.append([img, s * scale, e * scale, title, caption])
    adj[-1][2] = voice_dur  # last frame ends exactly with the voice track

    segment_files = []
    for i, (img, s, e, title, caption) in enumerate(adj):
        dur = e - s
        nframes = max(1, round(dur * FPS))
        seg = TMP / f"seg_{i:02d}.mp4"
        step = 0.35 / nframes
        if i % 2 == 0:
            zexpr = f"min(zoom+{step:.6f},1.18)"  # slow zoom-in (наезд)
        else:
            zexpr = f"if(eq(on,0),1.18,max(zoom-{step:.6f},1.0))"  # slow zoom-out (панорама/отъезд)
        xexpr = "iw/2-(iw/zoom/2)"
        yexpr = "ih/2-(ih/zoom/2)"
        vf = (
            f"scale={W*3}:{H*3}:force_original_aspect_ratio=increase,"
            f"crop={W*3}:{H*3},"
            f"zoompan=z='{zexpr}':d={nframes}:x='{xexpr}':y='{yexpr}':s={W}x{H}:fps={FPS},"
            f"format=yuv420p"
        )
        run([
            "ffmpeg", "-y", "-loop", "1", "-i", str(IMAGES / img),
            "-t", f"{dur:.3f}", "-vf", vf,
            "-c:v", "libx264", "-preset", "veryfast", "-crf", "18",
            "-r", str(FPS), str(seg),
        ])
        segment_files.append(seg)

    # Feed each segment as its own -i input and join with the concat *filter* rather than
    # the concat *demuxer* (which reads paths from a text list file) - on Windows the demuxer
    # misreads non-ASCII characters (e.g. a Cyrillic username) in that list file and fails.
    n = len(segment_files)
    concat_inputs = []
    for f in segment_files:
        concat_inputs += ["-i", str(f)]
    filter_str = "".join(f"[{i}:v]" for i in range(n)) + f"concat=n={n}:v=1:a=0[outv]"
    video_novoice = TMP / "video_novoice.mp4"
    run([
        "ffmpeg", "-y", *concat_inputs,
        "-filter_complex", filter_str,
        "-map", "[outv]",
        "-c:v", "libx264", "-preset", "veryfast", "-crf", "18",
        str(video_novoice),
    ])

    ass_path = TMP / "subs.ass"
    header = f"""[Script Info]
ScriptType: v4.00+
PlayResX: {W}
PlayResY: {H}
WrapStyle: 0
ScaledBorderAndShadow: yes

[V4+ Styles]
Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding
Style: Caption,Arial,58,&H00FFFFFF,&H000000FF,&H00000000,&H96000000,1,0,0,0,100,100,0,0,1,3,0,2,60,60,90,1
Style: Title,Arial,50,&H0000E5FF,&H000000FF,&H00000000,&H96000000,1,0,0,0,100,100,0,0,1,3,0,8,60,60,90,1

[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
"""
    lines = [header]
    for img, s, e, title, caption in adj:
        lines.append(f"Dialogue: 0,{to_ass_time(s)},{to_ass_time(e)},Caption,,0,0,0,,{ass_escape(caption)}\n")
        if title:
            lines.append(f"Dialogue: 1,{to_ass_time(s)},{to_ass_time(e)},Title,,0,0,0,,{ass_escape(title)}\n")
    ass_path.write_text("".join(lines), encoding="utf-8")

    video_subs = TMP / "video_subs.mp4"
    # The ass filter's option parser splits on ':' - a Windows drive letter like "C:" breaks
    # it even when escaped. Run from inside TMP and reference plain filenames to avoid this.
    run([
        "ffmpeg", "-y", "-i", video_novoice.name,
        "-vf", f"ass={ass_path.name}",
        "-c:v", "libx264", "-preset", "veryfast", "-crf", "18",
        video_subs.name,
    ], cwd=str(TMP))

    music = MUSIC / "music.mp3"
    final_out = OUTPUT / "reels-california.mp4"
    if music.exists():
        print("Найдена фоновая музыка — добавляю тихо (-20 дБ относительно голоса).")
        run([
            "ffmpeg", "-y",
            "-i", str(video_subs), "-i", str(voice), "-i", str(music),
            "-filter_complex",
            "[2:a]volume=-20dB,aloop=loop=-1:size=2e9[bg];"
            "[1:a][bg]amix=inputs=2:duration=first:dropout_transition=2:normalize=0[aout]",
            "-map", "0:v", "-map", "[aout]",
            "-c:v", "copy", "-c:a", "aac", "-b:a", "192k",
            "-shortest", str(final_out),
        ])
    else:
        run([
            "ffmpeg", "-y",
            "-i", str(video_subs), "-i", str(voice),
            "-map", "0:v", "-map", "1:a",
            "-c:v", "copy", "-c:a", "aac", "-b:a", "192k",
            "-shortest", str(final_out),
        ])

    print()
    print("ГОТОВО:", final_out)
    print("Длительность:", round(ffprobe_duration(final_out), 2), "с")


if __name__ == "__main__":
    build()
