# video-market

## Скиллы Claude Code

### video-use — монтаж видео по диалогу

Установлен как проектный скилл в [`.claude/skills/video-use`](.claude/skills/video-use), источник: [browser-use/video-use](https://github.com/browser-use/video-use) (MIT).

Что умеет: транскрибирует видео, вырезает слова-паразиты и паузы, применяет цветокоррекцию, монтирует аудиопереходы, вшивает субтитры, генерирует анимационные оверлеи (HyperFrames / Remotion / Manim / PIL), сам проверяет результат перед показом и хранит память проекта между сессиями.

**Перед первым использованием:**

1. Установить `ffmpeg` (обязательно) и опционально `yt-dlp`.
2. Установить Python-зависимости скилла: `cd .claude/skills/video-use && uv sync` (или `pip install -e .`).
3. Получить ключ ElevenLabs (нужен для транскрибации Scribe) на https://elevenlabs.io/app/settings/api-keys и положить его в `.claude/skills/video-use/.env`:
   ```
   ELEVENLABS_API_KEY=...
   ```
   Файл `.env` уже в `.gitignore` — в репозиторий он не попадёт.

Подробности установки — в [`install.md`](.claude/skills/video-use/install.md), правила монтажа и рабочий процесс — в [`SKILL.md`](.claude/skills/video-use/SKILL.md).

**Использование:** положить исходные видео в любую папку проекта и в чате Claude Code попросить, например, «смонтируй из этих клипов промо-ролик». Результат появится в `<папка_с_видео>/edit/final.mp4`.
