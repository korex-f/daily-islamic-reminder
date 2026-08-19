# Daily Islamic Reminder for Omarchy

An Omarchy Quattro bar widget and panel that presents a daily Quran ayah, a graded Hadith, or both. The bar stays compact; click **Today’s Reminder** to read Arabic and English text, provenance, and the visible Hadith grade.

![Plugin preview](preview.png)

## What it does

- Rotates Quran and Hadith independently once per local calendar day.
- Supports sequential (resumable) or deterministic random rotation per source.
- Defaults to both sources, Saheeh International (`en.sahih`), and records graded sahih or hasan. The default `any` collection pool uses Sahih al-Bukhari and Sahih Muslim; other collection records are considered only when their source-supplied grade passes the active filter.
- Keeps Quran Arabic separate from translation, and presents Hadith metadata separately so no commentary can be mistaken for Quran text.
- Caches immutable text per reference and edition under `~/.config/omarchy/plugins/dki.quran-verse-of-the-day/cache/`; the same cached ayah or Hadith is not fetched again. Quran and Hadith edition metadata refresh at most weekly.

## Sources and attribution

- Quran Arabic, translations, and optional recitation links come from [Al Quran Cloud](https://alquran.cloud/) / [api.alquran.cloud](https://api.alquran.cloud/). The selected edition is named beneath each translation.
- Hadith Arabic, English, collection/book references, and grade metadata come from [fawazahmed0/hadith-api](https://github.com/fawazahmed0/hadith-api), served through [jsDelivr](https://cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@1/editions.min.json). A Hadith is never rendered without a visible grade.

Neither source needs an API key; this repository contains none.

## Install

```bash
omarchy plugin add https://github.com/korex-f/daily-islamic-reminder.git --enable
```

The widget is added to the right bar section. To move it:

```bash
omarchy bar plugin move dki.quran-verse-of-the-day --section center
```

## Settings

Click the widget, then use the persistent gear icon in its panel. Settings are saved to the Omarchy bar entry and include:

- Quran translation edition, with a searchable sensible-English list or a directly entered Al Quran Cloud edition code;
- preferred Hadith collection (`any`, Bukhari, Muslim, Abu Dawud, or Tirmidhi);
- rotation mode (`both`, `quran-only`, or `hadith-only`);
- sequential/random order independently for Quran and Hadith;
- the opt-in filter to include grades beyond sahih/hasan; and
- optional Quran recitation link.

On first open the panel opens its settings surface with suggested defaults; there is no install-time wizard or background service.

## Network, cache, and privacy

The plugin runs commands through Omarchy’s unsandboxed shell integration to make HTTPS `curl` requests to the two sources above. It requests only selected, uncached immutable records on panel open, plus Quran edition metadata at most weekly. No account, API key, telemetry, or personal content is sent.

There is no offline catalogue bundled with the plugin. Previously viewed items remain readable from the local cache; a new uncached item needs network access. Al Quran Cloud has a soft per-second rate limit, so the plugin deliberately does not poll in the background.

## Remove cleanly

```bash
omarchy plugin remove dki.quran-verse-of-the-day
rm -rf ~/.config/omarchy/plugins/dki.quran-verse-of-the-day/cache
```

The second command is optional and removes only this plugin’s cached texts and rotation state.

## Development checks

```bash
omarchy plugin validate .
qmllint BarWidget.qml Panel.qml Service.qml
node tests/model.test.js
```

## License

MIT. See [LICENSE](LICENSE).
