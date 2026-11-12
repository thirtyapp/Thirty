# ADR-025 — Localization architecture (six launch languages)

**Status:** **Accepted** (founder decision D-L-1c, 2026-11-12), within the scope set out in "Acceptance scope" at the end. Sub-decisions D-L-6, D-L-7, D-L-8 and D-L-9 stay **pending**. Implementation: the L-INF slice only (status in the delivery tracker).

- **Product authority:** [PRODUCT_V2_CONTRACT.md](../PRODUCT_V2_CONTRACT.md), Amendment 3 (2026-11-12).
- **Related:** [ADR-026](ADR-026-language-safe-persistence.md) (language-safe persistence; Part A approved as principles, Part B on HOLD). ADR-027 (multilingual guidance audio) is **not drafted and not accepted**; §7 below only constrains it.
- **Decision record:** the G-02 decision package `THIRTY_G02_SIX_LANGUAGE_DECISION_GATE_2026-11-12/` (rev 2, outside the tree).
- **Baseline:** `b62984bc47c476647d3eb9c5d72434ab759fd64b`. Line references are to that tree.

## Context

THIRTY has **no localization infrastructure** at `b62984bc`:
- no `flutter_localizations`, `intl`, `l10n.yaml`, ARB files or `supportedLocales`;
- `MaterialApp.router` is at `lib/core/app/thirty_app.dart:146`.

**Hard-coded text:**
- The heuristic inventory (`hardcoded_inventory.py`, re-run on `b62984bc`) finds **1,347 user-facing literal candidates in 86 files**: ui 1,107, interpolated 191, accessibility 49.
- Month and weekday names are hand-written in four files.
- Plurals are hand-built (e.g. `insight_copy.dart:159`).
- The Android reminder channel strings are hard-coded in Kotlin.

**Verified toolchain:**
- Flutter **3.44.8** stable, Dart **3.12.2**; `pubspec.lock` requires `dart >=3.12.2 <4.0.0`, `flutter >=3.44.0`.
- The SDK's `flutter_localizations` pins **`intl: 0.20.2`**.
- gen-l10n in this SDK:
  - has **removed** `synthetic-package`;
  - **falls back to the English template for a missing message, exits 0** and only lists it in `untranslated-messages-file` (probe in a scratch project, 2026-11-12).

## Decision

### 1. Dependencies and generation (exact)

`pubspec.yaml` additions, and nothing else:

```yaml
dependencies:
  flutter_localizations:
    sdk: flutter
  intl: ^0.20.2

flutter:
  generate: true
```

- **Resolution check:** a dry run on a copy of THIRTY's `pubspec.yaml` and `pubspec.lock` gives `+ flutter_localizations 0.0.0 from sdk flutter`, `+ intl 0.20.2`, **"Would change 2 dependencies"**, with every other locked version unchanged.
- **Why `^0.20.2`** rather than `any`: if a future Flutter pins a different `intl` minor, resolution fails visibly and forces a reviewed upgrade. `intl` is never upgraded independently of the SDK pin.
- **Excluded:** no third-party localization package, no AppCompat, no TTS.

**`l10n.yaml` (exact):**

```yaml
arb-dir: lib/l10n/arb
template-arb-file: app_en.arb
output-dir: lib/l10n/gen
output-localization-file: app_localizations.dart
nullable-getter: false
required-resource-attributes: true
untranslated-messages-file: build/l10n_untranslated.json
```

- These options were verified to generate in this SDK (scratch probe).
- `synthetic-package` is **not** set: it is removed, and setting it to `true` is a tool error.
- **Generated code** (`lib/l10n/gen/`) is committed, so `flutter analyze` and `flutter test` run on a clean checkout. G-GEN (§6) requires a regenerated copy to be identical.
- **Import:** `package:thirty/l10n/gen/app_localizations.dart`.

### 2. Resources and keys

- **One ARB per supported language:** `app_en.arb` (template, canonical), `app_fr.arb`, `app_nl.arb`, `app_es.arb`, `app_de.arb`, `app_it.arb`.
  - `app_es.arb` **holds es-ES content** and is declared so in its `@@x-variant: "es-ES"` metadata and in the review sidecar.
  - A language-only file avoids gen-l10n's requirement for a fallback file next to any `es_ES` file.
- **Key metadata:** every key has `@key.description` (enforced by `required-resource-attributes`), with screen, purpose, length limits, "spoken" and "safety-sensitive" flags where relevant.
- **Keys are stable and id-based** (e.g. `element_getItOut_instruction`). They are never derived from English text.
  - A change of meaning or of spoken text creates a **new revision key** (`…_r2`). A released revision is never edited.
- **Messages:**
  - whole sentences only, never assembled from fragments;
  - ICU `{placeholders}` for values;
  - ICU `plural` for every count;
  - ICU `select` only over ids (need, kind), **never over user gender**;
  - lists ("a, b and c") as explicit 1/2/3+ messages.
- **Review status** lives per key and locale in `l10n/review/<locale>.json` (`draft` → `reviewed` → `release`, with reviewer, date and scope), outside the ARB.
- **Source link:** each locale file records `@@x-source-version`, the hash of `app_en.arb`.

