// Pure reference math for the daily-ayah widget. Everything here is
// locale- and Qt-free so it can be unit tested under node
// (tests/model.test.js); the QML owns layout and network plumbing.

// Surah names indexed by surah number (1-based), used to build the
// human-readable reference label like "Al-Baqara 2:255".
var SURAH_NAMES = [
  "Al-Faatiha",
  "Al-Baqara",
  "Aal-i-Imraan",
  "An-Nisaa",
  "Al-Maaida",
  "Al-An'aam",
  "Al-A'raaf",
  "Al-Anfaal",
  "At-Tawba",
  "Yunus",
  "Hud",
  "Yusuf",
  "Ar-Ra'd",
  "Ibrahim",
  "Al-Hijr",
  "An-Nahl",
  "Al-Israa",
  "Al-Kahf",
  "Maryam",
  "Taa-Haa",
  "Al-Anbiyaa",
  "Al-Hajj",
  "Al-Muminoon",
  "An-Noor",
  "Al-Furqaan",
  "Ash-Shu'araa",
  "An-Naml",
  "Al-Qasas",
  "Al-Ankaboot",
  "Ar-Room",
  "Luqman",
  "As-Sajda",
  "Al-Ahzaab",
  "Saba",
  "Faatir",
  "Yaseen",
  "As-Saaffaat",
  "Saad",
  "Az-Zumar",
  "Ghafir",
  "Fussilat",
  "Ash-Shura",
  "Az-Zukhruf",
  "Ad-Dukhaan",
  "Al-Jaathiya",
  "Al-Ahqaf",
  "Muhammad",
  "Al-Fath",
  "Al-Hujuraat",
  "Qaaf",
  "Adh-Dhaariyat",
  "At-Tur",
  "An-Najm",
  "Al-Qamar",
  "Ar-Rahmaan",
  "Al-Waaqia",
  "Al-Hadid",
  "Al-Mujaadila",
  "Al-Hashr",
  "Al-Mumtahana",
  "As-Saff",
  "Al-Jumu'a",
  "Al-Munaafiqoon",
  "At-Taghaabun",
  "At-Talaaq",
  "At-Tahrim",
  "Al-Mulk",
  "Al-Qalam",
  "Al-Haaqqa",
  "Al-Ma'aarij",
  "Nooh",
  "Al-Jinn",
  "Al-Muzzammil",
  "Al-Muddaththir",
  "Al-Qiyaama",
  "Al-Insaan",
  "Al-Mursalaat",
  "An-Naba",
  "An-Naazi'aat",
  "Abasa",
  "At-Takwir",
  "Al-Infitaar",
  "Al-Mutaffifin",
  "Al-Inshiqaaq",
  "Al-Burooj",
  "At-Taariq",
  "Al-A'laa",
  "Al-Ghaashiya",
  "Al-Fajr",
  "Al-Balad",
  "Ash-Shams",
  "Al-Lail",
  "Ad-Dhuhaa",
  "Ash-Sharh",
  "At-Tin",
  "Al-Alaq",
  "Al-Qadr",
  "Al-Bayyina",
  "Az-Zalzala",
  "Al-Aadiyaat",
  "Al-Qaari'a",
  "At-Takaathur",
  "Al-Asr",
  "Al-Humaza",
  "Al-Fil",
  "Quraish",
  "Al-Maa'un",
  "Al-Kawthar",
  "Al-Kaafiroon",
  "An-Nasr",
  "Al-Masad",
  "Al-Ikhlaas",
  "Al-Falaq",
  "An-Naas"
]

