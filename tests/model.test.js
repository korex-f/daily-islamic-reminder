const assert = require("node:assert/strict")
const model = require("../Model.js")

// The curated list is finite and deterministic: the same date always maps to
// the same ayah, and every reference resolves to a known surah and ayah.
const surahCounts = [7,286,200,176,120,165,206,75,129,109,123,111,43,52,99,128,111,110,98,135,112,78,118,64,77,227,93,88,69,60,34,30,73,54,45,83,182,88,75,85,54,53,89,59,37,35,38,29,18,45,60,49,62,55,78,96,29,22,24,13,14,11,11,18,12,12,30,52,52,44,28,28,20,56,40,31,50,40,46,42,29,19,36,25,22,17,19,26,30,20,15,21,11,8,8,19,5,8,8,11,11,8,3,9,5,4,7,3,6,3,5,4,5,6]

// Day-of-year indexing is stable across years, so Jan 1 and Dec 31 of any
// year land on the same reference — the widget doesn't drift by year.
assert.ok(model.AYAHS.length >= 180, "curated list should be substantial")
assert.ok(model.AYAHS.length <= 300, "curated list should stay hand-reviewed")
assert.equal(model.referenceForDate(new Date(2026, 0, 1)), model.referenceForDate(new Date(2027, 0, 1)))
assert.ok(model.referenceForDate(new Date()).length > 0)

// Every curated reference is within the bounds of its surah.
for (const ref of model.AYAHS) {
  const r = model.parseReference(ref)
  assert.ok(r, "malformed reference " + ref)
  assert.ok(r.surah >= 1 && r.surah <= 114, "surah out of range " + ref)
  assert.ok(r.ayah >= 1 && r.end >= r.ayah, "bad ayah span " + ref)
  assert.ok(r.end <= surahCounts[r.surah - 1], "ayah beyond end of surah " + ref)
  const label = model.referenceLabel(ref)
  assert.ok(label.startsWith(model.SURAH_NAMES[r.surah - 1]), "label should name the surah: " + ref)
}

// Reference labels read the way people cite the Qur'an.
assert.equal(model.referenceLabel("2:255"), "Al-Baqara 2:255")
assert.equal(model.referenceLabel("1:1-7"), "Al-Faatiha 1:1-7")

// API URLs request both Arabic and the translation in one call.
assert.equal(
  model.apiUrl("2:255", "en.sahih"),
  "https://api.alquran.cloud/v1/ayah/2:255/editions/quran-uthmani,en.sahih"
)
assert.equal(model.apiUrl("1:1-7", "EN.Pickthall"), "https://api.alquran.cloud/v1/ayah/1:1-7/editions/quran-uthmani,en.pickthall")

// ISO dates pad, and text cleaning collapses verse-number newlines.
assert.equal(model.isoDate(new Date(2026, 0, 5)), "2026-01-05")
assert.equal(model.cleanVerseText("  a\n\nb \n c  "), "a b c")

console.log("Quran reference tests passed")