### 3. Supported locales, resolution and fallback

1. **Release-locale set.** `supportedLocales` is the build's release set, given at build time (`--dart-define=THIRTY_RELEASE_LOCALES=…`):
   - **T2/T3:** `en,fr,nl,es,de,it`;
   - **T1:** a scoped subset (e.g. `en,fr`);
   - **T0:** any.

   A locale outside the set is **not selectable and not resolvable**. English is always in the set and listed first.
2. **Resolution:**
   1. a valid in-app choice (§4);
   2. otherwise the device's ordered locale list, where the first supported **language** wins (Flutter's default list resolution; regional variants such as fr-BE, de-CH or es-MX resolve to their language);
   3. otherwise English.
3. **The two fallbacks are distinct:**

   | Situation | Behaviour |
   |---|---|
   | **Unsupported device language** (e.g. pt-BR, pl, ja) | Resolves to **English**. Correct and permanent |
   | **Missing, untranslated, placeholder-mismatched or not-`release` message in a supported release locale** | **CI and release-build failure** (G-KEYS, §6). gen-l10n's silent template fallback is never relied on for a release |
   | Same, in a T0 developer run | Reported (`build/l10n_untranslated.json`, G-KEYS report mode); the build is never distributed |

4. **Spanish:** every `es-*` device resolves to the single `es` resource (es-ES content). Founder option D-L-6: map non-Spain Spanish to English instead.
5. **Material, Cupertino and Widgets:** `GlobalMaterialLocalizations.delegate`, `GlobalCupertinoLocalizations.delegate` and `GlobalWidgetsLocalizations.delegate`. The SDK ARBs exist for all six languages. These delegates also initialise `intl` date symbols.

### 4. Language selection

- **Location:** You → Preferences → **Language**.
- **Options:** "System default" plus English, Français, Nederlands, Español (España), Deutsch, Italiano. Endonyms are never translated. Only release-set locales are listed.
- **Free, never gated.** Never a required onboarding step (it may appear on Welcome as an optional control; ADR-026 and D-ON-3 cover detection).
- **Storage:** `app_locale_v1` (String language code).
  - A choice is a **confirmed write**, applied only once the store confirms it. A refused write is shown with the existing "This change couldn't be saved." pattern.
  - "System default" removes the key (a confirmed removal).
  - An unsupported or damaged stored value is **ignored for resolution and kept as stored** until the user makes a new explicit choice.
- **Not exported** (like `theme_mode_v1`).
- **Language is never existence evidence** (D-ON-3).
- **Switching is presentation-only.** The only side effects:
  - the reminder is re-armed with new-language text (the title and body are stored natively at scheduling time, `DailyReminder.kt:47–48`);
  - optionally, on API 33+, the choice is mirrored to Android `LocaleManager` with `android:localeConfig` (D-L-9; the framework API, no AppCompat; `MainActivity` is a `FlutterActivity`).
- A **running Circle keeps its content language** until Close (§7.4).

### 5. Dates, times, numbers

- `DateFormat` and `NumberFormat` in the resolved locale replace every hand-written month and weekday array:
  - `circle_journal_entry_card.dart:174, 184`;
  - `insight_copy.dart:186`;
  - `circle_history_calendar.dart`;
  - `plan_copy.dart:259`.
- **English stays byte-identical:** explicit patterns, not `en_US` defaults ("Saturday 5 September 2026", "5 September 2026", "12 Oct").
- **Time:** 24-hour `HH:mm` in all six languages (D-L-7).
- **Other locales:** natively reviewed patterns.
- Domain code formats with an explicit locale; there is no global `Intl.defaultLocale` mutation.

### 6. Guards (all mandatory before the English copy freeze; G-KEYS mandatory for any T1/T2/T3 build)

| Guard | Scope | Fails when |
|---|---|---|
| **G-HC** hard-coded copy | `lib/**/*.dart`, excluding `lib/core/qa`, `lib/core/dev_preview`, `lib/core/showcase` (debug-only; to be re-confirmed), and the Android Kotlin/XML user-visible sites (notification channel names and descriptions, notification text, toasts) | A user-facing literal is not on the allowlist. The allowlist records file, literal and reason; every entry must still match; it only shrinks |
| **G-A11Y** accessibility copy (part of G-HC, reported separately) | `semanticsLabel`, `Semantics(label/hint/value/tooltip)`, `Tooltip`/`tooltip:`, `SemanticsService.announce`, live regions, `MergeSemantics` replacements, custom `onTapHint`/`onLongPressHint` | Any such literal is not from `AppLocalizations` or the allowlist |
| **G-KEYS** completeness | All ARBs of the release set | Missing or extra key; placeholder set differs from English; ICU fails to parse; plural categories wrong for the language; `build/l10n_untranslated.json` is not `{}`; review status not `release`; `@key.description` missing |
| **G-SRC** source drift | Each locale's `@@x-source-version` | English changed after review → the dependent keys are stale → failure for release locales |
| **G-ARB-CONTENT** forbidden concepts | **ARB content of all locales**, plus remaining Dart literals | The B8 forbidden-concept patterns (retired product, false completion, streak or guilt, health claims) match in `app_en.arb`, or the per-language lists match in fr/nl/es/de/it. *Required because today's B8 guard scans `.dart` only (`test/features/b8/support/live_copy.dart:117`) and would silently weaken once copy moves to ARB.* |
| **G-GEN** | `lib/l10n/gen/` | The regenerated output differs from the committed output |
| **G-DATE** | `lib/` | A hand-written month or weekday name array remains (after extraction) |
| **G-AUDIO-EN** | the guidance manifest | Any of the 180 English asset paths or script fingerprints differs from the frozen list (§7) |