// Curated ayahs cycled by day-of-year. alquran.cloud has no dedicated
// "ayah of the day" endpoint, so the plugin picks a reference itself and
// fetches its text by reference.
var AYAHS = [
  "1:1-7",
  "2:2",
  "2:45",
  "2:152",
  "2:153",
  "2:155-157",
  "2:186",
  "2:216",
  "2:255",
  "2:261",
  "2:269",
  "2:285-286",
  "3:8",
  "3:16",
  "3:31",
  "3:92",
  "3:103",
  "3:110",
  "3:139",
  "3:159",
  "3:160",
  "3:173",
  "3:185",
  "4:36",
  "4:58",
  "4:59",
  "4:110",
  "4:135",
  "5:3",
  "5:8",
  "5:32",
  "5:35",
  "5:90",
  "5:105",
  "6:32",
  "6:59",
  "6:63",
  "6:103",
  "6:115",
  "6:125",
  "6:162-163",
  "7:26",
  "7:56",
  "7:128",
  "7:180",
  "7:199",
  "7:205",
  "8:2",
  "8:46",
  "8:61",
  "9:51",
  "9:71",
  "9:119",
  "9:129",
  "10:57",
  "10:62",
  "10:99",
  "10:107",
  "11:6",
  "11:88",
  "11:113",
  "11:115",
  "12:87",
  "12:108",
  "13:28",
  "13:37",
  "14:7",
  "14:34",
  "14:42",
  "15:9",
  "16:18",
  "16:90",
  "16:97",
  "16:125",
  "16:126",
  "17:23-24",
  "17:29",
  "17:32",
  "17:36",
  "17:70",
  "17:80-81",
  "17:85",
  "18:10",
  "18:28",
  "18:46",
  "18:110",
  "19:78",
  "20:14",
  "20:25-28",
  "20:124-126",
  "20:131",
  "21:35",
  "21:83",
  "21:107",
  "22:37",
  "22:46",
  "22:77",
  "23:1-2",
  "23:51-52",
  "23:97-98",
  "24:26",
  "24:30-31",
  "24:35",
  "25:63",
  "25:74",
  "26:88-89",
  "27:62",
  "28:24",
  "28:56",
  "28:77",
  "29:41",
  "29:45",
  "29:57",
  "29:69",
  "30:21",
  "30:30",
  "30:53",
  "31:17-19",
  "33:21",
  "33:35",
  "33:41-42",
  "33:56",
  "33:70-71",
  "34:39",
  "35:2",
  "35:5",
  "35:15",
  "36:12",
  "36:58",
  "36:82",
  "37:180-182",
  "38:87-88",
  "39:9",
  "39:53",
  "39:73",
  "40:44",
  "40:60",
  "41:30",
  "41:34",
  "41:53",
  "42:19",
  "42:30",
  "42:36-38",
  "43:13",
  "43:36",
  "44:58",
  "45:13",
  "45:22",
  "45:36-37",
  "46:13",
  "47:7",
  "47:19",
  "48:4",
  "48:28-29",
  "49:10",
  "49:11",
  "49:12",
  "49:13",
  "50:16",
  "50:39",
  "51:56",
  "52:49",
  "53:39",
  "53:43-44",
  "54:17",
  "54:49",
  "55:13",
  "55:26-27",
  "55:33",
  "55:60",
  "56:79",
  "56:87",
  "57:3",
  "57:20",
  "57:22",
  "58:11",
  "59:18",
  "59:19",
  "59:22-24",
  "60:7-8",
  "61:4",
  "61:8",
  "61:13",
  "62:9",
  "62:11",
  "63:9",
  "64:11",
  "64:16",
  "65:2-3",
  "65:11",
  "66:8",
  "67:1",
  "67:15",
  "68:4",
  "69:33",
  "70:4",
  "71:12",
  "72:13",
  "73:8",
  "73:20",
  "74:4-5",
  "75:2",
  "76:7-9",
  "77:20",
  "78:8-9",
  "79:40-41",
  "80:24",
  "81:27-29",
  "82:6",
  "83:4-6",
  "84:6",
  "85:21-22",
  "86:5",
  "87:1-2",
  "87:14-15",
  "88:8-10",
  "89:27-30",
  "90:12-13",
  "91:7-8",
  "92:5-7",
  "93:5-8",
  "94:5-6",
  "94:7-8",
  "95:4-6",
  "96:1-5",
  "97:1-3",
  "98:5-8",
  "99:7-8",
  "100:8",
  "101:8-9",
  "102:1-2",
  "102:8",
  "103:1-3",
  "104:1-3",
  "105:1",
  "106:3-4",
  "107:4-7",
  "108:1-3",
  "109:1-6",
  "110:1-3",
  "111:1-5",
  "112:1-4",
  "113:1-5",
  "114:1-6"
]

