#Requires -Version 5.1
# Reels-California - setup script
# Creates the project folder structure on the Desktop, writes the scenario/prompt files,
# and makes sure ffmpeg + Python are installed (via winget) for the later assembly step.

$ErrorActionPreference = "Stop"

$Root   = Join-Path $env:USERPROFILE "Desktop\Reels-California"
$Images = Join-Path $Root "images"
$Audio  = Join-Path $Root "audio"
$Music  = Join-Path $Root "music"
$Output = Join-Path $Root "output"

Write-Host "=== Reels-California: настройка проекта ===" -ForegroundColor Cyan
Write-Host ""

foreach ($d in @($Root, $Images, $Audio, $Music, $Output)) {
    if (-not (Test-Path $d)) {
        New-Item -ItemType Directory -Path $d -Force | Out-Null
        Write-Host "Создана папка: $d"
    } else {
        Write-Host "Папка уже есть:  $d"
    }
}

$Utf8Bom = New-Object System.Text.UTF8Encoding($true)

$scenarioContent = @'
# Сценарий Reels: "Худшая сделка в истории?" (Калифорния)

Формат: вертикальный 1080x1920, 11 кадров, общая длительность ~58 секунд.

| # | Тайминг | Титр (вверху) | Текст диктора |
|---|---------|----------------|----------------|
| 1 | 0:00–0:04 | «15 000 000 $ ЗА ЦЕЛЫЙ ШТАТ» | США купили Калифорнию за 15 миллионов долларов. |
| 2 | 0:04–0:09 | «ЗА 9 ДНЕЙ ДО ДОГОВОРА» | А золото там нашли за девять дней до сделки — и о нём не знала ни одна из сторон. |
| 3 | 0:09–0:15 | «ПРЕДЛОЖЕНИЕ: 30 МЛН + ДОЛГИ» | Сначала Америка предложила купить Калифорнию по-хорошему — 30 миллионов наличными плюс мексиканские долги. |
| 4 | 0:15–0:20 | «ОТКАЗ ПРИНЯТЬ ПОСЛА» | Но ни один министр в Мехико даже не захотел встретиться с американским посланником. |
| 5 | 0:20–0:25 | «ВОЙНА 1846–1848» | В 1846-м началась война с США — и Мексика её проиграла. |
| 6 | 0:25–0:33 | «4 ПРЕЗИДЕНТА ЗА 1 ГОД» | Огромная страна — но власть менялась постоянно: за один только 1846 год в Мехико сменилось четыре президента, шесть военных министров и шестнадцать министров финансов. |
| 7 | 0:33–0:38 | «ГУАДАЛУПЕ-ИДАЛЬГО · 1848» | Итог — мирный договор Гуадалупе-Идальго, февраль 1848 года. |
| 8 | 0:38–0:44 | «ВДВОЕ ДЕШЕВЛЕ» | Америка забрала всю Калифорнию за 15 миллионов плюс 3 миллиона долга. Почти вдвое дешевле первого предложения. |
| 9 | 0:44–0:47 | (без титра, пауза) | А теперь самое обидное для Мексики. |
| 10 | 0:47–0:53 | «81 МЛН $ ЗА 1 ГОД» | В 1852 году золотоискатели намыли в Калифорнии золота на 81 миллион долларов. За один год. |
| 11 | 0:53–0:58 | «ХУДШАЯ СДЕЛКА В ИСТОРИИ?» | Штат окупился золотом примерно за пару месяцев. Худшая сделка в истории? |

## Единый текст озвучки (содержимое voice.mp3)

США купили Калифорнию за пятнадцать миллионов долларов. А золото там нашли за девять дней до сделки — и о нём не знала ни одна из сторон. Сначала Америка предложила купить Калифорнию по-хорошему — тридцать миллионов наличными плюс мексиканские долги. Но ни один министр в Мехико даже не захотел встретиться с американским посланником. В тысяча восемьсот сорок шестом началась война с США — и Мексика её проиграла. Огромная страна — но власть менялась постоянно: за один только сорок шестой год в Мехико сменилось четыре президента, шесть военных министров и шестнадцать министров финансов. Итог — мирный договор Гуадалупе-Идальго, февраль тысяча восемьсот сорок восьмого. Америка забрала всю Калифорнию за пятнадцать миллионов плюс три миллиона долга. Почти вдвое дешевле первого предложения. А теперь самое обидное для Мексики. В тысяча восемьсот пятьдесят втором году золотоискатели намыли в Калифорнии золота на восемьдесят один миллион долларов. За один год. Штат окупился золотом примерно за пару месяцев. Худшая сделка в истории?

'@
[System.IO.File]::WriteAllText((Join-Path $Root "scenario.md"), $scenarioContent, $Utf8Bom)
Write-Host "Записан scenario.md"