**Modes:**
- G-HC and G-A11Y run from L-INF as a **non-growing baseline**: every existing literal is listed with a documented reason, any addition fails, and the baseline only shrinks. They **fail per file** as each extraction batch lands.
- All guards are global **fail** before the English copy freeze.

### 7. Language-aware content and audio interface (binding constraints on ADR-026 and ADR-027)

1. **Explicit content locale.** Element names and instructions, spoken scripts, the guidance manifest and voice completeness are functions of an explicit `contentLocale`, resolved without `BuildContext` (e.g. `lookupAppLocalizations(Locale)`).
   - **Today they derive from the element's current strings:** `partClip` (`spoken_cues.dart:176`), `spokenCueFor` (`:184`), `spokenPreviewFor` (`:196`), `completeGuidanceVoices` (`guidance_voice.dart:143`, run at start-up from `main.dart:66`).
   - A naive extraction would make every English voice incomplete under a non-English UI.
2. **Frozen English identity:**
   - the English manifest is generated from the English source;
   - it must yield the **identical 180 asset paths and FNV-1a script fingerprints** (`spoken_cues.dart:116`) as at `b62984bc`;
   - English rendition ids (`voice_locke_v1` …) never change;
   - G-AUDIO-EN captures the list before any extraction.
3. **Per-locale completeness and offer.**
   - A voice is complete per **(persona, locale)**.
   - Spoken guidance is offered only when Premium is active **and** the current content locale has a complete, founder-approved rendition.
   - **No clip is ever taken from another locale.**
4. **One language per Circle.**
   - At Start, the Circle fixes its content locale:
     - a composed Circle: the UI locale at Start;
     - a kept Circle: its snapshot's content locale (ADR-026).
   - Until Close, the Circle's content surface (heading, parts, leads, ending, notes), every clip and the foreground notification text use it.
   - The pinned locale is stored with the in-flight session, so it survives a process kill.
   - In-app, Android per-app and system language changes are handled identically.
5. **The saved-wording audio check is mandatory and stays a check** (ADR-026 §A-5).

### 8. Out of scope for this ADR

- record metadata and legacy display (ADR-026);
- voice counts, personas, delivery packaging and production (ADR-027, D-V-1…5, E-1);
- glossary decisions (D-L-3) and reviewers (D-L-4);
- analytics locale dimensions (MEA-1);
- store listing (STO-1).

## Consequences

- **Each extraction batch:**
  - touches live copy, so it needs the B8/D2 review-pack regeneration authorized (as in L-1 D-1);
  - keeps English output byte-identical.
- `circle_elements.dart` and `spoken_cues.dart` are extracted **only after** the §7 content-locale API exists.
- **Generated code** adds files under `lib/l10n/gen/`. Cost: none at runtime; a small APK increase.
- **T1 pilots** can ship a subset release set without any half-translated language being selectable.

## Acceptance (summary)

AT-LOC-1…8, AT-KEY-1…3, AT-DT-1…3, AT-ICU-1…3, AT-RST-1, AT-ENT-1/2, AT-A11Y-1/2, AT-TXT-1/2 and AT-FP-1 in the G-02 decision package (file 04). The L-INF slice tests S-1…S-14 are in file 09.

## Acceptance scope (2026-11-12)

**Accepted (D-L-1c):** §1–§7 as the localization architecture.

**Implemented by the L-INF slice:**
- §1;
- §2 for the English template catalogue only;
- §3 with the release-locale set fixed to English;
- §6: G-KEYS, G-HC, G-A11Y, G-ARB-CONTENT, G-GEN and G-AUDIO-EN.

**Deferred to later slices:**
- G-SRC and per-key review status, which apply once a non-English catalogue exists;
- G-DATE, which applies with date extraction.

**Not yet decided** (each needs its own founder decision):
- §3.4 Spanish outside Spain (D-L-6);
- §5 date style (D-L-7);
- §7.4 the running-Circle language (D-L-8);
- §4 Android `LocaleManager` mirroring (D-L-9).

**English-only runtime.** Until ADR-026 Part B's persisted language identity (D-L-5c) is decided and implemented, the effective app language is **English** for every device locale (ADR-026 A-3b, gate G-5C). There is no non-English catalogue, no release-locale define and no language control. A device set to any other language starts normally in English; nothing is refused or blocked.

**Not accepted here:** ADR-027, ADR-028, any translation and any audio production.