function dayOfYear(date) {
  var start = new Date(date.getFullYear(), 0, 0)
  var diff = date.getTime() - start.getTime()
  var oneDay = 24 * 60 * 60 * 1000
  return Math.floor(diff / oneDay)
}

function referenceForDate(date) {
  var idx = dayOfYear(date) % AYAHS.length
  if (idx < 0) idx += AYAHS.length
  return AYAHS[idx]
}

function pad2(n) {
  return n < 10 ? "0" + n : String(n)
}

function isoDate(date) {
  return date.getFullYear() + "-" + pad2(date.getMonth() + 1) + "-" + pad2(date.getDate())
}

// Parse a reference like "2:255" or "1:1-7" into { surah, ayah, end }.
function parseReference(reference) {
  var m = String(reference || "").match(/^(\d+):(\d+)(?:-(\d+))?$/)
  if (!m) return null
  return { surah: parseInt(m[1], 10), ayah: parseInt(m[2], 10), end: m[3] ? parseInt(m[3], 10) : parseInt(m[2], 10) }
}

// Human-readable label: "2:255" -> "Al-Baqara 2:255", "1:1-7" -> "Al-Faatiha 1:1-7".
function referenceLabel(reference) {
  var r = parseReference(reference)
  if (!r) return String(reference || "")
  var name = SURAH_NAMES[r.surah - 1] || ("Surah " + r.surah)
  var span = r.end === r.ayah ? "" : "-" + r.end
  return name + " " + r.surah + ":" + r.ayah + span
}

// alquran.cloud takes references with a colon (e.g. "2:255" or "1:1-7");
// both editions are fetched in one call, Arabic first then the translation.
function apiUrl(reference, translation) {
  var ref = String(reference || "").trim()
  var t = String(translation || "en.sahih").trim().toLowerCase()
  if (t === "") t = "en.sahih"
  return "https://api.alquran.cloud/v1/ayah/" + ref + "/editions/quran-uthmani," + encodeURIComponent(t)
}

// alquran.cloud returns text with verse-number breaks and leading/trailing
// newlines; collapse to a single clean paragraph for display.
function cleanVerseText(raw) {
  return String(raw || "").replace(/\s+/g, " ").trim()
}

function choice(value, allowed, fallback) {
  var v = String(value || "").toLowerCase()
  return allowed.indexOf(v) >= 0 ? v : fallback
}

function nextPosition(position, length, style, salt) {
  if (length <= 0) return -1
  if (String(style) !== "random") return (Number(position) + 1 + length) % length
  // A deterministic daily pick avoids changing an item during the same day,
  // while storing the result still makes changing modes resumable.
  var hash = 0
  var text = String(salt || "")
  for (var i = 0; i < text.length; i++) hash = ((hash * 31) + text.charCodeAt(i)) >>> 0
  return hash % length
}

function isOlderThanDays(date, days) {
  var then = Date.parse(String(date || ""))
  return !isFinite(then) || Date.now() - then > days * 86400000
}

function quranUrl(reference, translation) { return apiUrl(reference, translation) }
function hadithUrl(edition, number) {
  return "https://cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@1/editions/" + encodeURIComponent(edition) + "/" + encodeURIComponent(number) + ".min.json"
}

// Small, deliberately reviewed rotation seed. The remote API supplies text,
// book reference and grades; Bukhari/Muslim records are in the default pool.
var HADITHS = [
  { collection: "bukhari", number: 1 }, { collection: "bukhari", number: 8 },
  { collection: "bukhari", number: 13 }, { collection: "bukhari", number: 20 },
  { collection: "bukhari", number: 52 }, { collection: "bukhari", number: 56 },
  { collection: "muslim", number: 1 }, { collection: "muslim", number: 8 },
  { collection: "muslim", number: 16 }, { collection: "muslim", number: 38 },
  { collection: "muslim", number: 47 }, { collection: "muslim", number: 55 },
  { collection: "abudawud", number: 1 }, { collection: "tirmidhi", number: 1 }
]

