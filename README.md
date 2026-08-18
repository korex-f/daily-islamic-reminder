# Quran Verse of the Day for Omarchy

An Omarchy bar widget that shows a daily Qur'anic ayah. A book icon sits in the
bar; clicking it opens a popup with the day's reference, the Arabic text, and a
translation.

The ayah rotates once per day (day-of-year indexed into a curated list of ~240
references bundled with the plugin) and its text is fetched from the free,
keyless [alquran.cloud](https://alquran.cloud) API — the Uthmani Arabic edition
and the configured translation in a single request. The result is cached
locally so the widget only hits the network once per day, not on every shell
restart.

## What it does

- Shows a book icon in the bar; hover reveals the day's reference.
- Opens a popup with the reference, Arabic text, and translation on left click.
- Middle click force-refreshes (ignores the daily cache).
- Right click sends today's ayah as a desktop notification.

## Install

Install from git and enable it:

```bash
omarchy plugin add https://github.com/korex-f/omarchy-quran-verse-of-the-day.git --enable
```

After enabling, Omarchy adds the widget to the right bar section. Move it if
desired:

```bash
omarchy bar plugin move dki.quran-verse-of-the-day --section center
```

## Configuration

The plugin has two settings, editable from Omarchy's settings panel or directly
in `~/.config/omarchy/shell.json` next to the widget's bar entry:

```json
{
  "id": "dki.quran-verse-of-the-day",
  "translation": "en.sahih",
  "showArabic": true
}
```

- `translation` — any [alquran.cloud translation edition code](https://alquran.cloud/editions)
  (`en.sahih`, `en.pickthall`, `en.yusufali`, `en.asad`, ...). Defaults to
  `en.sahih` (Saheeh International).
- `showArabic` — whether the popup shows the Arabic text above the
  translation. Defaults to `true`.

Changing either setting triggers an immediate refetch.

## Remove

```bash
omarchy plugin remove dki.quran-verse-of-the-day
```

## Update

```bash
omarchy plugin update dki.quran-verse-of-the-day
```

## Validate from source

```bash
omarchy plugin validate .
node tests/model.test.js
```

## Security and privacy

The plugin runs inside `omarchy-shell` when enabled. It calls `curl` once per
day to fetch the selected ayah from `api.alquran.cloud` and caches the result
in `~/.local/state/omarchy/quran-verse-of-the-day.json`. No other data leaves
the machine, and no API key is required.

## License

MIT. See [LICENSE](LICENSE).