$promptsContent = @'
01: Cinematic historical realism, close-up of an antique 1840s map of California on a dark wooden desk, a hand sliding stacks of silver dollar coins across it, warm candlelight, deep shadows, dramatic side lighting, 35mm lens photography, shallow depth of field, cinematic composition, vertical 9:16.
02: Cinematic historical realism, macro shot of bright gold flakes glinting in clear shallow river water over dark gravel, a beam of morning sunlight igniting the metal, misty Sierra Nevada river at dawn, 35mm lens photography, dramatic golden light, cinematic composition, vertical 9:16.
03: Cinematic historical realism, 1840s American diplomat in a formal dark tailcoat holding official documents and a leather case of gold coins, dim candlelit office, oil-painting atmosphere, dramatic Rembrandt lighting, 35mm lens photography, cinematic composition, vertical 9:16.
04: Cinematic historical realism, an 1840s Mexican government minister in ornate military uniform turning his back and walking away through a grand colonial hall, tall closed wooden doors, cold shadowed light, 35mm lens photography, cinematic composition, vertical 9:16.
05: Cinematic historical realism, chaotic 1846 Mexican-American War battlefield, soldiers with muskets and cannon smoke on a dusty plain, dramatic overcast sky, gritty atmosphere, low-angle shot, 35mm lens photography, cinematic composition, vertical 9:16.
06: Cinematic historical realism, a wall of ornate gilded portrait frames of 19th-century Mexican statesmen in a shadowy government hall, some frames crooked and falling, candlelight and deep shadows, unsettling atmosphere, 35mm lens photography, cinematic composition, vertical 9:16.
07: Cinematic historical realism, candlelit 19th-century chamber, diplomats in 1840s formal attire signing the Treaty of Guadalupe Hidalgo, quill on parchment, solemn mood, warm candlelight, deep shadows, overhead angle, 35mm lens photography, cinematic composition, vertical 9:16.
08: Cinematic historical realism, antique map of North America on a war table, the vast California and southwestern territory glowing as it changes hands, brass compass and coins nearby, dramatic warm lamplight, 35mm lens photography, cinematic composition, vertical 9:16.
09: Cinematic historical realism, extreme close-up of a weathered Mexican official's face in shadow, tense expression, single hard rim light, dark background, dramatic chiaroscuro, 35mm lens photography, cinematic composition, vertical 9:16.
10: Cinematic historical realism, sweeping wide shot of a crowded 1852 California gold rush camp, hundreds of prospectors panning and digging along a river, tents, dust and harsh sunlight, epic scale, 35mm lens photography, cinematic composition, vertical 9:16.
11: Cinematic historical realism, extreme close-up of a large raw gold nugget in a miner's dirt-streaked open palm, water droplets, warm dramatic backlight, dark background, shallow depth of field, 35mm lens photography, cinematic composition, vertical 9:16.

'@
[System.IO.File]::WriteAllText((Join-Path $Root "image-prompts.txt"), $promptsContent, $Utf8Bom)
Write-Host "Записан image-prompts.txt"

$buildPyContent = @'
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


def run(cmd):
    print("+", " ".join(str(c) for c in cmd))
    subprocess.run(cmd, check=True)


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

    concat_list = TMP / "concat.txt"
    concat_list.write_text("".join(f"file '{f.resolve().as_posix()}'\n" for f in segment_files))
    video_novoice = TMP / "video_novoice.mp4"
    run([
        "ffmpeg", "-y", "-f", "concat", "-safe", "0", "-i", str(concat_list),
        "-c", "copy", str(video_novoice),
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
    # ffmpeg's subtitles/ass filter needs forward slashes and escaped colons on Windows paths
    ass_arg = ass_path.resolve().as_posix().replace(":", "\\:")
    run([
        "ffmpeg", "-y", "-i", str(video_novoice),
        "-vf", f"ass={ass_arg}",
        "-c:v", "libx264", "-preset", "veryfast", "-crf", "18",
        str(video_subs),
    ])

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

'@
[System.IO.File]::WriteAllText((Join-Path $Root "build_reels.py"), $buildPyContent, $Utf8Bom)
Write-Host "Записан build_reels.py"

$buildPs1Content = @'
$ErrorActionPreference = "Stop"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $here

$py = Get-Command python -ErrorAction SilentlyContinue
if (-not $py) {
    Write-Host "Python не найден. Сначала запусти setup.ps1 ещё раз (он поставит Python) или установи его вручную: winget install Python.Python.3.12" -ForegroundColor Red
    Read-Host "Нажмите Enter, чтобы закрыть"
    exit 1
}

python build_reels.py
if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host ("Готово! Файл: " + $here + "\output\reels-california.mp4") -ForegroundColor Green
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
        Write-Host "ffmpeg не найден, а winget недоступен в этой системе." -ForegroundColor Red
        Write-Host "Установи ffmpeg вручную: https://www.gyan.dev/ffmpeg/builds/ и добавь его в PATH." -ForegroundColor Yellow
    } else {
        Write-Host "ffmpeg не найден. Устанавливаю через winget (это может занять пару минут)..."
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
        Write-Host "Python не найден, а winget недоступен в этой системе." -ForegroundColor Red
        Write-Host "Установи Python вручную: https://www.python.org/downloads/" -ForegroundColor Yellow
    } else {
        Write-Host "Python не найден. Устанавливаю через winget (это может занять пару минут)..."
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
Write-Host "Дальше вручную:"
Write-Host "  1. Положи картинки 01.png ... 11.png в папку images"
Write-Host "  2. Положи voice.mp3 в папку audio"
Write-Host "  3. (по желанию) положи music.mp3 в папку music"
Write-Host "  4. Когда всё на месте - запусти build.ps1 внутри папки проекта"
Write-Host "     (или напиши мне 'файлы готовы', если я собираю ролик для тебя)."
Write-Host "     Результат появится в output\reels-california.mp4"
Write-Host "==========================================" -ForegroundColor Cyan
Read-Host "Нажмите Enter, чтобы закрыть"