function hadithPool(collection, includeWeak) {
  var wanted = choice(collection, ["any", "bukhari", "muslim", "abudawud", "tirmidhi"], "any")
  return HADITHS.filter(function(item) {
    if (wanted !== "any" && item.collection !== wanted) return false
    // The default "any" pool is deliberately the two Sahih collections.
    // For an explicitly selected collection, final eligibility comes from
    // the record's source-supplied grade in isAllowedGrade().
    return wanted !== "any" || includeWeak || item.collection === "bukhari" || item.collection === "muslim"
  })
}

function firstRecord(value) {
  if (Array.isArray(value)) return value[0] || null
  if (value && Array.isArray(value.hadiths)) return value.hadiths[0] || null
  if (value && value.data) return firstRecord(value.data)
  return value && typeof value === "object" ? value : null
}

function gradeFrom(record, collection) {
  var grades = record && Array.isArray(record.grades) ? record.grades : []
  var labels = grades.map(function(g) { return String((g && (g.grade || g.name)) || "").trim() }).filter(Boolean)
  // The two canonical Sahih collections are inherently graded; retain that
  // provenance if an individual API record has no duplicated grade field.
  if (labels.length === 0 && (collection === "bukhari" || collection === "muslim")) return "Sahih"
  return labels.join("; ")
}

function isAllowedGrade(grade, includeWeak) {
  var text = String(grade || "").toLowerCase()
  if (text === "") return false
  if (includeWeak) return true
  return text.indexOf("sahih") !== -1 || text.indexOf("hasan") !== -1
}

function collectionName(collection) {
  var names = {
    bukhari: "Sahih al-Bukhari",
    muslim: "Sahih Muslim",
    abudawud: "Sunan Abi Dawud",
    tirmidhi: "Jami` at-Tirmidhi"
  }
  return names[collection] || String(collection || "")
}

function parseQuran(raw, reference, translation) {
  try {
    var value = JSON.parse(String(raw || ""))
    var rows = value && value.data
    if (!Array.isArray(rows) || rows.length < 2) return null
    return {
      reference: referenceLabel(reference), arabic: cleanVerseText(rows[0].text),
      text: cleanVerseText(rows[1].text),
      edition: String((rows[1].edition && rows[1].edition.englishName) || translation),
      audio: String(rows[0].audio || "")
    }
  } catch (e) { return null }
}

function parseHadith(englishRaw, arabicRaw, candidate) {
  try {
    var english = firstRecord(JSON.parse(String(englishRaw || "")))
    var arabic = firstRecord(JSON.parse(String(arabicRaw || "")))
    if (!english || !arabic) return null
    var ref = english.reference || arabic.reference || {}
    var grade = gradeFrom(english, candidate.collection)
    return {
      text: cleanVerseText(english.text), arabic: cleanVerseText(arabic.text),
      collection: collectionName(candidate.collection),
      book: "Book " + String(ref.book === undefined ? "—" : ref.book),
      number: String(english.hadithnumber || candidate.number), grade: grade
    }
  } catch (e) { return null }
}

if (typeof module !== "undefined") {
  module.exports = {
    referenceForDate: referenceForDate,
    referenceLabel: referenceLabel,
    parseReference: parseReference,
    isoDate: isoDate,
    apiUrl: apiUrl,
    cleanVerseText: cleanVerseText,
    choice: choice,
    nextPosition: nextPosition,
    isOlderThanDays: isOlderThanDays,
    quranUrl: quranUrl,
    hadithUrl: hadithUrl,
    hadithPool: hadithPool,
    isAllowedGrade: isAllowedGrade,
    collectionName: collectionName,
    parseQuran: parseQuran,
    parseHadith: parseHadith,
    SURAH_NAMES: SURAH_NAMES,
    AYAHS: AYAHS,
    HADITHS: HADITHS
  }
}
