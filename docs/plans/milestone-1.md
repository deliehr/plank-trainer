# Implementierungsplan Meilenstein 1 – Plank-Trainer (iOS)

Stand: 2026-11-21 · Status: freigegeben (Entscheidungen in Abschnitt 11) · Verfasser: Opus (Effort High)

Grundlage (verbindlich, in dieser Reihenfolge bei Widerspruch: spätere Nutzerentscheidung > Spezifikation > dieser Plan):
- `CLAUDE.md`
- `docs/spec/plank-trainer-spec.md` (M1; Abschnitt 9 gehört **nicht** zu M1)
- `docs/spec/announcement-phrases.md` (alle Ansagetexte)
- `docs/spec/claude-design-brief.md`
- `docs/swift/*` und `docs/swift/database/*` (nur Muster)

HIG-Grundlage: Skill `apple-design`, gelesen `references/hig/`: accessibility, layout, typography, color, designing-for-ios, tab-bars, pickers, lists-and-tables, charting-data, progress-indicators, playing-haptics, playing-audio, modality, feedback, dark-mode. Zitate stehen in den Akzeptanzkriterien der UI-Aufgaben im Format `datei.md › Abschnitt`.

Technische Vorab-Verifikation (Spike vom 2026-11-21 mit Xcode 27.2, XcodeGen 2.46, Simulator „iPhone 17“, iOS 27.2) – alles grün:
- XcodeGen `type: syncedFolder` für App- und Test-Target erzeugt `PBXFileSystemSynchronizedRootGroup`; neue Dateien brauchen kein `xcodegen generate`.
- `@Model final class` in `extension DatabaseSchemaV1` mit `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, Swift 6, strikter Concurrency: kompiliert ohne Warnung; In-Memory-Container, `FetchDescriptor` mit `SortDescriptor` auf optionaler Eigenschaft und `#Predicate { $0.id == optionalUUID }` funktionieren.
- Mehrere String Catalogs (`Announcements.xcstrings`, `Coach.xcstrings`, `Training.xcstrings` …) werden zu getrennten Tabellen `de.lproj/<Name>.strings|.stringsdict` kompiliert; Plural-Varianten funktionieren; `LocalizedStringResource(…, table:)` mit gesetztem `locale` liefert gezielt Deutsch oder Englisch. Ein leerer Catalog baut ohne Fehler. `xcodebuild` verändert die `.xcstrings`-Quelldateien nicht.
- `AVSpeechSynthesizerDelegate` über ein Proxy-Objekt mit `nonisolated`-Methoden und `AsyncStream`, `AVAudioSession.setCategory(.playback, mode: .voicePrompt, options: [.duckOthers, .interruptSpokenAudioAndMixWithOthers])`, `NotificationCenter.default.notifications(named:)` und `UIApplication.shared.isIdleTimerDisabled` kompilieren unter Swift 6 ohne Warnung.
- `AVSpeechSynthesisVoice(language: "de")` liefert `de-DE`.
- Swift Testing mit `@Test(arguments:)` und `-only-testing:PlanktrainerTests/<Suite>` funktioniert im gehosteten Test-Target.
- Eine `InfoPlist.xcstrings` in einem **nicht** synchronisierten Ordner sorgt dafür, dass XcodeGen `de` in `knownRegions` einträgt (bei reinen `syncedFolder`-Quellen fehlt `de` sonst).

Der Spike ist beendet und nicht Teil des Repos. Alles, was er nicht abgedeckt hat, ist im Plan als „vom Tech Lead in Welle 0 zu verifizieren“ markiert (Risiken R9, R13).

---

## 1. Überblick

### 1.1 Wellen

| Welle | Aufgaben | parallel | Inhalt | vom Design unabhängig |
|---|---|---|---|---|
| **W0** | 2 (W0-T1 → W0-T2) | nein, nacheinander | Projektgerüst, Persistenz, Lokalisierungs-Infrastruktur, alle gemeinsamen Verträge, Router, RootView, Theme-Tokens (Platzhalter), Screen-Platzhalter | ja |
| **W1** | 8 (W1-T1 … W1-T8) | ja | Ansagetexte, Coach-Sätze, Ansageplaner, Session-Engine, Sprachausgabe/Audio, Persistenz-Store, Formatierung, Fortschrittsring | ja |
| **W2** | 6 (W2-T1 … W2-T6) | ja | alle Screens (Training, Verlauf, Detail, Session-Vollbild zweigeteilt, Einstellungen/Info) | ja (nur Platzhalter-Tokens) |
| **W3** | 1 (W3-T1) | – | Integrationstests mit echten Texten, Platzhalter-Prüfung | ja |
| **Abschluss** | Tech Lead + Nutzer | – | komplette Testausführung, Simulator-Sichtprüfung, Geräte-Checkliste (Spec 5) | ja |
| **D** (später) | D1: 1, D2: 5 | D2 parallel | Claude-Design-Ergebnisse einarbeiten | **nein**, braucht Design-Ergebnisse |

Abhängigkeiten: W0 → W1 → W2 → W3 → Abschluss. Welle D startet, sobald W2 abgenommen ist **und** die Claude-Design-Ergebnisse vorliegen. Liegen die Design-Ergebnisse schon vor Beginn von W2 vor, darf D1 (Tokens) vor W2 laufen; D2 schrumpft dann auf Feinkorrekturen.

### 1.2 Parallelität im Detail

```
W0-T1 ─► W0-T2 ─┬─► W1-T1 Texte ──────────┐
                ├─► W1-T2 Coach-Sätze ─────┤
                ├─► W1-T3 Planer (Fakes) ──┤
                ├─► W1-T4 Engine (Fakes) ──┤
                ├─► W1-T5 Audio/Sprache ───┼─► W2-T1 … W2-T6 ─► W3-T1 ─► Abschluss ─► (D1 ─► D2-T1 … D2-T5)
                ├─► W1-T6 Store/Summary ───┤
                ├─► W1-T7 Formatierung ────┤
                └─► W1-T8 Ring ────────────┘
```

Warum das parallel kompiliert: Alle Typen, gegen die eine Aufgabe programmiert, entstehen in W0 (Verträge, Abschnitt 4) oder in einer früheren Welle. Innerhalb einer Welle programmiert keine Aufgabe gegen eine andere Aufgabe derselben Welle. Planer und Engine testen deshalb mit Fakes gegen Protokolle; die echte Verdrahtung passiert in W2 (Engine-Erzeugung im Session-Screen) und wird in W3 mit echten Texten integriert getestet. Screens, die sich gegenseitig referenzieren (RootView → Screens, Session-Screen → Anzeige-Views), existieren ab W0 als Platzhalter mit endgültiger Signatur.

### 1.3 Modell- und Agentenzuordnung

Alle Umsetzungsaufgaben: Agent-Typ `swift-coding-agent`, Modell Sonnet 5.5, Effort Medium. Tech Lead: Opus, Effort High. Besonders gründlich abzunehmen (Kernlogik): W1-T3 (Planer) und W1-T4 (Engine).

---

## 2. Arbeitsweise

### 2.1 Entscheidung: isolierte Arbeitskopien statt gemeinsamem Working Tree oder Git-Worktrees

**Entscheidung:** Jede parallele Aufgabe arbeitet in einer **eigenen Kopie des Repositorys ohne `.git`** (per `rsync`) mit eigenem DerivedData und eigenem Simulator-Klon. Der Tech Lead übernimmt nach der Prüfung **nur die der Aufgabe gehörenden Dateien** in den Haupt-Working-Tree.

Begründung:
1. **Gemeinsamer Working Tree scheidet aus:** Ein Swift-Target kompiliert nur als Ganzes. Solange ein Agent eine halbfertige Datei hat, bricht der Build aller anderen Agenten. Tests wären nicht aussagekräftig.
2. **Git-Worktrees** würden das lösen, sind aber Branch-Operationen. Laut `CLAUDE.md › Git` dürfen Subagenten keine Git-Operationen ausführen, und verändernde Operationen brauchen die Absprache mit dem Nutzer pro Vorgang. Kopien ohne `.git` erreichen dieselbe Isolation **ohne jede Git-Operation**.
3. **Exklusive Dateizuständigkeit** macht das Zurückkopieren konfliktfrei; Änderungen außerhalb der Zuständigkeit gehen beim Zurückkopieren automatisch verloren und fallen im Vergleich mit der Basis-Kopie auf.
4. **Simulator:** Mehrere gleichzeitige `xcodebuild test` auf demselben Simulator installieren dieselbe Bundle-ID und stören sich. Deshalb bekommt jede Aufgabe einen Klon (`PT-<Task-ID>`).
5. Will der Nutzer lieber Git-Worktrees, ist das eine Alternative; dann holt der Tech Lead vor der Welle die Zustimmung für das Anlegen der Worktrees/Branches, das Cherry-Picken und das Aufräumen ein.

W0 läuft nacheinander direkt im Haupt-Working-Tree (keine Kopie nötig). W3-T1 ebenfalls.

### 2.2 Ablauf pro Welle (Tech Lead)

1. **Vorbedingung:** Die vorige Welle ist abgenommen. Empfohlen: auch committet (siehe 2.4), damit es einen sauberen Rücksetzpunkt gibt.
2. **Arbeitskopien und Simulatoren vorbereiten** (keine Git-Operation):

```sh
ROOT=/Users/dominik/Projects/plank-trainer
WS=/Users/dominik/Projects/plank-trainer-workspaces
xcrun simctl shutdown "iPhone 17" 2>/dev/null
mkdir -p "$WS"
rsync -a --delete --exclude '.git/' --exclude 'DerivedData/' "$ROOT/" "$WS/_base/"
for TASK in W1-T1 W1-T2 W1-T3 W1-T4; do            # Task-IDs der Charge
  rsync -a --delete "$WS/_base/" "$WS/$TASK/"
  xcrun simctl clone "iPhone 17" "PT-$TASK"
done
```

   Falls Agenten außerhalb von `/Users/dominik/Projects/plank-trainer` nicht schreiben dürfen: stattdessen `$ROOT/.workspaces` verwenden, beim `rsync` zusätzlich `--exclude '.workspaces/'` angeben und `.workspaces/` in `.gitignore` aufnehmen (Absprache mit dem Nutzer, da Repo-Änderung).
3. **Agenten starten:** pro Aufgabe ein Agent (`subagent_type: swift-coding-agent`, `model: sonnet`, Effort Medium). Prompt = gemeinsamer Vorspann (2.3) mit eingesetzter Task-ID + vollständiger Aufgabenabschnitt aus Abschnitt 6. **Höchstens 4 Agenten gleichzeitig** (CPU/RAM für Builds und Simulatoren); W1 läuft deshalb in zwei Chargen: A = T3, T4, T1, T2; B = T5, T6, T7, T8. W2: A = T4, T5, T1, T2; B = T3, T6.
4. **Pro gemeldeter Aufgabe prüfen:**

```sh
diff -rq --exclude 'DerivedData' "$WS/_base" "$WS/W1-T3"   # nur zugewiesene Pfade dürfen auftauchen
diff -ruN --exclude 'DerivedData' "$WS/_base/ios/Planktrainer" "$WS/W1-T3/ios/Planktrainer" | less
```

   Abweichungen außerhalb der Zuständigkeit → Rückmeldung an den Agenten (SendMessage, Agent arbeitet in seiner Kopie weiter).
5. **Integrieren:** Für jede Aufgabe die zugewiesenen Pfade zurückkopieren:

```sh
integrate() { TASK=$1; shift; for P in "$@"; do mkdir -p "$ROOT/$(dirname "$P")"; rsync -a "$WS/$TASK/$P" "$ROOT/$(dirname "$P")/"; done; }
integrate W1-T3 ios/Planktrainer/Core/Announcements/AnnouncementPlanner.swift ios/PlanktrainerTests/Announcements/AnnouncementPlannerTests.swift ios/PlanktrainerTests/Announcements/PlannerFakes.swift
```

6. **Abnahme im Haupt-Working-Tree** nach Checkliste (Abschnitt 7). Fehler → Rückmeldung an den zuständigen Agenten, erneut integrieren.
7. **Commits nach Absprache** (2.4).
8. **Aufräumen:** `xcrun simctl delete "PT-<Task-ID>"` für alle Klone, `rm -rf "$WS"`.

### 2.3 Gemeinsamer Vorspann für jeden Agenten-Prompt

Der Tech Lead setzt `{TASK_ID}` und `{WORKDIR}` ein (`{WORKDIR}` = Arbeitskopie bzw. bei W0/W3 `/Users/dominik/Projects/plank-trainer`) und hängt den Aufgabenabschnitt an.

```text
Du setzt Aufgabe {TASK_ID} aus dem Implementierungsplan docs/plans/milestone-1.md für die iOS-App „Plank-Trainer“ um.
Arbeitsverzeichnis: {WORKDIR} (alle Pfade unten sind relativ dazu). Arbeite ausschließlich dort.

Pflichtlektüre vor dem Start: CLAUDE.md, im Plan die Abschnitte 3 (Konventionen), 4 (Verträge) und deine Aufgabe; dazu die in deiner Aufgabe genannten Abschnitte der Spezifikation docs/spec/plank-trainer-spec.md.

Harte Regeln:
1. Du änderst oder erzeugst NUR die Dateien, die in deiner Aufgabe unter „Exklusive Dateien“ stehen. Alle anderen Dateien sind tabu, auch wenn du dort einen Fehler siehst – melde ihn stattdessen.
2. Keine Git-Operationen (auch kein git status/diff im Arbeitsverzeichnis). Kein xcodegen, keine Änderung an ios/project.yml oder ios/Planktrainer.xcodeproj.
3. Verträge aus Abschnitt 4 des Plans sind wörtlich einzuhalten (Namen, Signaturen, Zugriffsebenen). Fehlt dir etwas im Vertrag, triff keine eigene Erweiterung an fremden Dateien, sondern melde es.
4. Code-Regeln aus CLAUDE.md: Swift 6, Default-Isolation MainActor, kein Force-Unwrap (!, try!, as!), kein try?, kein fatalError, kein Combine/ObservableObject/@Published/UIKit-Views. Bezeichner, Kommentare, Test-Namen, Log-Texte auf Englisch; so wenige Kommentare wie möglich. Keine Drittanbieter-Pakete.
5. Nutzer-sichtbare Texte nur über die String-Tabellen deiner Aufgabe (Abschnitt 3.2). Keine Text-Literale in der UI.
6. Styling nur über die Theme-Tokens aus ios/Planktrainer/DesignSystem (Abschnitt 3.3). Keine festen Farben, Schriftgrößen oder Abstände in Feature-Code.
7. Build und Tests mit genau diesen Befehlen (Simulator-Klon und DerivedData gehören dir):
   xcodebuild -project {WORKDIR}/ios/Planktrainer.xcodeproj -scheme Planktrainer -destination 'platform=iOS Simulator,name=PT-{TASK_ID}' -derivedDataPath {WORKDIR}/ios/DerivedData build
   xcodebuild -project {WORKDIR}/ios/Planktrainer.xcodeproj -scheme Planktrainer -destination 'platform=iOS Simulator,name=PT-{TASK_ID}' -derivedDataPath {WORKDIR}/ios/DerivedData test
   (Bei W0/W3 im Haupt-Working-Tree: name=iPhone 17 und -derivedDataPath ios/DerivedData.)
   Während der Arbeit darfst du einzelne Suites mit -only-testing:PlanktrainerTests/<SuiteName> laufen lassen; am Ende muss der vollständige Testlauf grün sein.
8. Keine Compiler-Warnungen in deinen Dateien.

Abschlussbericht (auf Deutsch, knapp):
- geänderte/erzeugte Dateien (vollständige Liste)
- Ergebnis des vollständigen Build- und Testlaufs (Anzahl Tests, alle grün?)
- erfüllte Akzeptanzkriterien (Liste mit Häkchen) und nicht erfüllte mit Grund
- getroffene Annahmen und offene Fragen
- Vorschlag Commit-Message (aus der Aufgabe übernehmen)
```

### 2.4 Commits

- Subagenten committen nie. Der Tech Lead committet **nach der Abnahme einer Welle**. Für M1 hat der Nutzer das dauerhaft erlaubt (Abschnitt 11): keine erneute Rückfrage pro Welle, die Commit-Liste „Aufgabe → Dateien → Commit-Message“ steht im Abnahmebericht.
- Ein Commit pro Aufgabe, in der Reihenfolge der Task-IDs: `git add <exklusive Dateien der Aufgabe>` und `git commit -m "<Message>"` mit der Attribution aus den Systemvorgaben. Die Commit-Messages in den Aufgaben sind **Vorschläge** für den Tech Lead.
- Kein `push`, kein `merge`, kein `rebase`, keine Branches ohne ausdrückliche Zustimmung.
- W0-T1 ändert `ios/project.yml`: `project.yml` und `ios/Planktrainer.xcodeproj` gehören in denselben Commit (`CLAUDE.md › Befehle`).

---

## 3. Verbindliche Konventionen

### 3.1 Projektstruktur und Dateizuständigkeit (Endstand M1)

```
ios/
  project.yml                                    W0-T1
  Planktrainer.xcodeproj/                        W0-T1 (generiert, eingecheckt)
  SupportingFiles/InfoPlist.xcstrings            W0-T1 (bewusst NICHT synchronisiert → knownRegions de/en)
  Planktrainer/                                  syncedFolder
    App/
      PlanktrainerApp.swift                      W0-T1 → W0-T2 → W1-T5 (Announcer-Tausch)
      AppEnvironment.swift                       W0-T2
      AppRouter.swift                            W0-T2
      RootView.swift                             W0-T2
      ContainerErrorView.swift                   W0-T1
      PreviewSupport.swift                       W0-T2 (#if DEBUG)
    Core/
      Localization/LocalizationTable.swift       W0-T1
      Session/SessionConfiguration.swift         W0-T1
      Session/SessionPhase.swift                 W0-T2
      Session/SessionResult.swift                W0-T2
      Session/SessionHistoryContext.swift        W0-T2
      Session/SessionClock.swift                 W0-T2
      Session/SessionHaptic.swift                W0-T2
      Session/SessionTimerDisplay.swift          W0-T2
      Session/SessionEngine.swift                W1-T4
      Announcements/CoachStyle.swift             W0-T2
      Announcements/AnnouncementModels.swift     W0-T2
      Announcements/AnnouncementProtocols.swift  W0-T2
      Announcements/Announcing.swift             W0-T2
      Announcements/SpokenDurationFormatter.swift  W1-T1
      Announcements/AnnouncementTexts.swift      W1-T1
      Announcements/SplitMix64.swift             W1-T2
      Announcements/ShuffleBag.swift             W1-T2
      Announcements/PhraseCatalog.swift          W1-T2
      Announcements/PhraseSelector.swift         W1-T2
      Announcements/AnnouncementPlanner.swift    W1-T3
      Formatting/TimeText.swift                  W1-T7
    Services/
      AudioSessionController.swift               W1-T5
      SpeechAnnouncer.swift                      W1-T5
      AudioInterruptionMonitor.swift             W1-T5
    Persistence/
      DatabaseSchemas.swift                      W0-T1
      MigrationPlans.swift                       W0-T1
      ModelContainerFactory.swift                W0-T1
      PersistenceError.swift                     W0-T1
      SessionStoreError.swift                    W0-T1
      Models/PlankSession.swift                  W0-T1
      Models/PlankSession+Values.swift           W0-T1
      SessionStore.swift                         W1-T6
      SessionHistorySummary.swift                W1-T6
    Settings/UserSettings.swift                  W0-T2
    DesignSystem/
      ThemeColor.swift                           W0-T2 → D1
      ThemeFont.swift                            W0-T2 → D1
      ThemeMetrics.swift                         W0-T2 → D1
      ProgressRing.swift                         W1-T8 → D1
    Features/
      Training/                                  Platzhalter W0-T2 → W2-T1 → D2-T1
      History/                                   Platzhalter W0-T2 → W2-T2 → D2-T2
      SessionDetail/                             Platzhalter W0-T2 → W2-T3 → D2-T3
      ActiveSession/                             Platzhalter W0-T2 → W2-T4 + W2-T5 (dateigenau getrennt) → D2-T4
      Settings/                                  Platzhalter W0-T2 → W2-T6 → D2-T5
    Resources/
      Assets.xcassets                            W0-T1 → D1 (AppIcon, AccentColor)
      Localization/<Tabelle>.xcstrings           Gerüst W0-T1 → Inhalt durch die Eigentümer-Aufgabe (3.2)
  PlanktrainerTests/                             syncedFolder; Testdateien je Aufgabe, siehe Aufgaben
```

Regel: Eine Datei gehört pro Welle genau einer Aufgabe. Zwischen Wellen darf der Eigentümer wechseln; das steht dann explizit in der Aufgabe.

### 3.2 Lokalisierung: getrennte String-Tabellen

**Entscheidung:** Statt eines einzigen `Localizable.xcstrings` (Spec 3.12) gibt es **eine String-Catalog-Datei pro Bereich**. Jede Datei hat genau eine Eigentümer-Aufgabe. Quellsprache Englisch, Übersetzungen Deutsch und Englisch.

Begründung:
- Ein gemeinsamer Catalog ist eine große JSON-Datei; parallele Aufgaben würden sich beim Zurückkopieren überschreiben.
- Xcode kompiliert jede `.xcstrings`-Datei zu einer eigenen Tabelle (`<Name>.strings` bzw. `.stringsdict` in `de.lproj`/`en.lproj`). Der Tabellenname ist der Dateiname. Das ist Standard-Foundation-Verhalten (`tableName`/`table:`), keine Eigenkonstruktion.
- Im Spike verifiziert: getrennte Tabellen, Plural-Varianten, gezielte Sprache über `LocalizedStringResource.locale`, leere Catalogs, keine Veränderung der Quelldateien durch `xcodebuild`.
- Abweichung von Spec 3.12 ist unter „Annahmen“ (A1) vermerkt.

| Tabelle (Datei `ios/Planktrainer/Resources/Localization/<Name>.xcstrings`) | `LocalizationTable` | Eigentümer |
|---|---|---|
| `App` | `.app` | W0-T1 |
| `Common` | `.common` | W0-T1 |
| `Errors` | `.errors` | W0-T1 |
| `Announcements` | `.announcements` | W1-T1 |
| `Coach` | `.coach` | W1-T2 |
| `Training` | `.training` | W2-T1 |
| `History` | `.history` | W2-T2 |
| `SessionDetail` | `.sessionDetail` | W2-T3 |
| `ActiveSession` | `.activeSession` | W2-T4 |
| `SessionDisplay` | `.sessionDisplay` | W2-T5 |
| `Settings` | `.settings` | W2-T6 |
| `ios/SupportingFiles/InfoPlist.xcstrings` (nur `CFBundleDisplayName`) | – | W0-T1 |

W0-T1 legt **alle** Dateien als leeres Gerüst an; die Eigentümer füllen sie. Andere Aufgaben dürfen Schlüssel fremder Tabellen **lesen** (z. B. `Common`, Beispielsätze aus `Coach`), aber nie die Datei ändern.

**Schlüssel:** semantisch, Präfix = Bereich, z. B. `training.startButton`, `coach.demanding.filler.03`. Schlüssel mit Argumenten entstehen durch String-Interpolation und enthalten die Formatplatzhalter (`"duration.seconds \(n)"` → Schlüssel `duration.seconds %lld`; `"history.row.result \(a) \(b)"` mit `String`-Argumenten → `history.row.result %@ %@`). Jeder Eintrag hat `"extractionState" : "manual"` und **explizite** Werte für `en` und `de`. Bei mehreren Argumenten im Wert Positionsplatzhalter verwenden (`%1$@`, `%2$@`).

**Zugriff:**
- In SwiftUI-Views: `Text("training.startButton", tableName: LocalizationTable.training.rawValue)`; mit Argumenten `Text("training.summary.record \(recordText)", tableName: LocalizationTable.training.rawValue)`. Für `Button`, `Label`, `Toggle`, `Picker`, `LabeledContent`, `Section`, `.navigationTitle`, `.accessibilityLabel` immer die Varianten mit `Text`-/Label-Closure bzw. `Text`-Parameter nutzen, damit der Tabellenname gesetzt werden kann. `Text(verbatim:)` nur für reine Zahlen/Zeiten.
- Außerhalb von Views (Fehlertexte, Ansagen, Accessibility-Werte als `String`): `L10n.string(_:table:locale:)` aus W0-T1. Für Ansagen und Coach-Sätze wird die Sprache immer explizit übergeben (`locale`), damit Tests deterministisch sind.

**Format-Vorlagen** (genau so in die `.xcstrings`-Dateien schreiben):

```json
{
  "sourceLanguage" : "en",
  "strings" : {
    "training.startButton" : {
      "extractionState" : "manual",
      "localizations" : {
        "de" : { "stringUnit" : { "state" : "translated", "value" : "Session starten" } },
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Start Session" } }
      }
    },
    "duration.seconds %lld" : {
      "extractionState" : "manual",
      "localizations" : {
        "de" : { "variations" : { "plural" : {
          "one" : { "stringUnit" : { "state" : "translated", "value" : "%lld Sekunde" } },
          "other" : { "stringUnit" : { "state" : "translated", "value" : "%lld Sekunden" } }
        } } },
        "en" : { "variations" : { "plural" : {
          "one" : { "stringUnit" : { "state" : "translated", "value" : "%lld second" } },
          "other" : { "stringUnit" : { "state" : "translated", "value" : "%lld seconds" } }
        } } }
      }
    },
    "history.row.result %@ %@" : {
      "extractionState" : "manual",
      "localizations" : {
        "de" : { "stringUnit" : { "state" : "translated", "value" : "%1$@ / %2$@" } },
        "en" : { "stringUnit" : { "state" : "translated", "value" : "%1$@ / %2$@" } }
      }
    }
  },
  "version" : "1.0"
}
```

Leeres Gerüst: `{ "sourceLanguage" : "en", "strings" : { }, "version" : "1.0" }`.

Jede Aufgabe, die eine Tabelle füllt, prüft ihre Schlüssel mit einem Test, der für `de` und `en` einen Wert ungleich dem Schlüssel liefert. Zusätzlich prüft der globale Test aus W0-T1, dass `de` und `en` in jeder Tabelle dieselben Schlüssel haben.

### 3.3 Design-Tokens (Platzhalter bis Claude Design)

- Alle Features stylen ausschließlich über die Tokens aus `ios/Planktrainer/DesignSystem/` (Vertrag 4.9). Platzhalterwerte sind Systemfarben und System-Textstile, damit Kontrast, Dark Mode, „Kontrast erhöhen“ und Dynamic Type von Anfang an stimmen (HIG `color.md › Best practices`: „When possible, use system colors, which already define variants for all these contexts.“).
- Navigation und Steuerelemente sind Systemkomponenten (`TabView`/`Tab`, `NavigationStack`, `List`/`Form`, `Picker(.wheel)`, `Toggle`, `Button`-Stile, `confirmationDialog`, `ContentUnavailableView`, Swift Charts). Liquid Glass kommt in iOS 26 automatisch über Tab Bar und Toolbars; eigene Glass-Effekte in Inhaltsflächen sind verboten.
- Keine Bild-Assets außer App-Icon; Symbole ausschließlich SF Symbols.
- Welle D tauscht die Token-Werte und passt Layouts an; die Token-**Namen** bleiben stabil.

### 3.4 Fehlerbehandlung

- Services werfen typisierte Fehler (`throws(XyzError)`), die `LocalizedError` sind; Texte stehen in `Errors.xcstrings`.
- Gefangen und angezeigt wird in der UI: Alert bei nutzerausgelösten Aktionen (Speichern, Löschen), Inline-Hinweis bei nicht-blockierenden Problemen (Audio).
- Erlaubte, dokumentierte Ausnahmen (Tech Lead prüft, dass es keine weiteren gibt):
  1. `SessionEngine` fängt `AnnouncerError` und legt ihn in der beobachtbaren Eigenschaft `announcementError` ab; die UI zeigt ihn inline (die Engine zeigt nichts an, sie reicht den Fehler als Zustand durch).
  2. `SpeechAnnouncer` fängt Fehler beim **Deaktivieren** der Audio-Session und protokolliert sie per `os.Logger` (nicht nutzerrelevant, nichts zu tun).
  3. `SessionEngine.run()` beendet die Schleife bei `CancellationError` aus `Task.sleep`.
  4. `PlanktrainerApp` fängt `PersistenceError` beim Start und zeigt `ContainerErrorView`.

### 3.5 Tests

- Swift Testing (`import Testing`, `@Suite`, `@Test`, `#expect`, `try #require`). Keine UI-Tests, kein XCTest.
- Testdateien liegen unter `ios/PlanktrainerTests/<Bereich>/`. Hilfstypen (Fakes) tragen eindeutige Namen und liegen in Dateien der jeweiligen Aufgabe.
- Tests mit `UserDefaults` nutzen je Test eine eigene Suite (`UserDefaults(suiteName: "test.\(UUID().uuidString)")` mit `try #require`), Tests mit SwiftData einen eigenen In-Memory-Container.
- Sprachabhängige Tests übergeben immer `Locale(identifier: "de")` bzw. `Locale(identifier: "en")`.

---

## 4. Verträge

Alle hier stehenden Typen, Namen und Signaturen sind verbindlich. „Implementierung“ heißt: Die Aufgabe schreibt den Rumpf; die Signatur bleibt. Wo ein vollständiger Rumpf angegeben ist, wird er so übernommen. Alle Typen sind `internal` (Standard), Test-Target nutzt `@testable import Planktrainer`. Durch Default-Isolation `MainActor` ist alles ohne Annotation MainActor-isoliert; `nonisolated` nur, wo hier angegeben.

**Regel aus W0-T1 (verifiziert):** Typen, die aus nicht isoliertem Kontext benutzt werden – vor allem aus `LocalizedError.errorDescription` oder aus Autoclosures wie dem rechten Operanden von `??` –, müssen als `nonisolated` deklariert sein. Betroffen sind bisher `L10n`, `AppLocale` und `SessionConfiguration`. Wer in späteren Aufgaben einen neuen Typ in dieser Rolle anlegt, deklariert ihn ebenfalls `nonisolated` und meldet das im Bericht. Fremde Verträge werden dafür nicht geändert, sondern gemeldet.

### 4.1 Lokalisierung (W0-T1)

`ios/Planktrainer/Core/Localization/LocalizationTable.swift` (vollständig):

```swift
import Foundation

enum LocalizationTable: String, CaseIterable, Sendable {
    case app = "App"
    case common = "Common"
    case errors = "Errors"
    case announcements = "Announcements"
    case coach = "Coach"
    case training = "Training"
    case history = "History"
    case sessionDetail = "SessionDetail"
    case activeSession = "ActiveSession"
    case sessionDisplay = "SessionDisplay"
    case settings = "Settings"
}

nonisolated enum AppLocale {
    static var current: Locale {
        Locale(identifier: Bundle.main.preferredLocalizations.first ?? "en")
    }
}

nonisolated enum L10n {
    static func string(
        _ key: String.LocalizationValue,
        table: LocalizationTable,
        locale: Locale = AppLocale.current
    ) -> String {
        var resource = LocalizedStringResource(key, table: table.rawValue)
        resource.locale = locale
        return String(localized: resource)
    }
}
```

Schlüssel, die W0-T1 in die Gerüst-Tabellen schreibt:

| Tabelle | Schlüssel | en | de |
|---|---|---|---|
| App | `tab.training` | Training | Training |
| App | `tab.history` | History | Verlauf |
| App | `tab.settings` | Settings | Einstellungen |
| App | `containerError.title` | Your Data Couldn't Be Loaded | Deine Daten konnten nicht geladen werden |
| App | `containerError.message` | Please restart the app. If the problem persists, report it on GitHub. | Bitte starte die App neu. Bleibt das Problem bestehen, melde es auf GitHub. |
| Common | `common.record` | Record | Rekord |
| Common | `common.newRecord` | New record! | Neuer Rekord! |
| Common | `common.goalReached` | Goal reached | Ziel erreicht |
| Common | `common.goalMissed` | Goal not reached | Ziel nicht erreicht |
| Common | `common.goal` | Goal | Ziel |
| Common | `common.achieved` | Achieved | Erreicht |
| Common | `common.ok` | OK | OK |
| Errors | `error.announcer.unavailable` | Announcements unavailable | Ansagen nicht verfügbar |
| Errors | `error.store.saveFailed` | The session couldn't be saved. | Die Session konnte nicht gespeichert werden. |
| Errors | `error.store.deleteFailed` | The session couldn't be deleted. | Die Session konnte nicht gelöscht werden. |
| Errors | `error.persistence.containerFailed` | The database couldn't be opened. | Die Datenbank konnte nicht geöffnet werden. |
| InfoPlist | `CFBundleDisplayName` | Plank-Trainer | Plank-Trainer |

### 4.2 Persistenz (W0-T1)

`Persistence/DatabaseSchemas.swift`:

```swift
import Foundation
import SwiftData

let currentDatabaseSchema = DatabaseSchemaV1.schema

typealias PlankSession = DatabaseSchemaV1.PlankSession

enum DatabaseSchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)
    static let models: [any PersistentModel.Type] = [DatabaseSchemaV1.PlankSession.self]
    static var schema: Schema { Schema(models, version: versionIdentifier) }
}
```

`Persistence/MigrationPlans.swift`:

```swift
import SwiftData

enum DatabaseMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [DatabaseSchemaV1.self] }
    static var stages: [MigrationStage] { [] }
}
```

`Persistence/Models/PlankSession.swift`:

```swift
import Foundation
import SwiftData

// MARK: - v1

extension DatabaseSchemaV1 {
    @Model
    final class PlankSession {
        var id: UUID?
        var startedAt: Date?
        var endedAt: Date?
        var preparationSeconds: Int?
        var plannedSeconds: Int?
        var extensionSeconds: Int?
        var achievedSeconds: Int?
        var pauseCount: Int?

        init(
            id: UUID? = UUID(),
            startedAt: Date? = nil,
            endedAt: Date? = nil,
            preparationSeconds: Int? = nil,
            plannedSeconds: Int? = nil,
            extensionSeconds: Int? = nil,
            achievedSeconds: Int? = nil,
            pauseCount: Int? = nil
        ) { /* alle Eigenschaften zuweisen */ }
    }
}
```

`Persistence/Models/PlankSession+Values.swift` – **die einzige Stelle mit Standardwerten** (Views nutzen nur diese Zugriffe):

```swift
import Foundation

extension PlankSession {
    static let missingID = UUID(uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0))

    var idValue: UUID { id ?? Self.missingID }
    var startedAtValue: Date { startedAt ?? .distantPast }
    var endedAtValue: Date { endedAt ?? startedAtValue }
    var preparationSecondsValue: Int { preparationSeconds ?? SessionConfiguration.standard.preparationSeconds }
    var plannedSecondsValue: Int { plannedSeconds ?? SessionConfiguration.standard.plannedSeconds }
    var extensionSecondsValue: Int { extensionSeconds ?? 0 }
    var achievedSecondsValue: Int { achievedSeconds ?? 0 }
    var pauseCountValue: Int { pauseCount ?? 0 }
    var isGoalReached: Bool { achievedSecondsValue >= plannedSecondsValue }
    var configuration: SessionConfiguration {
        SessionConfiguration(plannedSeconds: plannedSecondsValue, preparationSeconds: preparationSecondsValue)
    }
}
```

`Persistence/PersistenceError.swift`:

```swift
import Foundation

enum PersistenceError: LocalizedError, Equatable {
    case containerCreationFailed(reason: String)

    var errorDescription: String? {
        L10n.string("error.persistence.containerFailed", table: .errors)
    }
}
```

`Persistence/SessionStoreError.swift`:

```swift
import Foundation

enum SessionStoreError: LocalizedError, Equatable {
    case saveFailed
    case deleteFailed

    var errorDescription: String? {
        switch self {
        case .saveFailed: L10n.string("error.store.saveFailed", table: .errors)
        case .deleteFailed: L10n.string("error.store.deleteFailed", table: .errors)
        }
    }
}
```

`Persistence/ModelContainerFactory.swift`:

```swift
import SwiftData

enum ModelContainerFactory {
    static func make(inMemory: Bool = false) throws(PersistenceError) -> ModelContainer {
        let configuration = ModelConfiguration(
            schema: currentDatabaseSchema,
            isStoredInMemoryOnly: inMemory,
            cloudKitDatabase: .none
        )
        do {
            return try ModelContainer(
                for: currentDatabaseSchema,
                migrationPlan: DatabaseMigrationPlan.self,
                configurations: [configuration]
            )
        } catch {
            throw .containerCreationFailed(reason: String(describing: error))
        }
    }
}
```

`App/ContainerErrorView.swift`: `struct ContainerErrorView: View { let error: PersistenceError }` – `ContentUnavailableView` mit Titel `containerError.title`, Symbol `exclamationmark.triangle`, Beschreibung = `error.localizedDescription` + Leerzeile + `containerError.message`.

### 4.3 Session-Domäne (`SessionConfiguration`: W0-T1, Rest: W0-T2)

```swift
// Core/Session/SessionConfiguration.swift (W0-T1)
nonisolated struct SessionConfiguration: Hashable, Sendable {
    static let plannedSecondsRange = 10...600
    static let preparationSecondsRange = 5...60
    static let stepSeconds = 5
    static let standard = SessionConfiguration(plannedSeconds: 60, preparationSeconds: 10)

    let plannedSeconds: Int
    let preparationSeconds: Int

    init(plannedSeconds: Int, preparationSeconds: Int) {
        self.plannedSeconds = Self.normalized(plannedSeconds, in: Self.plannedSecondsRange)
        self.preparationSeconds = Self.normalized(preparationSeconds, in: Self.preparationSecondsRange)
    }

    /// Rounds to the nearest multiple of `stepSeconds` (ties round up), then clamps to `range`.
    static func normalized(_ seconds: Int, in range: ClosedRange<Int>) -> Int
}

// Core/Session/SessionPhase.swift
enum SessionOutcome: Equatable, Sendable { case completed, stopped }

enum SessionPhase: Equatable, Sendable {
    case preparing
    case running
    case paused
    case resuming
    case finished(SessionOutcome)
    case cancelled

    var isTerminal: Bool {
        switch self {
        case .finished, .cancelled: true
        case .preparing, .running, .paused, .resuming: false
        }
    }
}

// Core/Session/SessionResult.swift
struct SessionResult: Equatable, Sendable {
    let configuration: SessionConfiguration
    let startedAt: Date
    let endedAt: Date
    let extensionSeconds: Int
    let achievedSeconds: Int
    let pauseCount: Int
    let outcome: SessionOutcome
    let isNewRecord: Bool

    var isGoalReached: Bool { achievedSeconds >= configuration.plannedSeconds }
}

// Core/Session/SessionHistoryContext.swift
struct LastSessionInfo: Equatable, Sendable {
    let achievedSeconds: Int
    let isGoalReached: Bool
}

struct SessionHistoryContext: Equatable, Sendable {
    var recordSeconds: Int?
    var lastSession: LastSessionInfo?

    static let empty = SessionHistoryContext(recordSeconds: nil, lastSession: nil)
}

// Core/Session/SessionClock.swift
protocol SessionClock {
    var now: ContinuousClock.Instant { get }
    var currentDate: Date { get }
}

struct SystemSessionClock: SessionClock {
    var now: ContinuousClock.Instant { ContinuousClock.now }
    var currentDate: Date { Date.now }
}

// Core/Session/SessionHaptic.swift
enum SessionHaptic: Equatable, Sendable { case countdownTick, runningStarted, completed }

struct SessionHapticSignal: Equatable, Sendable {
    let sequence: Int
    let haptic: SessionHaptic
}

// Core/Session/SessionTimerDisplay.swift
struct SessionTimerDisplay: Equatable, Sendable {
    var remainingSeconds: Int
    var elapsedSeconds: Int
    var totalSeconds: Int
    var extensionSeconds: Int
    var isPaused: Bool

    var isFinalCountdown: Bool { remainingSeconds > 0 && remainingSeconds <= 5 }
}
```

### 4.4 Ansage-Modelle und -Protokolle (W0-T2)

```swift
// Core/Announcements/CoachStyle.swift
enum CoachStyle: String, CaseIterable, Sendable {
    case calm, demanding, cheeky, off
    static let standard: CoachStyle = .demanding
}

// Core/Announcements/AnnouncementModels.swift
enum CoachOccasion: String, CaseIterable, Sendable {
    case start, halfway, finalStretch, filler, recordInSight, newRecord, lastSession, resume, completion, stopped
}

enum FixedPhrase: Sendable { case prepare, startWithoutCoach, complete, stoppedWithoutCoach }

enum AnnouncementKind: Hashable, Sendable {
    case prepare, start, resume
    case timeRemaining(Int)
    case countdown(Int)
    case halfway, finalStretch, recordInSight, newRecord, lastSession
    case postureHint, filler

    var oneOff: OneOffAnnouncement? {
        switch self {
        case .halfway: .halfway
        case .finalStretch: .finalStretch
        case .recordInSight: .recordInSight
        case .newRecord: .newRecord
        case .lastSession: .lastSession
        case .prepare, .start, .resume, .timeRemaining, .countdown, .postureHint, .filler: nil
        }
    }
}

enum OneOffAnnouncement: Hashable, Sendable { case halfway, finalStretch, recordInSight, newRecord, lastSession }

struct ScheduledAnnouncement: Equatable, Sendable {
    static let charactersPerSecond = 14.0

    let elapsedSecond: Int
    let kind: AnnouncementKind
    let prefixKind: AnnouncementKind?
    let text: String

    init(elapsedSecond: Int, kind: AnnouncementKind, prefixKind: AnnouncementKind? = nil, text: String) {
        self.elapsedSecond = elapsedSecond
        self.kind = kind
        self.prefixKind = prefixKind
        self.text = text
    }

    var estimatedDuration: Double { Double(text.count) / Self.charactersPerSecond }
    var oneOffs: Set<OneOffAnnouncement> { Set([kind.oneOff, prefixKind?.oneOff].compactMap { $0 }) }
}

enum PlanTrigger: Sendable { case start, resume, extended }

struct PreviousAnnouncement: Equatable, Sendable {
    let startSecond: Int
    let estimatedDuration: Double
}

struct GapAnnouncement: Equatable, Sendable {
    let second: Int
    let kind: AnnouncementKind   // .filler or .postureHint
}

struct AnnouncementPlanInput: Equatable, Sendable {
    var trigger: PlanTrigger
    var totalSeconds: Int
    var elapsedSeconds: Int
    var history: SessionHistoryContext
    var style: CoachStyle
    var postureHintsEnabled: Bool
    var spokenOneOffs: Set<OneOffAnnouncement> = []
    var lastGapAnnouncement: GapAnnouncement? = nil
    var previous: PreviousAnnouncement? = nil
}

struct ClosingInput: Equatable, Sendable {
    var achievedSeconds: Int
    var plannedSeconds: Int
    var isNewRecord: Bool
    var newRecordAlreadyAnnounced: Bool
    var style: CoachStyle

    var isGoalReached: Bool { achievedSeconds >= plannedSeconds }
}

// Core/Announcements/AnnouncementProtocols.swift
protocol AnnouncementTextProviding {
    /// "{time}"/"{achieved}" without "noch"/"to go": "45 Sekunden", "1 Minute", "2 Minuten 30".
    func duration(_ seconds: Int) -> String
    /// Stand-alone time announcement: "Noch 2 Minuten 30." / "2 minutes 30 to go."
    func timeRemaining(_ seconds: Int) -> String
    /// Number only: "5".
    func countdown(_ number: Int) -> String
    /// `argument` fills the placeholder of `.startWithoutCoach` and `.stoppedWithoutCoach`; ignored otherwise.
    func fixed(_ phrase: FixedPhrase, argument: String?) -> String
}

protocol CoachPhraseProviding: AnyObject {
    /// Returns nil for `.off`. Draws without repetition per (style, occasion).
    func coachPhrase(_ occasion: CoachOccasion, style: CoachStyle, argument: String?) -> String?
    /// Style-independent posture hint, drawn without repetition.
    func postureHint() -> String?
}

protocol AnnouncementPlanning {
    /// Seconds are relative to the start of the preparation phase.
    func preparationAnnouncements(preparationSeconds: Int) -> [ScheduledAnnouncement]
    /// Seconds are relative to the start of the resume countdown.
    func resumeCountdownAnnouncements() -> [ScheduledAnnouncement]
    /// Seconds are active session seconds. Result is sorted by `elapsedSecond`.
    func plan(_ input: AnnouncementPlanInput) -> [ScheduledAnnouncement]
    func closingText(_ input: ClosingInput) -> String
}
```

### 4.5 Sprachausgabe-Vertrag (W0-T2)

```swift
// Core/Announcements/Announcing.swift
import Foundation

enum AnnouncerError: LocalizedError, Equatable {
    case unavailable

    var errorDescription: String? { L10n.string("error.announcer.unavailable", table: .errors) }
}

protocol Announcing: AnyObject {
    /// Configures the audio session once per session. Throws if audio is unavailable.
    func prepare() throws(AnnouncerError)
    func speak(_ text: String) throws(AnnouncerError)
    func stopSpeaking()
}

final class SilentAnnouncer: Announcing {
    func prepare() throws(AnnouncerError) {}
    func speak(_ text: String) throws(AnnouncerError) {}
    func stopSpeaking() {}
}
```

### 4.6 App, Router, Environment, Previews (W0-T2)

```swift
// App/AppRouter.swift
import Observation

enum AppTab: Hashable, CaseIterable, Sendable { case training, history, settings }

enum Route: Hashable, Sendable {
    case sessionDetail(UUID)
    case about
}

enum FullScreen: Identifiable, Hashable, Sendable {
    case activeSession(SessionConfiguration)
    var id: Self { self }
}

@Observable
final class AppRouter {
    var selectedTab: AppTab = .training
    var paths: [AppTab: [Route]] = [:]
    var fullScreen: FullScreen?

    /// Exactly one push level per tab (convention, enforced here).
    func push(_ route: Route) { paths[selectedTab] = [route] }
    func popToRoot() { paths[selectedTab] = [] }
    func present(_ fullScreen: FullScreen) { self.fullScreen = fullScreen }
    func dismissFullScreen() { fullScreen = nil }
    func path(for tab: AppTab) -> [Route] { paths[tab] ?? [] }
    func setPath(_ path: [Route], for tab: AppTab) { paths[tab] = Array(path.prefix(1)) }
}

// App/AppEnvironment.swift
import Observation

@Observable
final class AppEnvironment {
    let userSettings: UserSettings
    let announcer: any Announcing

    init(userSettings: UserSettings, announcer: any Announcing) {
        self.userSettings = userSettings
        self.announcer = announcer
    }
}

// App/PlanktrainerApp.swift (Endstand W0-T2; W1-T5 ersetzt SilentAnnouncer() durch SpeechAnnouncer())
import SwiftData
import SwiftUI

@main
struct PlanktrainerApp: App {
    @State private var appEnvironment = AppEnvironment(userSettings: UserSettings(), announcer: SilentAnnouncer())
    @State private var router = AppRouter()
    private let containerResult: Result<ModelContainer, PersistenceError>

    init() {
        do {
            containerResult = .success(try ModelContainerFactory.make())
        } catch {
            containerResult = .failure(error)
        }
    }

    var body: some Scene {
        WindowGroup {
            switch containerResult {
            case .success(let container):
                RootView()
                    .environment(appEnvironment)
                    .environment(router)
                    .preferredColorScheme(appEnvironment.userSettings.appearance.colorScheme)
                    .modelContainer(container)
            case .failure(let error):
                ContainerErrorView(error: error)
            }
        }
    }
}
```

`App/RootView.swift` (W0-T2, Endstand für M1):
- `TabView(selection:)` mit `Tab(value:content:label:)` für `.training`, `.history`, `.settings`; Labels `Label { Text("tab.training", tableName: LocalizationTable.app.rawValue) } icon: { Image(systemName: "figure.core.training") }` bzw. `chart.bar.fill`, `gearshape.fill`.
- Jeder Tab-Inhalt in `NavigationStack(path:)` mit `Binding(get: { router.path(for: tab) }, set: { router.setPath($0, for: tab) })` und `.navigationDestination(for: Route.self)`: `.sessionDetail(let id)` → `SessionDetailScreen(sessionID: id)`, `.about` → `AboutScreen()`.
- `.fullScreenCover(item:)` auf `router.fullScreen`: `.activeSession(let configuration)` → `ActiveSessionScreen(configuration: configuration)`.
- Ein späteres Sheet wird als weiteres `.sheet(item:)` an derselben Stelle ergänzt (kein Enum jetzt, YAGNI).

`App/PreviewSupport.swift` (W0-T2, komplett in `#if DEBUG`):

```swift
extension AppEnvironment {
    static func preview() -> AppEnvironment
}

enum PreviewData {
    /// In-memory container with 8 sample sessions (mixed goal reached/missed, one clear record, dates over the last 10 days).
    static func makeContainer() throws -> ModelContainer
}

/// Wraps preview content with container, AppEnvironment.preview() and a fresh AppRouter.
struct PreviewHost<Content: View>: View {
    init(@ViewBuilder content: @escaping () -> Content)
    var body: some View
}
```

`PreviewHost` erzeugt den Container im `body` über `do/catch` und zeigt bei Fehler `ContainerErrorView`. Verwendung in allen Feature-Previews: `#Preview { PreviewHost { HistoryScreen() } }`.

### 4.7 Einstellungen (W0-T2)

```swift
// Settings/UserSettings.swift
import Observation
import SwiftUI

@Observable
final class UserSettings {
    enum Appearance: String, CaseIterable, Sendable {
        case system, light, dark

        var colorScheme: ColorScheme? {
            switch self {
            case .system: nil
            case .light: .light
            case .dark: .dark
            }
        }
    }

    var appearance: Appearance { didSet { /* persist */ } }
    var coachStyle: CoachStyle { didSet { /* persist */ } }
    var postureHintsEnabled: Bool { didSet { /* persist */ } }
    var hapticsEnabled: Bool { didSet { /* persist */ } }
    private(set) var lastConfiguration: SessionConfiguration

    init(defaults: UserDefaults = .standard)

    /// Stores planned and preparation seconds as the new defaults (spec 3.2, 3.9).
    func rememberConfiguration(_ configuration: SessionConfiguration)
}
```

Standardwerte (nur hier): `appearance = .system`, `coachStyle = CoachStyle.standard`, `postureHintsEnabled = true`, `hapticsEnabled = true`, `lastConfiguration = SessionConfiguration.standard`. Schlüssel: `userSettings.appearance`, `userSettings.coachStyle`, `userSettings.postureHintsEnabled`, `userSettings.hapticsEnabled`, `userSettings.lastPlannedSeconds`, `userSettings.lastPreparationSeconds`. Gelesene Werte laufen durch `SessionConfiguration.init` (Normalisierung). `defaults` ist `@ObservationIgnored private let`.

### 4.8 Screen-Platzhalter (W0-T2, ersetzt in W2)

Jede Datei enthält die endgültige Signatur und einen Platzhalter-Body `Text(verbatim: "<TypName>")` mit Kommentar `// PLACEHOLDER(<Task-ID>)`. Die W2-Aufgabe ersetzt den Body und entfernt den Kommentar; die Aufrufsignatur bleibt.

| Datei | Signatur | ersetzt durch |
|---|---|---|
| `Features/Training/TrainingScreen.swift` | `struct TrainingScreen: View` (ohne Parameter) | W2-T1 |
| `Features/History/HistoryScreen.swift` | `struct HistoryScreen: View` | W2-T2 |
| `Features/SessionDetail/SessionDetailScreen.swift` | `struct SessionDetailScreen: View`, Aufruf `SessionDetailScreen(sessionID: UUID)` | W2-T3 |
| `Features/ActiveSession/ActiveSessionScreen.swift` | `struct ActiveSessionScreen: View`, Aufruf `ActiveSessionScreen(configuration: SessionConfiguration)` | W2-T4 |
| `Features/ActiveSession/SessionCountdownView.swift` | `struct SessionCountdownView: View { let value: Int; let caption: LocalizedStringResource }` | W2-T5 |
| `Features/ActiveSession/SessionTimerView.swift` | `struct SessionTimerView: View { let display: SessionTimerDisplay; let remainingFraction: () -> Double }` | W2-T5 |
| `Features/ActiveSession/SessionResultView.swift` | `struct SessionResultView: View { let result: SessionResult; let onDone: () -> Void }` | W2-T5 |
| `Features/Settings/SettingsScreen.swift` | `struct SettingsScreen: View` | W2-T6 |
| `Features/Settings/AboutScreen.swift` | `struct AboutScreen: View` | W2-T6 |

### 4.9 Design-Tokens (W0-T2, Werte später durch D1)

```swift
// DesignSystem/ThemeColor.swift
import SwiftUI

enum ThemeColor {
    static let accent: Color = .accentColor
    static let success: Color = .green
    static let destructive: Color = .red
    static let paused: Color = .orange
    static let contentPrimary: Color = .primary
    static let contentSecondary: Color = .secondary
    static let surface = Color(uiColor: .systemBackground)
    static let groupedSurface = Color(uiColor: .systemGroupedBackground)
    static let elevatedSurface = Color(uiColor: .secondarySystemGroupedBackground)
    static let ringTrack = Color(uiColor: .tertiarySystemFill)
}

// DesignSystem/ThemeFont.swift
import SwiftUI

enum ThemeFont {
    static let sectionTitle: Font = .headline
    static let body: Font = .body
    static let caption: Font = .footnote
    static let valueEmphasis: Font = .title2.weight(.semibold).monospacedDigit()
    static let rowValue: Font = .body.monospacedDigit()
    static let sessionCaption: Font = .title2.weight(.semibold)
}

enum ScaledTimeSize: Sendable {
    case session      // remaining time in the session ring, base 88 pt
    case countdown    // preparation/resume countdown, base 120 pt
    case detail       // achieved time in the detail ring, base 40 pt
    case result       // achieved time on the result screen, base 64 pt

    var baseSize: CGFloat { /* 88, 120, 40, 64 */ }
}

extension View {
    /// SF Pro Rounded, semibold, monospaced digits, scaled with Dynamic Type relative to .largeTitle,
    /// one line with minimumScaleFactor 0.4.
    func scaledTimeFont(_ size: ScaledTimeSize) -> some View
}

// DesignSystem/ThemeMetrics.swift
import CoreGraphics

enum ThemeSpacing {
    static let xs: CGFloat = 4
    static let s: CGFloat = 8
    static let m: CGFloat = 12
    static let l: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
}

enum ThemeRadius {
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let large: CGFloat = 20
}

enum ThemeSize {
    static let minimumTapTarget: CGFloat = 44
    static let sessionControlHeight: CGFloat = 72
    static let sessionControlSpacing: CGFloat = 24
}

enum RingMetrics {
    static let sessionDiameterRatio: CGFloat = 0.78   // of container width
    static let detailDiameterRatio: CGFloat = 0.5
    static let compactDiameter: CGFloat = 28
    static let lineWidthRatio: CGFloat = 0.08         // of diameter
}
```

`scaledTimeFont` wird als privater `ViewModifier` mit `@ScaledMetric(relativeTo: .largeTitle) private var scale: CGFloat = 1` umgesetzt; Schriftgröße = `baseSize * scale`, `.font(.system(size:weight: .semibold, design: .rounded).monospacedDigit())`, `.lineLimit(1)`, `.minimumScaleFactor(0.4)`.

`Resources/Assets.xcassets`: `AccentColor.colorset` (ohne eigene Farbe → System-Blau als Platzhalter) und `AppIcon.appiconset` (Single Size 1024, noch ohne Bild).

### 4.10 Öffentliche APIs aus W1 (für W2)

```swift
// W1-T1 – Core/Announcements/SpokenDurationFormatter.swift, AnnouncementTexts.swift
struct SpokenDurationFormatter: Sendable {
    let locale: Locale
    func duration(_ seconds: Int) -> String
    func timeRemaining(_ seconds: Int) -> String
}
struct AnnouncementTexts: AnnouncementTextProviding {
    init(locale: Locale)
}

// W1-T2 – SplitMix64.swift, ShuffleBag.swift, PhraseCatalog.swift, PhraseSelector.swift
struct SplitMix64: RandomNumberGenerator, Sendable {
    init(seed: UInt64)
    mutating func next() -> UInt64
}
struct ShuffleBag<Element: Equatable> {
    init(_ elements: [Element])
    var isEmpty: Bool { get }
    mutating func next(using generator: inout some RandomNumberGenerator) -> Element?
}
enum PhraseCatalog {
    static func keys(for occasion: CoachOccasion, style: CoachStyle) -> [String]   // [] for .off
    static let postureHintKeys: [String]
}
final class PhraseSelector: CoachPhraseProviding {
    init(locale: Locale, generator: SplitMix64)
}

// W1-T3 – AnnouncementPlanner.swift
struct AnnouncementPlanner: AnnouncementPlanning {
    init(texts: any AnnouncementTextProviding, coach: any CoachPhraseProviding)
}

// W1-T4 – Core/Session/SessionEngine.swift
@Observable
final class SessionEngine {
    let configuration: SessionConfiguration
    private(set) var phase: SessionPhase
    private(set) var elapsedSeconds: Int
    private(set) var extensionSeconds: Int
    private(set) var pauseCount: Int
    private(set) var preparationRemainingSeconds: Int
    private(set) var resumeCountdownRemainingSeconds: Int
    private(set) var result: SessionResult?
    private(set) var announcementError: AnnouncerError?
    private(set) var hapticSignal: SessionHapticSignal?

    var totalSeconds: Int { get }
    var remainingSeconds: Int { get }
    var timerDisplay: SessionTimerDisplay { get }
    func remainingFraction() -> Double

    init(
        configuration: SessionConfiguration,
        history: SessionHistoryContext,
        coachStyle: CoachStyle,
        postureHintsEnabled: Bool,
        announcer: any Announcing,
        planner: any AnnouncementPlanning,
        clock: any SessionClock
    )

    func start()
    func tick()
    func run() async
    func pause()
    func resume()
    func extend()
    func stop()
    func cancel()
}

// W1-T5 – Services
protocol AudioSessionControlling: AnyObject {
    func configureForAnnouncements() throws
    func activate() throws
    func deactivate() throws
}
final class AudioSessionController: AudioSessionControlling { init() }
final class SpeechAnnouncer: Announcing {
    init(audioSession: any AudioSessionControlling = AudioSessionController(), locale: Locale = AppLocale.current)
    static func voiceLanguage(appLanguage: String, systemVoiceLanguage: String) -> String
}
enum AudioInterruption: Equatable, Sendable { case began, ended(shouldResume: Bool) }
enum AudioInterruptionMonitor {
    static func interruption(from userInfo: [AnyHashable: Any]?) -> AudioInterruption?
    static func interruptions() -> AsyncStream<AudioInterruption>
}

// W1-T6 – Persistence
final class SessionStore {
    init(context: ModelContext)
    @discardableResult
    func save(_ result: SessionResult) throws(SessionStoreError) -> PlankSession
    func delete(_ session: PlankSession) throws(SessionStoreError)
}
struct SessionHistorySummary {
    let recordSeconds: Int?
    let recordSessionID: UUID?
    let lastSession: PlankSession?
    init(sessions: [PlankSession])
    var engineContext: SessionHistoryContext { get }
    func isRecord(_ session: PlankSession) -> Bool
    /// nil if there is no record or the session is the record session.
    func secondsBelowRecord(_ session: PlankSession) -> Int?
}

// W1-T7 – Core/Formatting/TimeText.swift
enum TimeText {
    static func clock(_ seconds: Int) -> String                                              // "1:30", "10:00", "0:05"
    static func accessibleDuration(_ seconds: Int, locale: Locale = AppLocale.current) -> String  // "1 minute, 30 seconds"
    static func compactDuration(_ seconds: Int, locale: Locale = AppLocale.current) -> String     // "12 s", "1 min, 12 s"
    static func relativeDateTime(_ date: Date, locale: Locale = AppLocale.current, timeZone: TimeZone = .current) -> String // "Heute, 07:42"
}

// W1-T8 – DesignSystem/ProgressRing.swift
struct ProgressRing: View {
    enum Style: Sendable { case session, detail, compact }
    let fraction: Double
    var style: Style = .session
    var isPaused: Bool = false
    var isHighlighted: Bool = false
}
```

---

## 5. Normative Regeln für Planer und Engine

Diese Regeln konkretisieren Spec 3.3–3.5 so, dass keine Interpretation nötig ist. Abweichungen oder Präzisierungen gegenüber der Spec sind in Abschnitt 10 (Annahmen) begründet.

### 5.1 Ansageplaner (`AnnouncementPlanner.plan`)

Bezeichnungen: `T = input.totalSeconds`, `e0 = input.elapsedSeconds`, Restzeit `r(e) = T − e`. `d(x)` = `estimatedDuration` (Zeichen ÷ 14). Eine „platzierte Ansage“ p hat Start `p.s` (Sekunde) und Ende `p.s + d(p)`. `input.previous` zählt bei allen Prüfungen als bereits platzierte Ansage, erscheint aber nicht im Ergebnis. Phrasen werden über `texts` (`AnnouncementTextProviding`) und `coach` (`CoachPhraseProviding`) bezogen; `coach` liefert bei Stil `.off` immer `nil`.

**Passt-Prüfung** `fits(e, d)` (für Schritte 3–6): Es gibt keine platzierte Ansage mit Start `== e`; für die letzte platzierte Ansage p mit `p.s < e` gilt `e − p.s ≥ 4` **und** `Double(e) ≥ p.s + d(p)`; für die erste platzierte Ansage n mit `n.s > e` gilt `Double(e) + d + 1 ≤ Double(n.s)`. Fehlt p oder n, entfällt die jeweilige Bedingung.

**Schritt 1 – Anker**
- `.start`: Ansage bei `e0`, Art `.start`, Text `coach.coachPhrase(.start, style, argument: texts.duration(r(e0)))` oder, wenn `nil`, `texts.fixed(.startWithoutCoach, argument: texts.duration(r(e0)))`.
- `.resume`: nur wenn `r(e0) > 10`: Ansage bei `e0`, Art `.resume`, Text `coach.coachPhrase(.resume, style, argument: texts.duration(r(e0)))` oder `texts.timeRemaining(r(e0))`.
- `.extended`: kein Anker („nach +10 s keine sofortige Ansage“).

**Schritt 2 – Zeitmarken** (höchste Priorität). Für `r` von `r(e0) − 1` abwärts bis `1`, Sekunde `e = T − r`:
- `r` in `1...5` → Art `.countdown(r)`, Text `texts.countdown(r)`, **immer** platziert (vom Mindestabstand ausgenommen).
- `r > 120 && r % 60 == 0` oder `r <= 120 && r % 30 == 0` oder `r == 15` oder `r == 10` → Art `.timeRemaining(r)`, Text `texts.timeRemaining(r)`. Platziert, wenn für die letzte platzierte Ansage p (`p.s < e`, inkl. Anker und `previous`) gilt: `e − p.s ≥ 4` und `Double(e) ≥ p.s + d(p)`. Sonst entfällt die Marke.
- Die Marke `r == r(e0)` selbst wird nie platziert (Start-/Weiter-Satz enthält die Zeit; nach +10 s keine sofortige Ansage).

**Schritt 3 – Rekord-Ereignisse** (nur Stil ≠ `.off`, `R = history.recordSeconds` vorhanden und `R > 0`):
- Rekord in Sicht: `e = R − 5`, nur wenn `.recordInSight ∉ spokenOneOffs`, `e > e0`, `r(e) > 10`; Text `coachPhrase(.recordInSight, …, argument: nil)`; platziert, wenn `fits(e, d)`.
- Neuer Rekord: `e = R + 1`, gleiche Bedingungen mit `.newRecord`.

**Schritt 4 – Halbzeit und Endspurt** (nur Stil ≠ `.off`):
- Halbzeit-Sekunde `h = T − T / 2` (Ganzzahldivision; entspricht Restzeit `⌊T/2⌋`), nur wenn `.halfway ∉ spokenOneOffs` und `h > e0`. Text P = `coachPhrase(.halfway, …)`.
  1. Gibt es eine platzierte `.timeRemaining`-Ansage m ohne Präfix mit `|m.s − h| < 4` (bei zwei Kandidaten die nähere, bei Gleichstand die frühere): Zusammenführen zu Text `P + " " + m.text`, `prefixKind = .halfway`, sofern die nächste platzierte Ansage n nach m `Double(m.s) + d(neu) + 1 ≤ Double(n.s)` erfüllt. Sonst entfällt die Halbzeit.
  2. Sonst eigenständig bei `h` mit Art `.halfway`, wenn `fits(h, d(P))`.
  3. Sonst Zusammenführen mit der nächsten `.timeRemaining`-Ansage m ohne Präfix mit `h < m.s ≤ h + 10` (Bedingung wie 1.). Sonst entfällt sie.
- Endspurt: nur wenn `.finalStretch ∉ spokenOneOffs` und eine platzierte `.timeRemaining(15)`-Ansage m mit `m.s > e0` **ohne** Präfix existiert: Zusammenführen mit `coachPhrase(.finalStretch, …)` (Bedingung wie Halbzeit 1.). Hat m schon das Halbzeit-Präfix, entfällt der Endspurt (Halbzeit gewinnt).

**Schritt 5 – Letzte Session** (nur Stil ≠ `.off`): `L = history.lastSession`; nur wenn `L` vorhanden, `!L.isGoalReached`, `L.achievedSeconds < T`, `e = L.achievedSeconds`, `e > e0`, `.lastSession ∉ spokenOneOffs`; platziert, wenn `fits(e, d)`; Art `.lastSession`.

**Schritt 6 – Lückenfüller und Haltungs-Hinweise**
- Verfügbare Arten: `.filler` (wenn Stil ≠ `.off`), `.postureHint` (wenn `postureHintsEnabled`). Keine verfügbar → fertig.
- Startart: Sind beide verfügbar, ist die erste Art das Gegenteil von `input.lastGapAnnouncement?.kind`, ohne Vorgänger `.filler`; danach abwechselnd. Ist nur eine verfügbar, immer diese.
- Startsekunde `e = max(e0 + 1, 10, (lastGapAnnouncement?.second ?? -20) + 20)`.
- Schleife, solange `r(e) > 15`: Falls kein Text vorgemerkt ist, für die aktuelle Art ziehen (`coachPhrase(.filler, …)` bzw. `postureHint()`); `nil` → Schleife beenden. Wenn `fits(e, d)`: platzieren, Art wechseln (falls beide verfügbar), Vormerkung leeren, `e += 20`. Sonst `e += 1` (Vormerkung bleibt).

**Ergebnis:** alle platzierten Ansagen außer `previous`, stabil sortiert nach `elapsedSecond`.

**Vorbereitung** `preparationAnnouncements(N)`: `[(0, .prepare, fixed(.prepare)), (N−3, .countdown(3), "3"), (N−2, .countdown(2), "2"), (N−1, .countdown(1), "1")]` (Texte über `texts.countdown`). `N ≥ 5` ist durch `SessionConfiguration` garantiert.

**Resume-Countdown** `resumeCountdownAnnouncements()`: `[(0, .countdown(3)), (1, .countdown(2)), (2, .countdown(1))]`.

**Abschluss** `closingText(input)`: Teile in dieser Reihenfolge, mit einem Leerzeichen verbunden:
1. Ziel erreicht: `fixed(.complete)`, danach `coachPhrase(.completion, style, nil)` falls nicht `nil`.
   Ziel nicht erreicht: `coachPhrase(.stopped, style, argument: duration(achieved))` oder `fixed(.stoppedWithoutCoach, argument: duration(achieved))`.
2. Wenn `isNewRecord && !newRecordAlreadyAnnounced`: `coachPhrase(.newRecord, style, nil)` falls nicht `nil`.

### 5.2 Session-Engine (`SessionEngine`)

Zustände und erlaubte Aktionen (alles andere wird ignoriert, ohne Fehler):

| Aktion | erlaubt in | Wirkung |
|---|---|---|
| `start()` | einmalig, vor allem anderen | Phase `.preparing`, `phaseStart = clock.now`, `announcer.prepare()` (Fehler → `announcementError`), Vorbereitungs-Ansagen planen, fällige sofort sprechen („Mach dich bereit“). |
| `pause()` | `.preparing`, `.running`, `.resuming` | Aktive Zeit aufsummieren, `announcer.stopSpeaking()`, Plan verwerfen, `pauseCount += 1`, Phase `.paused`. |
| `resume()` | `.paused` | Phase `.resuming`, `phaseStart = clock.now`, Resume-Countdown planen, „3“ sofort sprechen + Haptik `.countdownTick`. |
| `extend()` | `.running`, `.paused` | `extensionSeconds += 10`; in `.running` sofort neu planen mit Trigger `.extended` (aktueller `elapsedSeconds`, `previous` = zuletzt gesprochene Ansage); in `.paused` geschieht das beim nächsten Übergang nach `.running`. |
| `stop()` | `.running`, `.paused` | `finish(.stopped)` |
| `cancel()` | `.preparing`, `.running`, `.paused`, `.resuming` | `announcer.stopSpeaking()`, Phase `.cancelled`, kein Ergebnis. |
| `tick()` | jederzeit | siehe unten |

`tick()`:
- `.preparing`: `p = floor(now − phaseStart)` in ganzen Sekunden; fällige Vorbereitungs-Ansagen sprechen; `preparationRemainingSeconds = max(1, N − p)`; wenn `p ≥ N`: `enterRunning` mit Laufbeginn **`phaseStart + N s`** (nicht `now`, damit Tick-Verzögerungen nicht verloren gehen).
- `.resuming`: analog mit 3 s; `resumeCountdownRemainingSeconds = max(1, 3 − p)`; nach 3 s `enterRunning` mit Laufbeginn `phaseStart + 3 s`.
- `.running`: `elapsedSeconds = floor(aktive Zeit)` aktualisieren (nur bei Änderung zuweisen); fällige Ansagen sprechen; wenn `elapsedSeconds ≥ totalSeconds` → `finish(.completed)`.
- sonst: nichts.

Fällige Ansagen: Alle noch nicht verarbeiteten Einträge mit `elapsedSecond ≤ aktuelle Sekunde` werden als verarbeitet markiert; **gesprochen** werden nur die mit `elapsedSecond ≥ aktuelle Sekunde − 1` (veraltete werden übersprungen, z. B. nach einem Hänger). Sprechen heißt: `try announcer.speak(text)`, Erfolg → `announcementError = nil`, Fehler → `announcementError = error`. Danach (unabhängig vom Erfolg): `spokenOneOffs.formUnion(item.oneOffs)`; bei Art `.filler`/`.postureHint` → `lastGapAnnouncement = GapAnnouncement(second:kind:)`; im Zustand `.running` → `lastSpoken = PreviousAnnouncement(startSecond: item.elapsedSecond, estimatedDuration: item.estimatedDuration)`; bei Art `.countdown` → Haptik `.countdownTick`.

`enterRunning(runStart)`: `runningSince = runStart`, Phase `.running`. Erster Lauf (`startedAt == nil`): `startedAt = clock.currentDate`, Haptik `.runningStarted`, Trigger `.start`. Sonst Trigger `.resume`. Plan mit `AnnouncementPlanInput(trigger:, totalSeconds:, elapsedSeconds:, history:, style:, postureHintsEnabled:, spokenOneOffs:, lastGapAnnouncement:, previous: nil)` erstellen und fällige Einträge sofort verarbeiten (Start-/Weiter-Satz).

`finish(outcome)`: Aktive Zeit aufsummieren, `runningSince = nil`. `achieved = outcome == .completed ? totalSeconds : min(floor(aktive Zeit), totalSeconds)`. `endedAt = clock.currentDate`, `startedAt ?? endedAt`. `isNewRecord = history.recordSeconds.map { achieved > $0 } ?? false`. `result` setzen, Phase `.finished(outcome)`. Abschluss-Text über `planner.closingText(ClosingInput(achievedSeconds: achieved, plannedSeconds: configuration.plannedSeconds, isNewRecord:, newRecordAlreadyAnnounced: spokenOneOffs.contains(.newRecord), style:))`; bei `.stopped` vorher `announcer.stopSpeaking()`; dann sprechen. Haptik `.completed`, wenn `result.isGoalReached`.

Abgeleitete Werte:
- aktive Zeit = `accumulatedActive + (runningSince.map { now − $0 } ?? .zero)`; Sekunden ganzzahlig über `duration.components.seconds`.
- `totalSeconds = configuration.plannedSeconds + extensionSeconds`, `remainingSeconds = max(0, totalSeconds − elapsedSeconds)`.
- `remainingFraction()` = `(Double(totalSeconds) − aktive Zeit in Sekunden als Double) / Double(totalSeconds)`, auf `0...1` begrenzt; vor dem ersten Lauf 1.
- `timerDisplay` = `SessionTimerDisplay(remainingSeconds:, elapsedSeconds:, totalSeconds:, extensionSeconds:, isPaused: phase == .paused || phase == .resuming)`.
- `hapticSignal` = neues `SessionHapticSignal` mit fortlaufender `sequence` bei jedem Haptik-Ereignis.

`run() async`: Schleife `while !Task.isCancelled && !phase.isTerminal { tick(); do { try await Task.sleep(for: .milliseconds(100)) } catch { return } }`. Wird von der UI per `.task` gestartet; Tests rufen `tick()` direkt.

Nur für die Logik relevante, nicht beobachtete Zustände (`schedule`, Indizes, `accumulatedActive`, `runningSince`, `phaseStart`, `spokenOneOffs`, `lastGapAnnouncement`, `lastSpoken`, `startedAt`, Abhängigkeiten) sind `@ObservationIgnored`.

---

## 6. Aufgaben

Jede Aufgabe ist als eigenständiger Prompt formuliert (zusammen mit dem Vorspann aus 2.3). Verifikation bedeutet immer: vollständiger Build **und** vollständiger Testlauf mit den Befehlen aus dem Vorspann; beide grün, keine Warnungen in eigenen Dateien.

### Welle 0 – Gerüst und Verträge (nacheinander, Haupt-Working-Tree, designunabhängig)

#### W0-T1 – Projektgerüst, Persistenz, Lokalisierungs-Infrastruktur

- **Agent:** `swift-coding-agent` · Sonnet 5.5 · Effort Medium
- **Arbeitsverzeichnis:** `/Users/dominik/Projects/plank-trainer` (Simulator „iPhone 17“, `-derivedDataPath ios/DerivedData`)
- **Abhängigkeiten:** keine
- **Kontext:** Spec 1.3, 3.11, 3.12, 4.1, 4.4; Plan 3.1, 3.2, 4.1, 4.2, 4.3 (`SessionConfiguration`); `docs/swift/database/*` (Muster)
- **Exklusive Dateien:**
  - `ios/project.yml`, `ios/Planktrainer.xcodeproj/**` (generiert)
  - `ios/SupportingFiles/InfoPlist.xcstrings`
  - `ios/Planktrainer/App/PlanktrainerApp.swift` (vorläufig), `ios/Planktrainer/App/ContainerErrorView.swift`
  - `ios/Planktrainer/Core/Localization/LocalizationTable.swift`
  - `ios/Planktrainer/Core/Session/SessionConfiguration.swift`
  - `ios/Planktrainer/Persistence/DatabaseSchemas.swift`, `MigrationPlans.swift`, `ModelContainerFactory.swift`, `PersistenceError.swift`, `SessionStoreError.swift`, `Models/PlankSession.swift`, `Models/PlankSession+Values.swift`
  - `ios/Planktrainer/Resources/Assets.xcassets/**`
  - `ios/Planktrainer/Resources/Localization/{App,Common,Errors,Announcements,Coach,Training,History,SessionDetail,ActiveSession,SessionDisplay,Settings}.xcstrings`
  - `ios/PlanktrainerTests/Persistence/ModelContainerFactoryTests.swift`, `ios/PlanktrainerTests/Persistence/PlankSessionValuesTests.swift`, `ios/PlanktrainerTests/Localization/LocalizationCompletenessTests.swift`, `ios/PlanktrainerTests/Core/SessionConfigurationTests.swift`

**Schritte**
1. `ios/project.yml` exakt so anlegen:

```yaml
name: Planktrainer
options:
  bundleIdPrefix: de.liehrit
  deploymentTarget:
    iOS: "26.0"
  developmentLanguage: en
settings:
  base:
    SWIFT_VERSION: "6"
    SWIFT_DEFAULT_ACTOR_ISOLATION: MainActor
    SWIFT_APPROACHABLE_CONCURRENCY: "YES"
    SWIFT_STRICT_CONCURRENCY: complete
    TARGETED_DEVICE_FAMILY: "1"
    DEVELOPMENT_TEAM: 8HM2FV529D
    CODE_SIGN_STYLE: Automatic
    MARKETING_VERSION: "1.0.0"
    CURRENT_PROJECT_VERSION: "1"
    LOCALIZATION_PREFERS_STRING_CATALOGS: "YES"
    SWIFT_EMIT_LOC_STRINGS: "YES"
targets:
  Planktrainer:
    type: application
    platform: iOS
    sources:
      - path: Planktrainer
        type: syncedFolder
      - path: SupportingFiles
    settings:
      base:
        PRODUCT_NAME: Planktrainer
        PRODUCT_BUNDLE_IDENTIFIER: de.liehrit.planktrainer
        GENERATE_INFOPLIST_FILE: "YES"
        INFOPLIST_KEY_CFBundleDisplayName: Plank-Trainer
        INFOPLIST_KEY_UILaunchScreen_Generation: "YES"
        INFOPLIST_KEY_UIApplicationSceneManifest_Generation: "YES"
        INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone: UIInterfaceOrientationPortrait
        ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon
        ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME: AccentColor
        ENABLE_PREVIEWS: "YES"
  PlanktrainerTests:
    type: bundle.unit-test
    platform: iOS
    sources:
      - path: PlanktrainerTests
        type: syncedFolder
    dependencies:
      - target: Planktrainer
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: de.liehrit.planktrainer.tests
        GENERATE_INFOPLIST_FILE: "YES"
        TEST_HOST: "$(BUILT_PRODUCTS_DIR)/Planktrainer.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/Planktrainer"
        BUNDLE_LOADER: "$(TEST_HOST)"
schemes:
  Planktrainer:
    build:
      targets:
        Planktrainer: all
        PlanktrainerTests: [test]
    test:
      targets:
        - PlanktrainerTests
```

2. Ordner `ios/Planktrainer/` und `ios/PlanktrainerTests/` anlegen (mindestens die Dateien dieser Aufgabe), dann `cd ios && xcodegen generate`.
3. `InfoPlist.xcstrings` mit `CFBundleDisplayName` (de/en „Plank-Trainer“) anlegen; prüfen, dass `ios/Planktrainer.xcodeproj/project.pbxproj` unter `knownRegions` `de` und `en` enthält.
4. Alle elf Tabellen unter `Resources/Localization/` anlegen: `App`, `Common`, `Errors` mit den Schlüsseln aus 4.1, die übrigen als leeres Gerüst (Format 3.2).
5. `LocalizationTable.swift` (4.1), Persistenz-Dateien (4.2) und `SessionConfiguration.swift` (4.3) umsetzen. `normalized`: auf das nächste Vielfache von 5 runden (bei Gleichstand aufwärts), danach auf den Bereich begrenzen.
6. `Assets.xcassets` mit `AccentColor.colorset` (ohne Farbwert) und `AppIcon.appiconset` (Single Size, iOS, 1024, ohne Bild) anlegen.
7. Vorläufige `PlanktrainerApp.swift`: Container wie in 4.6 über `ModelContainerFactory.make()` erzeugen; Erfolg → `Text(verbatim: "Planktrainer")` mit `// PLACEHOLDER(W0-T2)` und `.modelContainer(container)`, Fehler → `ContainerErrorView(error:)`.
8. Tests schreiben (unten), Build und Test ausführen.

**Akzeptanzkriterien**
- [ ] `cd ios && xcodegen generate` erzeugt das Projekt ohne Fehler; ein zweiter Lauf ändert `project.pbxproj` nicht mehr.
- [ ] `project.pbxproj` enthält `PBXFileSystemSynchronizedRootGroup` für `Planktrainer` und `PlanktrainerTests` sowie `knownRegions` mit `de` und `en`.
- [ ] Build-Einstellungen wie Spec 4.1 (Swift 6, Default-Isolation MainActor, Approachable Concurrency, strikte Concurrency, nur iPhone, nur Portrait, Team `8HM2FV529D`, iOS 26.0).
- [ ] `@Model`-Klasse kompiliert unter Default-Isolation MainActor **ohne Warnung** (Frühprüfung des Risikos R1).
- [ ] Keine `fatalError`, kein `try?`, kein Force-Unwrap; `ModelContainerFactory.make` wirft `PersistenceError`.
- [ ] Alle Modell-Eigenschaften optional, kein `@Attribute(.unique)`.
- [ ] Die App startet im Simulator (manuell: `xcrun simctl launch`), es erscheint der Platzhaltertext.

**Tests (Swift Testing)**
- `ModelContainerFactoryTests`: In-Memory-Container lässt sich erzeugen; `PlankSession` einfügen, `save()`, per `FetchDescriptor` mit `SortDescriptor(\.startedAt, order: .reverse)` laden (Reihenfolge stimmt); `#Predicate { $0.id == id }` mit `let id: UUID? = …` findet genau einen Eintrag.
- `PlankSessionValuesTests`: Modell mit allen Eigenschaften `nil` → `idValue == PlankSession.missingID`, `startedAtValue == .distantPast`, `plannedSecondsValue == 60`, `preparationSecondsValue == 10`, `achievedSecondsValue == 0`, `isGoalReached == false`; Modell mit Werten → Werte werden durchgereicht; `isGoalReached` bei `achieved == planned` → `true`.
- `SessionConfigurationTests` (parametrisiert): planned `0→10`, `5→10`, `12→10`, `13→15`, `62→60`, `600→600`, `630→600`; preparation `0→5`, `12→10`, `13→15`, `61→60`, `90→60`; `standard` = 60/10.
- `LocalizationCompletenessTests`:
  - `@Test(arguments: LocalizationTable.allCases)`: Schlüsselmenge `de` == Schlüsselmenge `en` (Schlüssel aus `<Tabelle>.strings` und `<Tabelle>.stringsdict` der jeweiligen `.lproj` im `Bundle.main` über `Bundle.main.url(forResource:withExtension:subdirectory:localization:)` und `NSDictionary(contentsOf:) as? [String: Any]`; fehlende Datei = leere Menge).
  - `Bundle.main.localizations` enthält `de` und `en`.
  - `L10n.string("tab.history", table: .app, locale: Locale(identifier: "de")) == "Verlauf"` und für `en` `"History"`.

**Verifikation:** `xcodebuild -project ios/Planktrainer.xcodeproj -scheme Planktrainer -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath ios/DerivedData build` und `… test`
**Commit (Vorschlag):** `chore(ios): scaffold Xcode project with SwiftData schema and string tables`

#### W0-T2 – Gemeinsame Verträge, Router, RootView, Theme, Einstellungen, Platzhalter

- **Agent:** `swift-coding-agent` · Sonnet 5.5 · Effort Medium
- **Arbeitsverzeichnis:** `/Users/dominik/Projects/plank-trainer`
- **Abhängigkeiten:** W0-T1 abgenommen
- **Kontext:** Spec 3.1, 3.3, 3.10, 4.2, 4.3; Plan 3.3, 4.3–4.9, 5.2 (nur zum Verständnis der Typen); `docs/swift/AppEnvironment.swift`, `Dependencies.swift`, `UserSettings.swift` (Muster)
- **Exklusive Dateien:**
  - `ios/Planktrainer/App/PlanktrainerApp.swift` (übernimmt von W0-T1), `AppEnvironment.swift`, `AppRouter.swift`, `RootView.swift`, `PreviewSupport.swift`
  - `ios/Planktrainer/Core/Session/{SessionPhase,SessionResult,SessionHistoryContext,SessionClock,SessionHaptic,SessionTimerDisplay}.swift`
  - `ios/Planktrainer/Core/Announcements/{CoachStyle,AnnouncementModels,AnnouncementProtocols,Announcing}.swift`
  - `ios/Planktrainer/Settings/UserSettings.swift`
  - `ios/Planktrainer/DesignSystem/{ThemeColor,ThemeFont,ThemeMetrics}.swift`
  - Platzhalter aus 4.8 (neun Dateien unter `ios/Planktrainer/Features/`)
  - `ios/PlanktrainerTests/Core/AppRouterTests.swift`, `ios/PlanktrainerTests/Core/UserSettingsTests.swift`, `ios/PlanktrainerTests/Core/AnnouncementModelsTests.swift`

**Schritte**
1. Alle Typen aus 4.3 (außer `SessionConfiguration`), 4.4, 4.5, 4.6, 4.7, 4.9 wörtlich anlegen und implementieren.
2. `PlanktrainerApp.swift` auf den Endstand aus 4.6 bringen (RootView, Environment, `preferredColorScheme`, Container-Fehler).
3. `RootView` wie in 4.6 beschrieben bauen.
4. `PreviewSupport.swift`: `AppEnvironment.preview()` (UserSettings mit `UserDefaults(suiteName: "preview") ?? .standard`, `SilentAnnouncer()`), `PreviewData.makeContainer()` mit 8 Beispiel-Sessions, `PreviewHost`.
5. Platzhalter-Screens (4.8) anlegen, jeweils mit `#Preview { PreviewHost { … } }`.
6. Tests schreiben, Build und Test ausführen.

**Akzeptanzkriterien**
- [ ] Alle Verträge aus 4.3–4.9 existieren mit exakt diesen Namen und Signaturen.
- [ ] App startet im Simulator mit drei Tabs (Training, Verlauf, Einstellungen; deutsch bei Systemsprache Deutsch), Start auf „Training“, Tab-Symbole `figure.core.training`, `chart.bar.fill`, `gearshape.fill`.
- [ ] HIG `tab-bars.md › Best practices`: „Use a tab bar to support navigation, not to provide actions.“ und „Include tab labels … Use single words whenever possible.“ – Tabs haben Einwort-Labels und lösen keine Aktionen aus.
- [ ] `UserSettings` folgt dem Muster aus `docs/swift/UserSettings.swift` (didSet-Persistenz), ohne deutsche Labels im Code; alle Standardwerte nur dort.
- [ ] `AppRouter.push` hält je Tab höchstens eine Push-Ebene.
- [ ] `SilentAnnouncer` ist in `PlanktrainerApp` als vorläufiger Announcer eingesetzt (wird in W1-T5 ersetzt).
- [ ] Jede Platzhalterdatei enthält `// PLACEHOLDER(W2-Tx)` mit der richtigen Task-ID.
- [ ] Keine verbotenen APIs; keine Warnungen.

**Tests (Swift Testing)**
- `AppRouterTests`: Start `selectedTab == .training`; `push(.about)` zweimal → Pfad hat genau ein Element; `push` wirkt nur auf `selectedTab`; `popToRoot` leert nur den aktuellen Tab; `setPath([a, b], for:)` speichert nur `a`; `present`/`dismissFullScreen` setzen/leeren `fullScreen`; `FullScreen.activeSession(c).id == .activeSession(c)`.
- `UserSettingsTests` (eigene Suite je Test): Standardwerte bei leerer Suite (`.system`, `.demanding`, `true`, `true`, 60/10); jede Eigenschaft wird persistiert und von einer neuen Instanz mit derselben Suite gelesen; `rememberConfiguration` speichert beide Werte; ungültige gespeicherte Werte (z. B. `lastPlannedSeconds = 7`, `coachStyle = "unknown"`) → normalisiert bzw. Standard.
- `AnnouncementModelsTests`: `estimatedDuration` von 14 Zeichen = 1.0; `oneOffs` von `ScheduledAnnouncement(kind: .timeRemaining(30), prefixKind: .halfway, …)` = `[.halfway]`; `ClosingInput.isGoalReached` an der Grenze; `SessionTimerDisplay.isFinalCountdown` für 0, 1, 5, 6; `SessionPhase.isTerminal`.

**Verifikation:** wie W0-T1
**Commit (Vorschlag):** `feat(core): add shared contracts, router, root view, theme tokens and settings`

### Welle 1 – Logik und Dienste (parallel, Arbeitskopien, designunabhängig)

Gemeinsame Vorbedingung: W0 abgenommen. Jede Aufgabe kompiliert allein gegen die W0-Verträge.

#### W1-T1 – Gesprochene Zeiten und feste Ansagetexte

- **Agent:** `swift-coding-agent` · Sonnet 5.5 · Effort Medium
- **Abhängigkeiten:** W0
- **Kontext:** Spec 3.4 („Formulierung der Zeit“), 3.12; `docs/spec/announcement-phrases.md` › „Feste Texte“; Plan 3.2, 4.4 (`AnnouncementTextProviding`, `FixedPhrase`), 4.10
- **Exklusive Dateien:** `ios/Planktrainer/Core/Announcements/SpokenDurationFormatter.swift`, `ios/Planktrainer/Core/Announcements/AnnouncementTexts.swift`, `ios/Planktrainer/Resources/Localization/Announcements.xcstrings`, `ios/PlanktrainerTests/Announcements/SpokenDurationFormatterTests.swift`, `ios/PlanktrainerTests/Announcements/AnnouncementTextsTests.swift`

**Schritte**
1. `Announcements.xcstrings` mit genau diesen Schlüsseln füllen:

| Schlüssel | en | de |
|---|---|---|
| `duration.seconds %lld` (Plural) | one: `%lld second`, other: `%lld seconds` | one: `%lld Sekunde`, other: `%lld Sekunden` |
| `duration.minutes %lld` (Plural) | one: `%lld minute`, other: `%lld minutes` | one: `%lld Minute`, other: `%lld Minuten` |
| `duration.minutesAndSeconds %@ %lld` | `%1$@ %2$lld` | `%1$@ %2$lld` |
| `announcement.timeRemaining %@` | `%@ to go.` | `Noch %@.` |
| `announcement.prepare` | `Get ready.` | `Mach dich bereit.` |
| `announcement.startWithoutCoach %@` | `Planking session started, %@ to go.` | `Planking Session gestartet, noch %@.` |
| `announcement.complete` | `Planking session complete.` | `Planking Session abgeschlossen.` |
| `announcement.stoppedWithoutCoach %@` | `Stopped after %@.` | `Gestoppt nach %@.` |

2. `SpokenDurationFormatter.duration(s)`: `s < 0` wie 0. `s < 60` → `duration.seconds`. Sonst `m = s / 60`, `rest = s % 60`: `rest == 0` → `duration.minutes m`; sonst `duration.minutesAndSeconds` mit (`duration.minutes m`, `rest`) – „Sekunden“ entfällt (Spec 3.4). Alle Lookups über `L10n.string(_:table: .announcements, locale: locale)` mit String-Interpolation, z. B. `L10n.string("duration.seconds \(s)", table: .announcements, locale: locale)`.
3. `timeRemaining(s)` = `announcement.timeRemaining` mit `duration(s)`.
4. `AnnouncementTexts(locale:)` implementiert `AnnouncementTextProviding`: `duration`/`timeRemaining` über den Formatter, `countdown(n)` = `n.formatted(.number.locale(locale))`, `fixed` über die Schlüssel oben (`argument` bei `.startWithoutCoach`/`.stoppedWithoutCoach` einsetzen; fehlt es, `duration(0)` einsetzen).

**Akzeptanzkriterien**
- [ ] Alle Schlüssel in `de` und `en`; `LocalizationCompletenessTests` bleibt grün.
- [ ] Singular/Plural ausschließlich über Plural-Varianten des Catalogs (Spec 3.4), keine `if count == 1`-Logik.
- [ ] Keine Abhängigkeit zu SwiftUI.

**Tests (parametrisiert, beide Sprachen)**
- `duration`: de `45→"45 Sekunden"`, `1→"1 Sekunde"`, `60→"1 Minute"`, `90→"1 Minute 30"`, `120→"2 Minuten"`, `150→"2 Minuten 30"`, `600→"10 Minuten"`, `0→"0 Sekunden"`; en `45→"45 seconds"`, `1→"1 second"`, `60→"1 minute"`, `90→"1 minute 30"`, `120→"2 minutes"`, `150→"2 minutes 30"`, `600→"10 minutes"`.
- `timeRemaining` (Spec-Tabelle 3.4): de `45→"Noch 45 Sekunden."`, `60→"Noch 1 Minute."`, `90→"Noch 1 Minute 30."`, `150→"Noch 2 Minuten 30."`, `120→"Noch 2 Minuten."`; en `45→"45 seconds to go."`, `60→"1 minute to go."`, `90→"1 minute 30 to go."`, `150→"2 minutes 30 to go."`, `120→"2 minutes to go."`.
- `fixed`: de `.prepare → "Mach dich bereit."`, `.startWithoutCoach("1 Minute") → "Planking Session gestartet, noch 1 Minute."`, `.complete → "Planking Session abgeschlossen."`, `.stoppedWithoutCoach("42 Sekunden") → "Gestoppt nach 42 Sekunden."`; en entsprechend.
- `countdown(5) == "5"` in beiden Sprachen.

**Commit (Vorschlag):** `feat(announcements): add spoken duration formatter and fixed announcement texts`

#### W1-T2 – Coach-Sätze, Shuffle-Bag, Zufallsquelle

- **Agent:** `swift-coding-agent` · Sonnet 5.5 · Effort Medium
- **Abhängigkeiten:** W0
- **Kontext:** Spec 3.5 („Coach-Stile“, „Keine Wiederholung“), 3.12; `docs/spec/announcement-phrases.md` (vollständig); Plan 3.2, 4.4 (`CoachPhraseProviding`, `CoachOccasion`), 4.10
- **Exklusive Dateien:** `ios/Planktrainer/Core/Announcements/{SplitMix64,ShuffleBag,PhraseCatalog,PhraseSelector}.swift`, `ios/Planktrainer/Resources/Localization/Coach.xcstrings`, `ios/PlanktrainerTests/Announcements/ShuffleBagTests.swift`, `ios/PlanktrainerTests/Announcements/PhraseSelectorTests.swift`

**Schritte**
1. `Coach.xcstrings`: **alle** Sätze aus `announcement-phrases.md` außer „Feste Texte“ übernehmen, wörtlich (Deutsch = `de`, Englisch = `en`). Schlüssel `coach.<style>.<occasion>.<NN>` mit `style ∈ {calm (Ruhig), demanding (Fordernd), cheeky (Frech)}`, `occasion` = `CoachOccasion.rawValue`, `NN` zweistellig ab `01` in der Reihenfolge des Dokuments. Haltungs-Hinweise: `coach.posture.NN` (`01`–`10`). Platzhalter `{time}` und `{achieved}` werden zu `%@`. Mengen (pro Stil): start 4, halfway 4, finalStretch 4, filler 10, recordInSight 3, newRecord 4, lastSession 3, resume 3, completion 5, stopped 3; posture 10 → insgesamt 139 Schlüssel.
2. `SplitMix64` exakt so:

```swift
struct SplitMix64: RandomNumberGenerator, Sendable {
    private var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}
```

3. `ShuffleBag`: hält die verbleibenden Elemente; ist sie leer, wird mit allen Elementen neu gemischt (`shuffled(using:)`). Gilt nach dem Neumischen `count > 1` und das erste neue Element ist gleich dem zuletzt gezogenen, wird es mit einem anderen getauscht (keine Wiederholung über die Grenze hinweg). Leere Eingabe → `next` liefert immer `nil`.
4. `PhraseCatalog.keys(for:style:)` erzeugt die Schlüssel aus den Mengen (Schritt 1); `.off` → `[]`. `postureHintKeys` = 10 Schlüssel.
5. `PhraseSelector`: je `(style, occasion)` und für Haltung eine eigene `ShuffleBag<String>` mit Schlüsseln (lazy angelegt), gemeinsamer `SplitMix64`. `coachPhrase` zieht einen Schlüssel, löst ihn mit `L10n.string(String.LocalizationValue(key), table: .coach, locale: locale)` auf und setzt bei vorhandenem `argument` per `String(format: template, locale: locale, argument)` ein. `.off` → `nil`.

**Akzeptanzkriterien**
- [ ] 139 Schlüssel, jeder mit `de` und `en`, Texte wörtlich aus dem Dokument (Tech Lead prüft stichprobenartig 10 Einträge je Sprache).
- [ ] Start- und Weiter-Sätze enthalten `%@`; Gestoppt-Sätze enthalten `%@`; Halbzeit, Endspurt, Füller, Rekord, Letzte Session, Abschluss, Haltung enthalten **kein** `%@`.
- [ ] Ziehen ohne Wiederholung pro Stil und Anlass (Spec 3.5).
- [ ] Zufallsquelle injizierbar und deterministisch.

**Tests**
- `ShuffleBagTests`: Bag mit 5 Elementen liefert in den ersten 5 Zügen jedes Element genau einmal; über 50 Züge nie zweimal dasselbe Element direkt hintereinander; gleicher Seed → gleiche Folge; anderer Seed → (mit diesem Testseed) andere Folge; leere Bag → `nil`; Bag mit 1 Element liefert immer dieses.
- `PhraseSelectorTests`:
  - `@Test(arguments:)` über alle Kombinationen `CoachStyle` (ohne `.off`) × `CoachOccasion` × `["de","en"]`: jeder Schlüssel aus `PhraseCatalog.keys` löst zu einem nicht-leeren Text ≠ Schlüssel auf.
  - Haltung: alle 10 Schlüssel lösen in beiden Sprachen auf.
  - `.off` → `nil` für jeden Anlass.
  - Argument: de `coachPhrase(.start, style: .demanding, argument: "1 Minute")` enthält „1 Minute“; `.stopped` mit „42 Sekunden“ enthält „42 Sekunden“; kein Ergebnis enthält noch `%@`.
  - Keine Wiederholung: 4 Züge `.start`/`.calm` liefern 4 verschiedene Texte.
  - Determinismus: zwei Selector mit gleichem Seed liefern dieselbe Folge von 10 Füllern.
  - Stichprobe wörtlich: Text zu `coach.demanding.filler.03` de = „Nicht nachlassen!“, en = „Don't let up!“; `coach.posture.01` de = „Bauch anspannen.“.

**Commit (Vorschlag):** `feat(announcements): add coach phrase catalog with shuffle bag`

#### W1-T3 – Ansageplaner

- **Agent:** `swift-coding-agent` · Sonnet 5.5 · Effort Medium
- **Abhängigkeiten:** W0 (programmiert ausschließlich gegen Protokolle; Tests mit Fakes)
- **Kontext:** Spec 3.3 (Regeln zu +10 s, Resume), 3.4, 3.5 (Anlässe, Planungsregeln); Plan 4.4, **5.1 (normativ)**
- **Exklusive Dateien:** `ios/Planktrainer/Core/Announcements/AnnouncementPlanner.swift`, `ios/PlanktrainerTests/Announcements/AnnouncementPlannerTests.swift`, `ios/PlanktrainerTests/Announcements/PlannerFakes.swift`

**Schritte**
1. `struct AnnouncementPlanner: AnnouncementPlanning` mit `init(texts:coach:)` exakt nach 5.1 umsetzen. Reine Logik, keine SwiftUI-/AVFoundation-Abhängigkeit.
2. Hilfsfunktionen privat halten; die Passt-Prüfung (`fits`) als eine Funktion, die für Schritte 3–6 genutzt wird.
3. Fakes in `PlannerFakes.swift`:
   - `FakeAnnouncementTexts: AnnouncementTextProviding`: `duration(s) = "D\(s)"`, `timeRemaining(s) = "T\(s)"`, `countdown(n) = "\(n)"`, `fixed(.prepare) = "P"`, `fixed(.startWithoutCoach, a) = "S \(a)"`, `fixed(.complete) = "C"`, `fixed(.stoppedWithoutCoach, a) = "X \(a)"`.
   - `final class FakeCoachPhrases: CoachPhraseProviding`: konfigurierbare Texte je `CoachOccasion` (Standard: kurzer Text `"<occasion>"`, `%@` wird durch das Argument ersetzt), Haltung `"H"`; `.off` → `nil`; zählt Aufrufe je Anlass.
4. Tests schreiben (unten).

**Akzeptanzkriterien**
- [ ] Alle Regeln aus 5.1 umgesetzt; jede Regel ist durch mindestens einen Test abgedeckt.
- [ ] `plan` ist deterministisch für gleiche Eingaben und gleiche Fakes; Ergebnis aufsteigend sortiert, keine zwei Einträge in derselben Sekunde.
- [ ] Keine Zustände im Planer selbst (der Zustand des Ziehens liegt im `CoachPhraseProviding`).

**Tests** (Notation: `(Sekunde, Art)`; Stil `.off`, Haltung aus, ohne Historie, wenn nicht anders angegeben)
1. Spec-Tabelle 3.4 als `@Test(arguments:)`, Trigger `.start`, `e0 = 0`:
   - 300 → `(0,start) (60,tr240) (120,tr180) (180,tr120) (210,tr90) (240,tr60) (270,tr30) (285,tr15) (290,tr10) (295,cd5) (296,cd4) (297,cd3) (298,cd2) (299,cd1)`
   - 150 → `(0,start) (30,tr120) (60,tr90) (90,tr60) (120,tr30) (135,tr15) (140,tr10) (145…149, cd5…cd1)`
   - 60 → `(0,start) (30,tr30) (45,tr15) (50,tr10) (55…59, cd5…cd1)`
   - 45 → `(0,start) (15,tr30) (30,tr15) (35,tr10) (40…44, cd5…cd1)`
   - 20 → `(0,start) (5,tr15) (10,tr10) (15…19, cd5…cd1)`
   - 130 → `(0,start) (10,tr120) (40,tr90) (70,tr60) (100,tr30) (115,tr15) (120,tr10) (125…129, cd5…cd1)`
   - Start-Text bei `.off` = `"S D<T>"`.
2. 0:35 mit Stil `.demanding`: Start-Satz, der nach Einsetzen des Arguments genau 60 Zeichen hat (≈ 4,29 s) → `tr30` bei Sekunde 5 vorhanden; genau 80 Zeichen (≈ 5,71 s) → `tr30` fehlt; `tr15`, `tr10`, `cd5…cd1` in beiden Fällen vorhanden.
3. Mindestabstand: T = 12 → `tr10` (Sekunde 2) fehlt, `cd5…cd1` vorhanden. `previous = (startSecond: 28, estimatedDuration: 3.0)` mit T = 60, `e0 = 28`, Trigger `.extended` → `tr30` (Sekunde 30) fehlt (nur 2 s nach `previous`).
4. Countdown ausgenommen: Fake-Text für `tr10` mit 100 Zeichen → `cd5…cd1` trotzdem vorhanden.
5. +10 s: T = 70, `e0 = 15`, Trigger `.extended` → kein Eintrag bei 15; Einträge `(40,tr30) (55,tr15) (60,tr10) (65…69,cd)`; Marke `tr60` (Sekunde 10) liegt in der Vergangenheit und fehlt. Mit Stil `.demanding` und `spokenOneOffs = [.halfway]` → keine Halbzeit; ohne → eigenständige Halbzeit `(35, halfway)` (nächste Marke `tr30` bei 40 ist 5 s entfernt, der Fake-Text passt davor).
6. Resume: T = 120, `e0 = 50`, Trigger `.resume`, Stil `.off` → `(50, resume)` mit Text `"T70"`; Stil `.calm` → Text aus `coachPhrase(.resume, argument: "D70")`. `e0 = 112` (Rest 8) → kein `resume`-Eintrag.
7. Halbzeit zusammengeführt: T = 60, `.demanding` → Eintrag bei 30 hat `kind == .timeRemaining(30)`, `prefixKind == .halfway`, Text = Halbzeit-Text + `" "` + `"T30"`.
8. Halbzeit eigenständig: T = 300, `.demanding` → `(150, halfway)`.
9. Endspurt: T = 60 → Eintrag bei 45 hat `prefixKind == .finalStretch`. T = 30 → Halbzeit bei 15 (`tr15`) hat Präfix `.halfway`, kein Endspurt.
10. Rekord: `recordSeconds = 40`, T = 120, `.demanding` → `(35, recordInSight)` und `(41, newRecord)`. `recordSeconds = nil` → keine. `recordSeconds = 109`, T = 120 → kein `newRecord` (Sekunde 110, Rest 10 ist nicht > 10). `recordSeconds = 116`, T = 120 → kein `recordInSight` (Sekunde 111, Rest 9). Stil `.off` → keine.
11. Priorität: `recordSeconds = 40`, `lastSession = (36, false)`, T = 120 → `lastSession` fehlt (kollidiert mit `recordInSight` bei 35). Ohne Rekord → `(36, lastSession)`. `lastSession.isGoalReached == true` → fehlt. `lastSession.achievedSeconds = 130`, T = 120 → fehlt.
12. Füller: T = 300, `.demanding`, Haltung an → erster Füller/Hinweis frühestens bei Sekunde 10; Abstand zwischen zwei Lücken-Ansagen ≥ 20 s; keiner mit Rest ≤ 15; Arten wechseln `filler, postureHint, filler, …`; mit `lastGapAnnouncement = (second: 100, kind: .filler)` und `e0 = 105`, Trigger `.extended` → erste Lücken-Ansage frühestens bei 120 und ist `.postureHint`. Stil `.off` + Haltung an → nur `.postureHint`. Stil `.off` + Haltung aus → keine.
13. Invarianten (parametrisiert über T = 10…600 in 5er-Schritten, Stile `.off` und `.demanding`, Haltung an): sortiert, eindeutige Sekunden, jede Nicht-Countdown-Ansage beginnt nicht vor dem geschätzten Ende ihrer Vorgängerin.
14. `preparationAnnouncements(10)` = `(0,prepare) (7,cd3) (8,cd2) (9,cd1)`; `resumeCountdownAnnouncements()` = `(0,cd3) (1,cd2) (2,cd1)`.
15. `closingText`: Ziel erreicht + `.off` → `"C"`; Ziel erreicht + `.calm` → `"C " + completion`; Ziel verfehlt + `.off` → `"X D42"`; Ziel verfehlt + `.cheeky` → stopped-Text mit `"D42"`; `isNewRecord` und nicht angesagt + `.demanding` → endet mit newRecord-Text; `newRecordAlreadyAnnounced` → ohne newRecord-Text; `.off` + neuer Rekord → kein Rekord-Satz.

**Commit (Vorschlag):** `feat(announcements): add announcement planner`

#### W1-T4 – Session-Engine (Zustandsautomat)

- **Agent:** `swift-coding-agent` · Sonnet 5.5 · Effort Medium
- **Abhängigkeiten:** W0 (programmiert gegen `AnnouncementPlanning`, `Announcing`, `SessionClock`; Tests mit Fakes)
- **Kontext:** Spec 3.3 (vollständig), 3.7, 4.3; Plan 4.3–4.5, 4.10 (`SessionEngine`), **5.2 (normativ)**
- **Exklusive Dateien:** `ios/Planktrainer/Core/Session/SessionEngine.swift`, `ios/PlanktrainerTests/Session/SessionEngineTests.swift`, `ios/PlanktrainerTests/Session/SessionEngineFakes.swift`

**Schritte**
1. `SessionEngine` mit exakt der Signatur aus 4.10 und dem Verhalten aus 5.2 umsetzen. Keine SwiftUI-, UIKit- oder AVFoundation-Abhängigkeit (nur `Foundation`, `Observation`).
2. Fakes in `SessionEngineFakes.swift`:
   - `final class TestSessionClock: SessionClock` mit `origin = ContinuousClock.now`, `offset: Duration`, `baseDate: Date`, `now = origin.advanced(by: offset)`, `currentDate = baseDate.addingTimeInterval(Double(offset.components.seconds))`, `func advance(by: Duration)`.
   - `final class FakeAnnouncer: Announcing`: zeichnet `spoken: [String]`, `stopCount`, `prepareCount` auf; `prepareError`/`speakError: AnnouncerError?` lösen Fehler aus.
   - `final class FakePlanner: AnnouncementPlanning`: liefert konfigurierbare Listen, zeichnet alle `AnnouncementPlanInput` und `ClosingInput` auf; Standard: Vorbereitung wie 5.1, Resume-Countdown wie 5.1, `plan` → `[(e0, .start/.resume, "A<e0>")]` plus konfigurierbare Zusatz-Einträge, `closingText` → `"END"`.
   - Hilfsfunktion `advance(_ engine:, _ clock:, seconds:)`, die in 100-ms-Schritten vorrückt und jeweils `tick()` aufruft.
3. Tests schreiben (unten).

**Akzeptanzkriterien**
- [ ] Alle Übergänge aus Spec 3.3 und Tabelle 5.2; unerlaubte Aktionen ändern nichts.
- [ ] Zeitmessung ausschließlich über `SessionClock` (monoton), nicht über das Zählen von Ticks (Spec 3.3).
- [ ] `achievedSeconds` = aktive Zeit ohne Pausen und Resume-Countdowns, abgerundet; „Ziel erreicht“ gegen `plannedSeconds` ohne Verlängerung.
- [ ] Fehler aus `Announcing` landen in `announcementError`, die Session läuft weiter (Spec 3.6).
- [ ] Keine Speicherung in der Engine (das macht die UI über `SessionStore`).

**Tests** (`TestSessionClock`, `FakeAnnouncer`, `FakePlanner`; Konfiguration 30 s Ziel, 5 s Vorbereitung, wenn nicht anders angegeben; Zeitangaben wie „bei 10 s“ meinen aktive Sekunden ab Beginn von `.running`)
1. `start()`: Phase `.preparing`, `prepareCount == 1`, „P“ sofort gesprochen, `preparationRemainingSeconds == 5`; nach 2 s „3“ gesprochen und Haptik `.countdownTick`; nach 5 s Phase `.running`, Haptik `.runningStarted`, Start-Satz gesprochen, Planer-Eingabe mit Trigger `.start`, `elapsedSeconds == 0`, `totalSeconds == 30`.
2. Fällige Ansagen: Planer liefert zusätzlich `(10, "B")`, `(20, "C")` → nach 10 s aktiver Zeit „B“ genau einmal gesprochen, nach 20 s „C“.
3. Veraltete Ansagen: `tick()` erst nach 15 s → „B“ (Sekunde 10) wird nicht gesprochen.
4. Abschluss: nach 30 s Phase `.finished(.completed)`, `result.achievedSeconds == 30`, `isGoalReached`, `closingText`-Eingabe korrekt, „END“ gesprochen, Haptik `.completed`, `startedAt`/`endedAt` aus der Uhr.
5. Pause/Resume: bei 10 s `pause()` → `.paused`, `stopCount` + 1, `pauseCount == 1`; 60 s vorrücken → `elapsedSeconds` bleibt 10, `remainingFraction()` unverändert; `resume()` → `.resuming`, „3“ sofort, nach 1 s „2“, nach 2 s „1“, nach 3 s `.running` mit Planer-Trigger `.resume` und `elapsedSeconds == 10`; Session endet 20 s später mit `achievedSeconds == 30`.
6. Stop vor Ziel: bei 12,7 s `stop()` → `.finished(.stopped)`, `achievedSeconds == 12`, `!isGoalReached`, `stopCount` erhöht vor dem Abschluss-Satz.
7. Stop nach Ziel in der Verlängerung: bei 25 s `extend()`, bei 35 s `stop()` → `achievedSeconds == 35`, `isGoalReached == true`, `extensionSeconds == 10`.
8. `extend()` in `.running`: `totalSeconds == 40`, Planer-Eingabe Trigger `.extended`, `elapsedSeconds` = aktueller Wert, `previous` = zuletzt gesprochene Ansage; es wird nichts sofort gesprochen.
9. `extend()` in `.paused`: `totalSeconds` erhöht, kein Planer-Aufruf bis zum Resume.
10. `cancel()` aus `.preparing`, `.running`, `.paused`, `.resuming` → `.cancelled`, `result == nil`, `stopCount` erhöht.
11. Unerlaubte Aktionen: `stop()` und `extend()` in `.preparing`, `resume()` in `.running`, `pause()` in `.paused`, alles nach `.finished` → keine Änderung.
12. Auto-Pause in der Vorbereitung: bei 2 s `pause()` → `.paused`; `resume()` → nach 3 s `.running` mit Trigger `.start` (erster Lauf), Haptik `.runningStarted`, `startedAt` gesetzt.
13. Rekord: `history.recordSeconds = 20`, Abschluss mit 30 → `isNewRecord == true`; `recordSeconds = 40` → `false`; `recordSeconds = nil` (erste Session) → `false`. `newRecordAlreadyAnnounced` ist `true`, wenn vorher ein Eintrag mit Art `.newRecord` gesprochen wurde.
14. Audio-Fehler: `prepareError = .unavailable` → `announcementError == .unavailable`, Session erreicht trotzdem `.running` und `.finished`; `speakError` nur für einen Text → nach dem nächsten erfolgreichen `speak` ist `announcementError == nil`.
15. `remainingFraction()`: 1 vor dem Lauf, 0,5 nach 15 s, 0 am Ende; `timerDisplay.isPaused` in `.paused` und `.resuming`.
16. Gesprochene Einmal-Ereignisse und letzte Lücken-Ansage werden beim Resume in `AnnouncementPlanInput.spokenOneOffs` bzw. `.lastGapAnnouncement` übergeben.
17. `run()`: nach `cancel()` kehrt `await engine.run()` sofort zurück (Phase ist terminal); ein in einem `Task` gestartetes `run()` endet nach `task.cancel()`.

**Commit (Vorschlag):** `feat(session): add session engine state machine`

#### W1-T5 – Sprachausgabe, Audio-Session, Unterbrechungen

- **Agent:** `swift-coding-agent` · Sonnet 5.5 · Effort Medium
- **Abhängigkeiten:** W0
- **Kontext:** Spec 3.6, 3.11, 4.2; Plan 3.4 (Ausnahme 2), 4.5, 4.10 (Services); Risiken R2–R4 (Abschnitt 9)
- **Exklusive Dateien:** `ios/Planktrainer/Services/{AudioSessionController,SpeechAnnouncer,AudioInterruptionMonitor}.swift`, `ios/Planktrainer/App/PlanktrainerApp.swift` (nur den Announcer tauschen), `ios/PlanktrainerTests/Services/SpeechAnnouncerTests.swift`, `ios/PlanktrainerTests/Services/AudioInterruptionMonitorTests.swift`

**Schritte**
1. `AudioSessionController` (`import AVFAudio`):
   - `configureForAnnouncements()`: `AVAudioSession.sharedInstance().setCategory(.playback, mode: .voicePrompt, options: [.duckOthers, .interruptSpokenAudioAndMixWithOthers])`.
   - `activate()`: `setActive(true)`.
   - `deactivate()`: `setActive(false, options: .notifyOthersOnDeactivation)`.
2. `SpeechAnnouncer: Announcing`:
   - Hält `AVSpeechSynthesizer` (Standard `usesApplicationAudioSession = true`) und ein privates `final class SpeechDelegateProxy: NSObject, AVSpeechSynthesizerDelegate` mit `AsyncStream<SpeechEvent>` (`enum SpeechEvent: Sendable { case finished, cancelled }`). Die Delegate-Methoden `didFinish`/`didCancel` sind `nonisolated` und rufen nur `continuation.yield` auf. Der Announcer liest den Stream in einem `Task` (mit `[weak self]`), der in `deinit`-freier Form beim Beenden des Streams endet.
   - `prepare()`: `configureForAnnouncements()`; Fehler → `os.Logger` (`subsystem: "de.liehrit.planktrainer", category: "audio"`) + `throw .unavailable`.
   - `speak(_:)`: Wenn die Session nicht aktiv ist: `activate()` (Fehler → loggen + `throw .unavailable`), Merker setzen. Utterance mit Stimme `AVSpeechSynthesisVoice(language: Self.voiceLanguage(appLanguage: locale.language.languageCode?.identifier ?? "en", systemVoiceLanguage: AVSpeechSynthesisVoice.currentLanguageCode()))`; Stimme und Tempo sonst Standard (Spec 3.6).
   - `stopSpeaking()`: `stopSpeaking(at: .immediate)`.
   - Auf `finished`/`cancelled`: wenn `!synthesizer.isSpeaking` → `deactivate()`; Fehler nur loggen (dokumentierte Ausnahme 2), Merker zurücksetzen.
   - `voiceLanguage`: beginnt `systemVoiceLanguage` mit `appLanguage + "-"` → `systemVoiceLanguage`, sonst `appLanguage`.
3. `AudioInterruptionMonitor`:
   - `interruption(from:)` liest `AVAudioSessionInterruptionTypeKey` (`UInt` → `AVAudioSession.InterruptionType`) und bei `.ended` `AVAudioSessionInterruptionOptionKey` (`.shouldResume`); sonst `nil`.
   - `interruptions()` liefert einen `AsyncStream`, der in einem `Task` über `NotificationCenter.default.notifications(named: AVAudioSession.interruptionNotification)` iteriert und `onTermination` den Task abbricht (kein Combine).
4. In `PlanktrainerApp.swift` ausschließlich `SilentAnnouncer()` durch `SpeechAnnouncer()` ersetzen.

**Akzeptanzkriterien**
- [ ] Kategorie `.playback`, Modus `.voicePrompt`, Optionen `.duckOthers` + `.interruptSpokenAudioAndMixWithOthers`; Aktivierung pro Ansage, Deaktivierung mit `.notifyOthersOnDeactivation` (Spec 3.6). HIG `playing-audio.md › Best practices`: „Let other apps know when your app finishes playing temporary audio.“
- [ ] Kein Hintergrund-Audio-Modus in `project.yml` (Auto-Pause statt Hintergrundbetrieb).
- [ ] Keine Strict-Concurrency-Warnungen (Delegate über Proxy, kein `@preconcurrency`-Workaround nötig).
- [ ] `PlanktrainerApp` nutzt `SpeechAnnouncer()`; sonst keine Änderung an der Datei.

**Tests**
- `SpeechAnnouncerTests` mit `FakeAudioSession: AudioSessionControlling` (in derselben Testdatei, Fehler konfigurierbar, Aufrufe gezählt): `prepare()` mit fehlschlagender Konfiguration wirft `.unavailable`; `speak` mit fehlschlagender Aktivierung wirft `.unavailable` und spricht nicht; `stopSpeaking()` ohne laufende Ausgabe ist folgenlos.
- `voiceLanguage`: `("de","de-AT") → "de-AT"`, `("de","en-US") → "de"`, `("en","en-GB") → "en-GB"`, `("en","de-DE") → "en"`.
- `AudioInterruptionMonitorTests`: `.began` aus `[AVAudioSessionInterruptionTypeKey: InterruptionType.began.rawValue]`; `.ended(shouldResume: true)` mit Options-Key `shouldResume`; `.ended(shouldResume: false)` ohne Options-Key; `nil` bei leerem `userInfo` und bei unbekanntem Wert.

**Commit (Vorschlag):** `feat(audio): add speech announcer and audio session handling`

#### W1-T6 – Session-Store und Verlaufs-Zusammenfassung

- **Agent:** `swift-coding-agent` · Sonnet 5.5 · Effort Medium
- **Abhängigkeiten:** W0
- **Kontext:** Spec 3.3 (Speichern, Rekord), 3.8, 3.9, 3.11, 4.4; Plan 3.4, 4.2, 4.10 (Persistenz)
- **Exklusive Dateien:** `ios/Planktrainer/Persistence/SessionStore.swift`, `ios/Planktrainer/Persistence/SessionHistorySummary.swift`, `ios/PlanktrainerTests/Persistence/SessionStoreTests.swift`, `ios/PlanktrainerTests/Persistence/SessionHistorySummaryTests.swift`

**Schritte**
1. `SessionStore.save(_:)`: `PlankSession(id: UUID(), startedAt:, endedAt:, preparationSeconds:, plannedSeconds:, extensionSeconds:, achievedSeconds:, pauseCount:)` aus `SessionResult` einfügen, `try context.save()`; bei Fehler `context.rollback()` und `throw .saveFailed`. Rückgabe des Modells.
2. `delete(_:)`: `context.delete`, `try context.save()`; bei Fehler `rollback()` und `throw .deleteFailed`.
3. `SessionHistorySummary(sessions:)`: Eingabe in beliebiger Reihenfolge.
   - `recordSeconds` = Maximum von `achievedSecondsValue` über alle Sessions mit `achievedSecondsValue > 0`; keine → `nil`.
   - `recordSessionID` = `idValue` der Session mit diesem Maximum; bei Gleichstand die mit dem frühesten `startedAtValue` (sie hat den Rekord zuerst aufgestellt).
   - `lastSession` = Session mit dem spätesten `startedAtValue`.
   - `engineContext` = `SessionHistoryContext(recordSeconds:, lastSession: lastSession.map { LastSessionInfo(achievedSeconds: $0.achievedSecondsValue, isGoalReached: $0.isGoalReached) })`.
   - `isRecord(_:)` = `recordSessionID == session.idValue`.
   - `secondsBelowRecord(_:)` = `recordSeconds − achieved`, `nil` ohne Rekord oder für die Rekord-Session; bei gleicher Zeit wie der Rekord (aber nicht die Rekord-Session) → `0`.

**Akzeptanzkriterien**
- [ ] Fehler werden typisiert geworfen, nicht gefangen und versteckt (Spec 3.11).
- [ ] Keine `??` außerhalb von `PlankSession+Values` (Standardwerte an einer Stelle).

**Tests** (je Test eigener In-Memory-Container)
- Speichern überträgt alle Felder; `id` ist gesetzt; zweimal speichern ergibt zwei Datensätze.
- Löschen entfernt genau den Datensatz.
- Summary: leere Liste → alles `nil`; Rekord = Maximum; Gleichstand → früheste Session; nur 0-Sekunden-Sessions → kein Rekord; `lastSession` unabhängig von der Eingabereihenfolge; `engineContext` mit `isGoalReached` korrekt; `secondsBelowRecord` (Rekord 90, Session 78 → 12; Rekord-Session → `nil`; gleiche Zeit, andere Session → 0).
- Rekord ergibt sich nach dem Löschen der Rekord-Session neu (Summary aus den verbleibenden Sessions).

**Commit (Vorschlag):** `feat(persistence): add session store and history summary`

#### W1-T7 – Zeit- und Datumsformatierung für die UI

- **Agent:** `swift-coding-agent` · Sonnet 5.5 · Effort Medium
- **Abhängigkeiten:** W0
- **Kontext:** Spec 3.2, 3.8, 3.9, 3.13; Design-Brief 5.4 („Heute, 07:42“); Plan 4.10 (`TimeText`)
- **Exklusive Dateien:** `ios/Planktrainer/Core/Formatting/TimeText.swift`, `ios/PlanktrainerTests/Formatting/TimeTextTests.swift`

**Schritte**
1. `clock(s)`: `s < 0` wie 0; `"\(s / 60):"` + Sekunden zweistellig (manuell, ohne `String(format:)`).
2. `accessibleDuration(s, locale:)`: `Duration.seconds(s).formatted(.units(allowed: [.minutes, .seconds], width: .wide).locale(locale))`.
3. `compactDuration(s, locale:)`: wie 2 mit `width: .abbreviated`.
4. `relativeDateTime(_:locale:timeZone:)`: `DateFormatter` mit `locale`, `timeZone`, `dateStyle = .short`, `timeStyle = .short`, `doesRelativeDateFormatting = true`.

**Tests**
- `clock`: `0→"0:00"`, `5→"0:05"`, `59→"0:59"`, `60→"1:00"`, `90→"1:30"`, `600→"10:00"`, `-3→"0:00"`.
- `accessibleDuration` en 90 enthält „minute“ und „30“; de 90 enthält „Minute“ und „30“; en 45 enthält „45“ und „second“. (Nur `contains`, weil Foundation-Ausgaben je nach OS-Version leicht variieren.)
- `compactDuration` en 12 enthält „12“; de 72 enthält „1“ und „12“.
- `relativeDateTime(Date.now, de)` enthält „Heute“; en enthält „Today“; ein Datum vor 30 Tagen enthält keines der beiden Wörter.

**Commit (Vorschlag):** `feat(core): add time and date text formatting`

#### W1-T8 – Fortschrittsring (gemeinsame UI-Komponente)

- **Agent:** `swift-coding-agent` · Sonnet 5.5 · Effort Medium
- **Abhängigkeiten:** W0
- **Kontext:** Spec 3.3 (Ring), 3.9, 3.13; Design-Brief 4; Plan 3.3, 4.9, 4.10 (`ProgressRing`)
- **Exklusive Dateien:** `ios/Planktrainer/DesignSystem/ProgressRing.swift`

**Schritte**
1. `ProgressRing` wie in 4.10: Hintergrundspur (`ThemeColor.ringTrack`) und Fortschrittsbogen (`ThemeColor.accent`), Start oben (12 Uhr), Bogenlänge = `fraction` (auf `0...1` begrenzt), runde Enden, Strichstärke `RingMetrics.lineWidthRatio × Durchmesser`. Durchmesser über `GeometryReader`: `.session` = `sessionDiameterRatio × Breite`, `.detail` = `detailDiameterRatio × Breite`, `.compact` = `compactDiameter`.
2. `isPaused`: Bogen in `ThemeColor.paused` **und** gestrichelt (`StrokeStyle(dash:)`), damit der Zustand nicht nur über Farbe erkennbar ist. `isHighlighted` (letzte 5 s): Strichstärke × 1,15.
3. Keine eigene Animation; der Aufrufer liefert pro Frame einen neuen Wert (TimelineView). `.accessibilityHidden(true)`, weil Aufrufer Ring und Zeit zu einem Element zusammenfassen.
4. `#Preview` mit 1,0 / 0,5 / 0,1, pausiert, hervorgehoben, Hell/Dunkel.

**Akzeptanzkriterien**
- [ ] Nur Theme-Tokens, keine festen Farben/Größen.
- [ ] HIG `progress-indicators.md › Best practices`: „Be as accurate as possible when reporting advancement in a determinate progress indicator.“ – der Bogen entspricht exakt `fraction`.
- [ ] HIG `accessibility.md › Vision`: „Convey information with more than color alone.“ – Pausenzustand zusätzlich gestrichelt.
- [ ] HIG `color.md › Best practices`: „Make sure all your app’s colors work well in light, dark, and increased contrast contexts.“ – nur dynamische Systemfarben.

**Tests:** keine (reine Darstellung); Abnahme über Build, Preview und Review.
**Commit (Vorschlag):** `feat(ui): add progress ring component`

### Welle 2 – Screens (parallel, Arbeitskopien, designunabhängig über Platzhalter-Tokens)

Gemeinsame Vorbedingung: W1 abgenommen. Gemeinsame Regeln für alle W2-Aufgaben:
- Styling nur über Tokens (4.9) und Systemkomponenten; Texte nur aus der eigenen Tabelle plus lesend aus `Common`/`Coach`/`Errors`.
- Jede View hat `#Preview { PreviewHost { … } }`, zusätzlich eine Preview mit `.environment(\.dynamicTypeSize, .accessibility3)` und eine mit `.preferredColorScheme(.dark)`.
- Allgemeine HIG-Kriterien (gelten für jede W2-Aufgabe):
  - `typography.md › Supporting Dynamic Type`: „Make sure your app’s layout adapts to all font sizes.“ und „Keep text truncation to a minimum as font size increases.“ – geprüft mit AX3-Preview; horizontale Anordnungen wechseln bei `dynamicTypeSize.isAccessibilitySize` in vertikale (`layout.md › Adaptability`: „horizontally adjacent views may need to stack vertically“).
  - `accessibility.md › Mobility`: „Offer sufficiently sized controls.“ – Trefferflächen ≥ 44 × 44 pt (`ThemeSize.minimumTapTarget`).
  - `accessibility.md › Vision`: „Convey information with more than color alone.“ – jeder Status hat Symbol **und** Text bzw. Accessibility-Label.
  - `color.md › System colors`: „Avoid hard-coding system color values in your app.“ – nur Tokens.
  - `dark-mode.md › Dark Mode colors`: „Embrace colors that adapt to the current appearance.“ und `dark-mode.md › Text`: „Use the system-provided label colors for labels.“
  - `designing-for-ios.md › Best practices`: Steuerelemente für die Hauptaufgabe „in the middle or bottom area of the display“.
  - VoiceOver: jedes Bedienelement hat ein sprechendes Label; zusammengehörige Werte werden mit `.accessibilityElement(children: .combine)` oder explizitem Label/Wert zusammengefasst.

#### W2-T1 – Training-Tab

- **Agent:** `swift-coding-agent` · Sonnet 5.5 · Effort Medium
- **Abhängigkeiten:** W1 (`UserSettings`, `SessionHistorySummary`, `TimeText`, `AppRouter`)
- **Kontext:** Spec 3.1, 3.2, 3.13; Design-Brief 5.2; Plan 3.2, 3.3, 4.6, 4.7, 4.10
- **Exklusive Dateien:** Ordner `ios/Planktrainer/Features/Training/` (ersetzt `TrainingScreen.swift`, weitere Dateien nur in diesem Ordner), `ios/Planktrainer/Resources/Localization/Training.xcstrings`, `ios/PlanktrainerTests/Features/TrainingTextsTests.swift`

**Texte (Training-Tabelle)**

| Schlüssel | en | de |
|---|---|---|
| `training.title` | Training | Training |
| `training.summary.record %@` | Record %@ | Rekord %@ |
| `training.summary.last %@ %@` | Last: %1$@, %2$@ | Zuletzt: %1$@, %2$@ |
| `training.sessionTime.header` | Session Time | Session-Zeit |
| `training.minutes` | Minutes | Minuten |
| `training.seconds` | Seconds | Sekunden |
| `training.minutes.unit` | min | min |
| `training.seconds.unit` | s | s |
| `training.preparation` | Preparation | Vorbereitung |
| `training.preparation.value %lld` | %lld s | %lld s |
| `training.start` | Start Session | Session starten |
| `training.start.hint` | Starts the preparation countdown. | Startet den Vorbereitungs-Countdown. |

**Schritte**
1. `TrainingScreen`: `Form` mit `.navigationTitle` (`training.title`), Inhalt von oben nach unten (Spec 3.2):
   1. Abschnitt Rekord/letzte Session – nur wenn `SessionHistorySummary(sessions:)` einen Rekord oder eine letzte Session hat (`@Query` aller Sessions). Rekord: `training.summary.record` mit `TimeText.clock`. Letzte: `training.summary.last` mit `TimeText.relativeDateTime` und `TimeText.clock(achieved)`, dazu Symbol `checkmark.circle.fill` (`ThemeColor.success`) bzw. `xmark.circle` (`ThemeColor.contentSecondary`) mit Accessibility-Label `common.goalReached`/`common.goalMissed`.
   2. Abschnitt Session-Zeit: zwei `Picker` mit `.pickerStyle(.wheel)` nebeneinander (Minuten `0...10`, Sekunden `0, 5, …, 55`), Einheiten-Labels daneben, Accessibility-Labels `training.minutes`/`training.seconds`. Startwerte aus `userSettings.lastConfiguration`.
   3. Vorbereitungszeile: Button-Zeile mit `training.preparation` und Wert `training.preparation.value`; Antippen klappt inline einen dritten Wheel-Picker (`5…60` in 5er-Schritten) auf/zu. Accessibility: Wert und `.accessibilityAddTraits(.isButton)`, Zustand „ausgeklappt“ über `.accessibilityValue`.
2. Normalisierung: Bei jeder Änderung der Räder `SessionConfiguration(plannedSeconds: m * 60 + s, preparationSeconds: p)` bilden; weicht das Ergebnis ab (z. B. 10:30 → 10:00, 0:05 → 0:10), die Räder auf die normalisierten Werte setzen (nur bei Abweichung, keine Schleifen).
3. Start-Button in `.safeAreaInset(edge: .bottom)`: `training.start`, `.buttonStyle(.borderedProminent)`, `.controlSize(.extraLarge)`, volle Breite, `.accessibilityHint(training.start.hint)`. Aktion: `userSettings.rememberConfiguration(config)`, `router.present(.activeSession(config))`.
4. Aufklapp-Animation nur, wenn `accessibilityReduceMotion == false`.

**Akzeptanzkriterien (inkl. HIG)**
- [ ] Reihenfolge und Inhalt wie Spec 3.2; beim ersten Start kein Rekord-/Zuletzt-Abschnitt.
- [ ] HIG `pickers.md › Best practices`: „Avoid switching views to show a picker. A picker works well when displayed in context, below or in proximity to the field people are editing.“ – Vorbereitungs-Picker klappt inline unter der Zeile auf, kein Sheet.
- [ ] HIG `pickers.md › Best practices`: „Use predictable and logically ordered values.“ – aufsteigende Werte in 5er-Schritten.
- [ ] HIG `layout.md › Visual hierarchy`: „Use progressive disclosure to make layouts cleaner and easier to interact with.“ – Vorbereitung standardmäßig eingeklappt.
- [ ] HIG `color.md › Liquid Glass color`: „Refrain from adding color to the background of multiple controls.“ – nur der Start-Button ist prominent eingefärbt.
- [ ] HIG `designing-for-ios.md › Best practices`: Start-Button im unteren Daumenbereich.
- [ ] Ungültige Kombinationen werden korrigiert (10:30 → 10:00, 0:00/0:05 → 0:10).
- [ ] Beim Start werden beide Zeiten als neue Standardwerte gespeichert (Spec 3.2).

**Tests:** `TrainingTextsTests` – alle Schlüssel der Training-Tabelle lösen in `de` und `en` zu Text ≠ Schlüssel auf (`L10n.string`).
**Commit (Vorschlag):** `feat(training): add training tab with time pickers`

#### W2-T2 – Verlauf-Tab (Diagramm, Liste, Leerzustand, Löschen)

- **Agent:** `swift-coding-agent` · Sonnet 5.5 · Effort Medium
- **Abhängigkeiten:** W1 (`SessionStore`, `SessionHistorySummary`, `TimeText`)
- **Kontext:** Spec 3.1, 3.8, 3.11, 3.13; Design-Brief 5.4; Plan 3.4, 4.6, 4.10
- **Exklusive Dateien:** Ordner `ios/Planktrainer/Features/History/` (ersetzt `HistoryScreen.swift`), `ios/Planktrainer/Resources/Localization/History.xcstrings`, `ios/PlanktrainerTests/Features/HistoryTextsTests.swift`, `ios/PlanktrainerTests/Features/HistoryChartDataTests.swift`

**Texte (History-Tabelle)**

| Schlüssel | en | de |
|---|---|---|
| `history.title` | History | Verlauf |
| `history.chart.title` | Last 30 Sessions | Letzte 30 Sessions |
| `history.chart.summary %@` | Your record: %@ | Dein Rekord: %@ |
| `history.chart.axis.session` | Session | Session |
| `history.chart.axis.time` | Time | Zeit |
| `history.row.result %@ %@` | %1$@ / %2$@ | %1$@ / %2$@ |
| `history.row.accessibility %@ %@ %@` | %1$@, %2$@ of %3$@ | %1$@, %2$@ von %3$@ |
| `history.empty.title` | No Sessions Yet | Noch keine Sessions |
| `history.empty.message` | Your sessions and records will appear here. | Hier erscheinen deine Sessions und Rekorde. |
| `history.empty.action` | Start First Session | Erste Session starten |
| `history.deleteError.title` | Couldn't Delete | Löschen fehlgeschlagen |

**Schritte**
1. `HistoryScreen`: `@Query(sort: \PlankSession.startedAt, order: .reverse)`; `SessionHistorySummary` daraus.
2. Leer → `ContentUnavailableView` mit Symbol `figure.core.training`, `history.empty.title`, `history.empty.message` und Button `history.empty.action` (`.borderedProminent`), Aktion `router.selectedTab = .training`.
3. Sonst `List`:
   - Abschnitt Diagramm: Überschrift `history.chart.title`, Zusammenfassung `history.chart.summary` mit Rekordzeit; Swift-Charts-`Chart` mit `BarMark` je Session (die letzten 30 in zeitlicher Reihenfolge, x = laufende Nummer, y = erreichte Sekunden), `RuleMark(y:)` beim Rekord mit Annotation `common.record`. Erreichte Ziele: `ThemeColor.success` **und** Symbol-Annotation `checkmark` über dem Balken; verfehlte: `ThemeColor.contentSecondary` ohne Symbol. Y-Achse mit `TimeText.clock`. Pro Balken `.accessibilityLabel(TimeText.relativeDateTime)` und `.accessibilityValue` („1:30 von 1:30, Ziel erreicht“ über `history.row.accessibility`-Logik bzw. `accessibleDuration`). Höhe ca. 200 pt über `ThemeSpacing`-Vielfache.
   - Datenaufbereitung als reine Funktion `HistoryChartData.points(from sessions: [PlankSession]) -> [HistoryChartPoint]` (eigene Datei im Ordner; `struct HistoryChartPoint: Identifiable { let id: UUID; let index: Int; let achievedSeconds: Int; let plannedSeconds: Int; let isGoalReached: Bool; let startedAt: Date }`), damit sie testbar ist.
   - Abschnitt Liste: `ForEach` mit `NavigationLink(value: Route.sessionDetail(session.idValue))`; Zeile: `TimeText.relativeDateTime`, `history.row.result` (erreicht / Ziel mit `TimeText.clock`), Status-Symbol wie W2-T1, Rekord-Markierung (`trophy.fill` + Text `common.record`) bei `summary.isRecord`. Zeile als ein VoiceOver-Element mit Label aus Datum, Ergebnis, Status, ggf. „Rekord“. Bei Accessibility-Textgrößen Datum oben, Werte darunter.
   - `.onDelete`: `try SessionStore(context: modelContext).delete(session)`; Fehler → `.alert` (`history.deleteError.title`, Meldung `error.localizedDescription`, Button `common.ok`). Keine Rückfrage (Spec 3.8).
   - Toolbar: `EditButton()` (nur wenn nicht leer).

**Akzeptanzkriterien (inkl. HIG)**
- [ ] Inhalt und Verhalten wie Spec 3.8; Rekord ergibt sich nach dem Löschen neu (automatisch über `@Query`).
- [ ] HIG `charting-data.md › Best practices`: „Make every chart in your app accessible.“ – jeder Balken hat Label und Wert; die Rekordlinie ist beschriftet.
- [ ] HIG `charting-data.md › Designing effective charts`: „In general, prefer using common chart types.“ (Balken + Linie) und „Aid comprehension by adding descriptive text to the chart.“ (Titel + Rekord-Zusammenfassung).
- [ ] HIG `charting-data.md › Best practices`: „Keep a chart simple, letting people choose when they want additional details.“ – keine Interaktion, Details über die Liste.
- [ ] HIG `accessibility.md › Vision`: Ziel erreicht über Farbe **und** Symbol (Spec 3.8).
- [ ] HIG `color.md › Best practices`: „Avoid using the same color to mean different things.“ – `success` bedeutet überall „Ziel erreicht“.
- [ ] HIG `lists-and-tables.md › Mobile`: „If you need to let people drill into a list or table row’s subviews, use a disclosure indicator accessory control.“ – `NavigationLink` mit Chevron.
- [ ] HIG `tab-bars.md › Best practices`: „If a section is empty, explain why its content is unavailable.“ – `ContentUnavailableView` mit Aktion.
- [ ] HIG `feedback.md › Best practices`: „don’t warn people when data loss is the expected result of their action“ – Löschen ohne Rückfrage; HIG `accessibility.md › Mobility`: „Offer alternatives to gestures.“ – `EditButton` als Alternative zum Wischen.
- [ ] Löschfehler erscheinen als Alert (Spec 3.11).

**Tests**
- `HistoryChartDataTests`: 35 Sessions → 30 Punkte, älteste zuerst, Indizes 0…29, nur die neuesten 30; leere Eingabe → leer; `isGoalReached` übernommen.
- `HistoryTextsTests`: alle Schlüssel in `de`/`en`.

**Commit (Vorschlag):** `feat(history): add history tab with chart, list and delete`

#### W2-T3 – Session-Detail

- **Agent:** `swift-coding-agent` · Sonnet 5.5 · Effort Medium
- **Abhängigkeiten:** W1 (`ProgressRing`, `SessionHistorySummary`, `TimeText`, `UserSettings`)
- **Kontext:** Spec 3.9, 3.13; Design-Brief 5.5; Plan 4.2 (`PlankSession+Values`), 4.6, 4.8, 4.10
- **Exklusive Dateien:** Ordner `ios/Planktrainer/Features/SessionDetail/` (ersetzt `SessionDetailScreen.swift`), `ios/Planktrainer/Resources/Localization/SessionDetail.xcstrings`, `ios/PlanktrainerTests/Features/SessionDetailTextsTests.swift`

**Texte (SessionDetail-Tabelle)**

| Schlüssel | en | de |
|---|---|---|
| `detail.ring.label` | Achieved time | Erreichte Zeit |
| `detail.ring.value %@ %@` | %1$@ of %2$@ | %1$@ von %2$@ |
| `detail.date` | Date | Datum |
| `detail.preparation` | Preparation | Vorbereitung |
| `detail.pauses` | Pauses | Pausen |
| `detail.extension` | Extension | Verlängerung |
| `detail.recordGap` | Compared to Record | Abstand zum Rekord |
| `detail.recordGap.below %@` | %@ below your record | %@ unter deinem Rekord |
| `detail.repeat` | Repeat with Same Time | Nochmal mit gleicher Zeit |
| `detail.notFound.title` | Session Not Found | Session nicht gefunden |

**Schritte**
1. `SessionDetailScreen` mit `init(sessionID: UUID)`, `@Query(filter: #Predicate<PlankSession> { $0.id == id })` (mit `let id: UUID? = sessionID`) und einem zweiten `@Query` aller Sessions für den Rekord.
2. Nicht gefunden (z. B. gelöscht) → `ContentUnavailableView` mit `detail.notFound.title`.
3. Sonst `List`: oben `ProgressRing(fraction: min(1, achieved / planned), style: .detail)` mit `TimeText.clock(achieved)` (`.scaledTimeFont(.detail)`) in der Mitte; Ring + Zeit als ein Accessibility-Element (`detail.ring.label`, Wert `detail.ring.value` mit `accessibleDuration` + Status-Text). Darunter `LabeledContent`-Zeilen: Datum (`relativeDateTime`), Ziel (`common.goal`), Erreicht (`common.achieved`), Vorbereitung, Pausen, Verlängerung (`TimeText.compactDuration`), Abstand zum Rekord: `common.record` bei Rekord-Session bzw. `detail.recordGap.below` mit `compactDuration`. Status „Ziel erreicht/nicht erreicht“ mit Symbol.
4. `.navigationTitle` = relatives Datum, `.navigationBarTitleDisplayMode(.inline)`.
5. Button `detail.repeat` in `.safeAreaInset(edge: .bottom)`, `.borderedProminent`, `.controlSize(.extraLarge)`; Aktion: `userSettings.rememberConfiguration(session.configuration)`, `router.present(.activeSession(session.configuration))`.
6. Kein Bearbeiten, kein Löschen (Spec 3.9).

**Akzeptanzkriterien (inkl. HIG)**
- [ ] Alle Werte aus Spec 3.9; nur `…Value`-Zugriffe, kein `??` in der View.
- [ ] HIG `layout.md › Visual hierarchy`: „Order content by relative importance.“ – Ring und Ergebnis oben, Details darunter.
- [ ] HIG `layout.md › Visual hierarchy`: „Group related items to clearly express related information or functions.“ – Werte gruppiert in einer Liste.
- [ ] HIG `progress-indicators.md › Best practices`: Ring zeigt den Anteil exakt; voller Ring = geschafft.
- [ ] VoiceOver liest Ring als „Erreichte Zeit, 1 Minute 30 Sekunden von 2 Minuten, Ziel nicht erreicht“.

**Tests:** `SessionDetailTextsTests` – alle Schlüssel in `de`/`en`.
**Commit (Vorschlag):** `feat(history): add session detail screen`

#### W2-T4 – Session-Vollbild: Ablauf, Steuerung, Lebenszyklus

- **Agent:** `swift-coding-agent` · Sonnet 5.5 · Effort Medium
- **Abhängigkeiten:** W1 (`SessionEngine`, `AnnouncementPlanner`, `AnnouncementTexts`, `PhraseSelector`, `SplitMix64`, `AudioInterruptionMonitor`, `SessionStore`, `SessionHistorySummary`); Anzeige-Views von W2-T5 existieren als Platzhalter (4.8)
- **Kontext:** Spec 3.3, 3.6, 3.7, 3.11, 3.13; Design-Brief 5.3; Plan 3.4, 4.6, 4.8, 4.10, 5.2; Risiken R2–R6
- **Exklusive Dateien:** `ios/Planktrainer/Features/ActiveSession/ActiveSessionScreen.swift` (ersetzt Platzhalter), `ios/Planktrainer/Features/ActiveSession/ActiveSessionContent.swift`, `ios/Planktrainer/Features/ActiveSession/SessionControlsView.swift`, `ios/Planktrainer/Features/ActiveSession/AnnouncementNoticeView.swift`, `ios/Planktrainer/Features/ActiveSession/SessionHaptic+Feedback.swift`, `ios/Planktrainer/Resources/Localization/ActiveSession.xcstrings`, `ios/PlanktrainerTests/Features/ActiveSessionTextsTests.swift`, `ios/PlanktrainerTests/Features/SessionHapticFeedbackTests.swift`

**Texte (ActiveSession-Tabelle)**

| Schlüssel | en | de |
|---|---|---|
| `active.cancel` | Cancel | Abbrechen |
| `active.pause` | Pause | Pause |
| `active.resume` | Resume | Weiter |
| `active.stop` | Stop | Stop |
| `active.stop.hint` | Ends the session and saves it. | Beendet die Session und speichert sie. |
| `active.extend` | +10 s | +10 s |
| `active.extend.accessibility` | Add 10 seconds | 10 Sekunden hinzufügen |
| `active.prepare.caption` | Get ready | Mach dich bereit |
| `active.resuming.caption` | Get back into position | Gleich geht's weiter |
| `active.discard.title` | Discard Session? | Session verwerfen? |
| `active.discard.message` | This session won't be saved. | Diese Session wird nicht gespeichert. |
| `active.discard.confirm` | Discard | Verwerfen |
| `active.discard.keep` | Keep Planking | Weiter planken |
| `active.saveError.title` | Couldn't Save | Speichern fehlgeschlagen |

**Schritte**
1. `ActiveSessionScreen(configuration:)`: liest `AppEnvironment`, `AppRouter`, `@Query` aller Sessions, `modelContext`. Erzeugt die Engine **einmal** beim ersten Erscheinen (`@State private var engine: SessionEngine?`, in `.onAppear` falls `nil`):

```swift
let locale = AppLocale.current
SessionEngine(
    configuration: configuration,
    history: SessionHistorySummary(sessions: sessions).engineContext,
    coachStyle: settings.coachStyle,
    postureHintsEnabled: settings.postureHintsEnabled,
    announcer: appEnvironment.announcer,
    planner: AnnouncementPlanner(
        texts: AnnouncementTexts(locale: locale),
        coach: PhraseSelector(locale: locale, generator: SplitMix64(seed: UInt64.random(in: .min ... .max)))
    ),
    clock: SystemSessionClock()
)
```

2. `ActiveSessionContent(engine:)` (bekommt die Engine als `let`):
   - `.task { engine.start(); await engine.run() }`.
   - `.task { for await event in AudioInterruptionMonitor.interruptions() { if event == .began { engine.pause() } } }` – kein automatisches Weiter bei `.ended` (Spec 3.3).
   - `@Environment(\.scenePhase)`: `.onChange` → bei `.background` `engine.pause()` (nicht bei `.inactive`).
   - Display an: `.onAppear { UIApplication.shared.isIdleTimerDisabled = true }`, `.onDisappear { … = false }` (`import UIKit` nur dafür).
   - Haptik: `.sensoryFeedback(trigger: engine.hapticSignal) { _, signal in … }` – nur wenn `userSettings.hapticsEnabled`; Abbildung in `SessionHaptic+Feedback.swift`: `extension SessionHaptic { var feedback: SensoryFeedback }` mit `.countdownTick → .impact(weight: .light)`, `.runningStarted → .impact(weight: .medium)`, `.completed → .success` (Spec 3.7).
   - Inhalt nach Phase: `.preparing` → `SessionCountdownView(value: engine.preparationRemainingSeconds, caption: LocalizedStringResource("active.prepare.caption", table: LocalizationTable.activeSession.rawValue))`; `.running`/`.paused` → `SessionTimerView(display: engine.timerDisplay, remainingFraction: { engine.remainingFraction() })`; `.resuming` → `SessionTimerView` mit darübergelegtem `SessionCountdownView(value: engine.resumeCountdownRemainingSeconds, caption: LocalizedStringResource("active.resuming.caption", table: LocalizationTable.activeSession.rawValue))` (Hintergrund `ThemeColor.surface` mit Deckkraft, kein Glass-Effekt im Inhalt); `.finished` → `SessionResultView(result:onDone:)` mit `onDone: router.dismissFullScreen`; `.cancelled` → `router.dismissFullScreen()` über `.onChange(of: engine.phase)`.
   - Oben: Button `active.cancel` (sekundär, `.bordered`) in allen nicht-terminalen Phasen. In `.preparing` bricht er **ohne Rückfrage** ab; sonst öffnet er `confirmationDialog` (`active.discard.title`, Nachricht, `active.discard.confirm` mit `role: .destructive` → `engine.cancel()`, `active.discard.keep` mit `role: .cancel`). Wird die Phase terminal, während der Dialog offen ist, Dialog schließen.
   - Unten `SessionControlsView(engine:)`: `.running` → primär `active.pause` (`pause.fill`), sekundär `active.extend` (`plus`) und `active.stop` (`stop.fill`); `.paused` → primär `active.resume` (`play.fill`), sekundär `active.extend`, `active.stop`; sonst keine. Primär: `.borderedProminent`, sekundär `.bordered`; Höhe ≥ `ThemeSize.sessionControlHeight`, Abstand `ThemeSize.sessionControlSpacing`, volle Breite; Labels mit Symbol **und** Text.
   - `AnnouncementNoticeView`: zeigt bei `engine.announcementError != nil` einen nicht-blockierenden Hinweis (Symbol `speaker.slash` + `error.localizedDescription`) unter dem Abbrechen-Button; kein Auto-Ausblenden. Beim Erscheinen `AccessibilityNotification.Announcement(text).post()`.
   - Speichern: `.onChange(of: engine.result)` → `do { try SessionStore(context: modelContext).save(result) } catch { saveError = error }`; `.alert` mit `active.saveError.title`, `error.localizedDescription`, Button `common.ok`. Danach bleibt der Ergebnis-Screen sichtbar.
3. Hintergrund `ThemeColor.surface`, `.ignoresSafeArea()` nur für den Hintergrund; Inhalte respektieren Safe Areas.

**Akzeptanzkriterien (inkl. HIG)**
- [ ] Alle Zustände, Regeln und Bedienungen aus Spec 3.3; Auto-Pause bei Hintergrund und Audio-Unterbrechung; Weiter nur per Button.
- [ ] Speichern beim Übergang nach `finished`, Fehler als Alert im Ergebnis-Screen (Spec 3.3, 3.11).
- [ ] Display bleibt an, solange das Vollbild offen ist; wird beim Schließen zurückgesetzt (Spec 3.3).
- [ ] Haptik nur bei aktivierter Einstellung (Spec 3.7); HIG `playing-haptics.md › Best practices`: „Make haptics optional.“ und „Use system-provided haptic patterns according to their documented meanings.“ (`success` nur für das Ergebnis „geschafft“).
- [ ] HIG `modality.md › Best practices`: „Always give people an obvious way to dismiss a modal view.“ (Abbrechen oben, Fertig im Ergebnis) und „When necessary, help people avoid data loss by getting confirmation before closing a modal view.“ (`confirmationDialog` außer in der Vorbereitung).
- [ ] HIG `progress-indicators.md › Best practices`: „When it’s feasible, let people halt processing. … it can be useful to provide a Pause button in addition to a Cancel button.“ und „Let people know when halting a process has a negative consequence.“
- [ ] HIG `feedback.md › Best practices`: „Consider integrating status feedback into your interface.“ – Audio-Hinweis inline statt Alert; „Use alerts to deliver critical — and ideally actionable — information.“ – nur der Speicherfehler ist ein Alert.
- [ ] HIG `modality.md › Best practices`: „Let people dismiss a modal view before presenting another one.“ – nie Dialog und Alert gleichzeitig.
- [ ] HIG `accessibility.md › Mobility`: „Consider spacing between controls as important as size.“ – Session-Buttons ≥ 72 pt hoch, ≥ 24 pt Abstand; Stop (speichern, `stop.fill`, unten) und Abbrechen (verwerfen, oben, Rückfrage) sind nach Ort, Symbol und Text unterscheidbar (Design-Brief 5.3).
- [ ] HIG `accessibility.md › Hearing`: „Use haptics in addition to audio cues.“ und „Augment audio cues with visual cues.“ – jeder gesprochene Countdown ist sichtbar und fühlbar.
- [ ] HIG `accessibility.md › Cognitive`: „Minimize use of time-boxed interface elements.“ – Ergebnis und Hinweise verschwinden nicht automatisch.
- [ ] HIG `playing-audio.md › Handling interruptions`: „When an interruption ends, determine whether to resume audio playback automatically.“ – bewusst kein automatisches Weiter.

**Tests**
- `SessionHapticFeedbackTests`: Abbildung der drei Fälle auf `SensoryFeedback` (`#expect(SessionHaptic.completed.feedback == .success)` usw.).
- `ActiveSessionTextsTests`: alle Schlüssel in `de`/`en`.

**Commit (Vorschlag):** `feat(session): add active session screen with controls and lifecycle`

#### W2-T5 – Session-Anzeige: Countdown, Timer-Ring, Ergebnis

- **Agent:** `swift-coding-agent` · Sonnet 5.5 · Effort Medium
- **Abhängigkeiten:** W1 (`ProgressRing`, `TimeText`)
- **Kontext:** Spec 3.3 (Anzeige-Spalte), 3.13; Design-Brief 4, 5.3; Plan 4.3 (`SessionTimerDisplay`, `SessionResult`), 4.8, 4.9
- **Exklusive Dateien:** `ios/Planktrainer/Features/ActiveSession/SessionCountdownView.swift`, `SessionTimerView.swift`, `SessionResultView.swift` (ersetzen Platzhalter, Signaturen aus 4.8 unverändert), `ios/Planktrainer/Resources/Localization/SessionDisplay.xcstrings`, `ios/PlanktrainerTests/Features/SessionDisplayTextsTests.swift`

**Texte (SessionDisplay-Tabelle)**

| Schlüssel | en | de |
|---|---|---|
| `display.paused` | Paused | Pausiert |
| `display.remaining` | Remaining time | Restzeit |
| `display.elapsed %@` | %@ elapsed | %@ vergangen |
| `display.extended %@` | Extended by %@ | Verlängert um %@ |
| `display.countdown.accessibility %lld` | Starting in %lld | Start in %lld |
| `display.result.goal %@` | Goal: %@ | Ziel: %@ |
| `display.result.done` | Done | Fertig |

**Schritte**
1. `SessionCountdownView(value:caption:)`: sehr große Zahl (`.scaledTimeFont(.countdown)`, `Text(verbatim:)`), darunter `caption` (`ThemeFont.sessionCaption`). Accessibility: ein Element, Label `caption`, Wert `display.countdown.accessibility`; `.accessibilityAddTraits(.updatesFrequently)`. Zahlwechsel ohne Animation bei „Bewegung reduzieren“, sonst `.contentTransition(.numericText())`.
2. `SessionTimerView(display:remainingFraction:)`:
   - `TimelineView`: bei `accessibilityReduceMotion == false` `.animation(paused: display.isPaused)`, sonst `.periodic(from: .now, by: 1)`; Fraktion bei reduzierter Bewegung = `Double(display.remainingSeconds) / Double(display.totalSeconds)` (sekundenweise Sprünge, Spec 3.13), sonst `remainingFraction()`.
   - `ProgressRing(fraction:, style: .session, isPaused: display.isPaused, isHighlighted: display.isFinalCountdown)`; in der Mitte Restzeit `TimeText.clock(display.remainingSeconds)` mit `.scaledTimeFont(.session)`, darunter klein `display.elapsed` mit `TimeText.clock(display.elapsedSeconds)`.
   - Pausiert: zusätzlich Symbol `pause.circle.fill` + Text `display.paused` (nicht nur Farbe/Strichart).
   - Verlängert (`extensionSeconds > 0`): Hinweis `display.extended` mit `TimeText.compactDuration`.
   - Accessibility: Ring + Zeiten als ein Element, Label `display.remaining`, Wert `TimeText.accessibleDuration(display.remainingSeconds)` (+ „Pausiert“), `.updatesFrequently` (Spec 3.13: „der Ring meldet die Restzeit als Wert“).
3. `SessionResultView(result:onDone:)`: erreichte Zeit groß (`.scaledTimeFont(.result)`), `display.result.goal` mit `TimeText.clock(plannedSeconds)`, Status `common.goalReached`/`common.goalMissed` mit Symbol (`checkmark.circle.fill`/`xmark.circle`), bei `isNewRecord` `common.newRecord` mit `trophy.fill`; ein orchestrierter Moment: `.symbolEffect(.bounce, value:)` auf dem Status-Symbol nur ohne „Bewegung reduzieren“. Button `display.result.done` (`.borderedProminent`, `.controlSize(.extraLarge)`, volle Breite, unten) ruft `onDone`.

**Akzeptanzkriterien (inkl. HIG)**
- [ ] Anzeige je Zustand wie Spec 3.3 (große Zahl, Ring mit Restzeit groß und vergangener Zeit klein, „Pausiert“, Ergebnis mit Ziel, geschafft ja/nein, „Neuer Rekord“).
- [ ] Restzeit aus ca. 60–80 cm lesbar: Basisgröße ≥ 88 pt, skaliert mit Dynamic Type (Spec 1.2, 3.13).
- [ ] HIG `typography.md › Ensuring legibility`: „In general, avoid light font weights.“ – `semibold`, gerundet, Monospaced Digits.
- [ ] HIG `accessibility.md › Cognitive`: „Be cautious with fast-moving and blinking animations. … reducing automatic and repetitive animations“ – bei „Bewegung reduzieren“ springt der Ring sekundenweise, keine Zahl-/Symbolanimation.
- [ ] HIG `progress-indicators.md › Best practices`: „Keep progress indicators moving so people know something is continuing to happen.“ – läuft kontinuierlich; steht er (Pause), sagt der Text „Pausiert“ warum.
- [ ] HIG `feedback.md › Best practices`: „When it makes sense, confirm that a significant action or task has completed.“ – Ergebnis-Screen.
- [ ] HIG `accessibility.md › Vision`: Pause und Ziel-Status nie nur über Farbe.

**Tests:** `SessionDisplayTextsTests` – alle Schlüssel in `de`/`en`.
**Commit (Vorschlag):** `feat(session): add countdown, timer ring and result views`

#### W2-T6 – Einstellungen und Info

- **Agent:** `swift-coding-agent` · Sonnet 5.5 · Effort Medium
- **Abhängigkeiten:** W1 (`UserSettings` aus W0, Coach-Tabelle aus W1-T2 lesend)
- **Kontext:** Spec 3.5 (Coach-Stile), 3.10; Design-Brief 5.6; Plan 4.6, 4.7
- **Exklusive Dateien:** Ordner `ios/Planktrainer/Features/Settings/` (ersetzt `SettingsScreen.swift`, `AboutScreen.swift`), `ios/Planktrainer/Resources/Localization/Settings.xcstrings`, `ios/PlanktrainerTests/Features/SettingsTextsTests.swift`

**Texte (Settings-Tabelle)**

| Schlüssel | en | de |
|---|---|---|
| `settings.title` | Settings | Einstellungen |
| `settings.appearance` | Appearance | Erscheinungsbild |
| `settings.appearance.system` | System | System |
| `settings.appearance.light` | Light | Hell |
| `settings.appearance.dark` | Dark | Dunkel |
| `settings.coach.header` | Coach | Coach |
| `settings.coach.calm` | Calm | Ruhig |
| `settings.coach.calm.description` | Relaxed and mindful. | Gelassen und achtsam. |
| `settings.coach.demanding` | Demanding | Fordernd |
| `settings.coach.demanding.description` | Sporty and driving. | Sportlich und antreibend. |
| `settings.coach.cheeky` | Cheeky | Frech |
| `settings.coach.cheeky.description` | Funny and a little cheeky. | Humorvoll und ein bisschen frech. |
| `settings.coach.off` | Off | Aus |
| `settings.coach.off.description` | Time announcements only. | Nur Zeitansagen. |
| `settings.postureHints` | Posture Hints | Haltungs-Hinweise |
| `settings.postureHints.footer` | Short tips on your posture between announcements, independent of the coach style. | Kurze Tipps zur Haltung zwischen den Ansagen, unabhängig vom Coach-Stil. |
| `settings.haptics` | Haptics | Haptik |
| `settings.haptics.footer` | Vibrations for the countdown, the start and a completed session. | Vibrationen beim Countdown, beim Start und bei einer geschafften Session. |
| `settings.about` | About | Info |
| `about.title` | About | Info |
| `about.version` | Version | Version |
| `about.license` | License | Lizenz |
| `about.license.value` | MIT | MIT |
| `about.sourceCode` | Source Code on GitHub | Quellcode auf GitHub |

**Schritte**
1. `SettingsScreen`: `Form`, Titel `settings.title`.
   - Erscheinungsbild: `Picker` (`.menu`) mit drei Optionen, gebunden an `userSettings.appearance` (`@Bindable`).
   - Coach: `Picker` mit `.pickerStyle(.inline)`, Zeilen mit Name, Beschreibung und – außer bei „Aus“ – einem Beispielsatz in Anführungszeichen, gelesen aus der Coach-Tabelle: Ruhig `coach.calm.filler.01`, Fordernd `coach.demanding.filler.04`, Frech `coach.cheeky.filler.02` (über `L10n.string(…, table: .coach)`).
   - Haltungs-Hinweise: `Toggle` mit Footer; Haptik: `Toggle` mit Footer.
   - Info: `NavigationLink(value: Route.about)`.
2. `AboutScreen`: `Form` mit `LabeledContent` Version (`CFBundleShortVersionString` + `CFBundleVersion` aus `Bundle.main.infoDictionary` per `as? String`; fehlend → leerer Text), Lizenz `MIT`, `Link` zu `https://github.com/deliehr/plank-trainer` (`URL(string:)` per `if let`, kein Force-Unwrap).

**Akzeptanzkriterien (inkl. HIG)**
- [ ] Alle Einstellungen aus Spec 3.10 mit den Standardwerten aus `UserSettings`; Änderungen wirken sofort (Erscheinungsbild über `preferredColorScheme` in `PlanktrainerApp`).
- [ ] Das Erscheinungsbild ist die dokumentierte Abweichung von HIG `dark-mode.md › Best practices` („Avoid offering an app-specific appearance setting.“) – Standard bleibt „System“.
- [ ] HIG `lists-and-tables.md › Best practices`: „a table that lists options often highlights a row only briefly before adding an image — such as a checkmark — indicating that the item is selected.“ – Inline-Picker mit Häkchen.
- [ ] HIG `playing-haptics.md › Best practices`: „Make haptics optional.“ – Haptik-Schalter.
- [ ] HIG `lists-and-tables.md › Style`: gruppierter Stil (`Form`) mit Überschriften und Footern.

**Tests:** `SettingsTextsTests` – alle Schlüssel in `de`/`en`.
**Commit (Vorschlag):** `feat(settings): add settings and about screens`

### Welle 3 – Integration (Haupt-Working-Tree, designunabhängig)

#### W3-T1 – Integrationstests mit echten Texten, Platzhalter-Prüfung

- **Agent:** `swift-coding-agent` · Sonnet 5.5 · Effort Medium
- **Arbeitsverzeichnis:** `/Users/dominik/Projects/plank-trainer`
- **Abhängigkeiten:** W2 abgenommen
- **Kontext:** Spec 3.4, 3.5, 5; Plan 5.1
- **Exklusive Dateien:** `ios/PlanktrainerTests/Integration/PlannerIntegrationTests.swift`, `ios/PlanktrainerTests/Integration/EngineIntegrationTests.swift`, `ios/PlanktrainerTests/Integration/LocalizationCoverageTests.swift`

**Schritte und Tests**
1. `PlannerIntegrationTests` mit echtem `AnnouncementPlanner(texts: AnnouncementTexts(locale:), coach: PhraseSelector(locale:, generator: SplitMix64(seed: 42)))`, Stil `.off`, Haltung aus, beide Sprachen: Spec-Tabelle 3.4 (5:00, 2:30, 1:00, 0:45, 0:20, 2:10) – Sekunden und Arten wie W1-T3 Test 1; Start-Text de `"Planking Session gestartet, noch 5 Minuten."`, en `"Planking session started, 5 minutes to go."`; Text der 1:30-Marke de `"Noch 1 Minute 30."`.
2. 0:35 mit Stil `.calm`, `.demanding`, `.cheeky` und je 20 Seeds: `tr30` ist genau dann enthalten, wenn der Start-Satz ≤ 5,0 s geschätzt ist (Spec-Beispiel 0:35).
3. Invarianten über T = 10…600 (5er-Schritte), alle Stile, Haltung an, Rekord 45, letzte Session 30 (verfehlt), beide Sprachen: sortiert, eindeutige Sekunden, kein Text enthält `%@` oder `%lld`, keine Ansage (außer Countdown) startet vor dem geschätzten Ende der vorigen.
4. `EngineIntegrationTests`: Engine mit echtem Planer, `FakeAnnouncer`-Äquivalent (eigener Typ `RecordingAnnouncer` in dieser Datei) und eigener Test-Uhr (`IntegrationClock` in dieser Datei): 60-s-Session in Deutsch läuft durch; gesprochen werden in dieser Reihenfolge u. a. „Mach dich bereit.“, „3“, „2“, „1“, Start-Satz mit „noch 1 Minute“, „Noch 30 Sekunden.“, „Noch 15 Sekunden.“, „Noch 10 Sekunden.“, „5“…„1“, Abschluss beginnt mit „Planking Session abgeschlossen.“
5. `LocalizationCoverageTests`: Tabellen `App`, `Common`, `Errors`, `Announcements`, `Coach`, `Training`, `History`, `SessionDetail`, `ActiveSession`, `SessionDisplay`, `Settings` sind in `de` **und** `en` nicht leer.
6. Prüfen (ohne Codeänderung, nur Bericht): `grep -rn 'PLACEHOLDER(' ios/Planktrainer` ist leer; sonst Fundstellen melden.

**Akzeptanzkriterien**
- [ ] Alle Integrationstests grün; Fehler in Produktivcode werden **nicht** in dieser Aufgabe behoben, sondern mit Analyse an den Tech Lead gemeldet (er vergibt eine Korrekturaufgabe an den ursprünglichen Eigentümer).

**Commit (Vorschlag):** `test: add integration tests for planner, engine and localization`

### Welle D – Claude-Design-Ergebnisse einarbeiten (später, designabhängig)

Vorbedingung: W2 abgenommen **und** Claude-Design-Ergebnisse liegen im Repo, Annahme: unter `docs/design/` (Tokens als Text/Tabelle, Screens als Bilder, App-Icon als 1024-px-PNG in Hell/Dunkel/getönt). Ablauf und Abnahme wie bei jeder Welle. Für alle D-Aufgaben gilt zusätzlich: Skill `apple-design` laden und gegen `docs/design/` sowie die HIG-Kriterien der ursprünglichen W2-Aufgabe prüfen; Funktionalität und Texte bleiben unverändert, sofern das Design keine neuen Texte verlangt.

#### D1-T1 – Tokens, Ring, App-Icon

- **Agent:** `swift-coding-agent` · Sonnet 5.5 · Effort Medium
- **Exklusive Dateien:** `ios/Planktrainer/DesignSystem/**`, `ios/Planktrainer/Resources/Assets.xcassets/**`
- **Schritte:** Farb-Tokens (Hell, Dunkel, Hoher Kontrast) als Color Sets in `Assets.xcassets` anlegen und in `ThemeColor` referenzieren (Token-Namen bleiben); Typo-Skala in `ThemeFont`/`ScaledTimeSize`; Abstände/Radien in `ThemeMetrics`; Ring-Spezifikation (Strichstärke, Enden, Verlauf, Spur, Pause, letzte 5 s) in `ProgressRing`/`RingMetrics`; App-Icon (Hell, Dunkel, getönt) und Akzentfarbe.
- **Akzeptanzkriterien:** Kontrast laut Design-Lieferung ≥ 4,5:1 (Text) bzw. ≥ 3:1 (großer/fetter Text) in Hell und Dunkel, nachgerechnet aus den Hex-Werten (HIG `accessibility.md › Vision`: Tabelle „Minimum contrast ratio“; `dark-mode.md › Dark Mode colors`: „strive for a contrast ratio of 7:1, especially in small text“); jede Farbe hat eine Variante für „Kontrast erhöhen“ (`color.md › Best practices`); App-Icon nach `app-icons.md` (Tech Lead lädt die Seite bei der Abnahme).
- **Commit (Vorschlag):** `feat(ui): apply Claude Design tokens, ring and app icon`

#### D2 – Screens an das Design anpassen (parallel nach D1)

| ID | exklusive Dateien | Commit (Vorschlag) |
|---|---|---|
| D2-T1 | `Features/Training/**`, `Training.xcstrings` | `feat(training): align training tab with Claude Design` |
| D2-T2 | `Features/History/**`, `History.xcstrings` | `feat(history): align history tab with Claude Design` |
| D2-T3 | `Features/SessionDetail/**`, `SessionDetail.xcstrings` | `feat(history): align session detail with Claude Design` |
| D2-T4 | `Features/ActiveSession/**`, `ActiveSession.xcstrings`, `SessionDisplay.xcstrings` (inkl. Abschluss-/Rekord-Moment mit Variante für „Bewegung reduzieren“) | `feat(session): align session screens with Claude Design` |
| D2-T5 | `Features/Settings/**`, `Settings.xcstrings` | `feat(settings): align settings with Claude Design` |

Alle: Agent `swift-coding-agent` · Sonnet 5.5 · Effort Medium; Kontext: `docs/design/`, Design-Brief, ursprüngliche W2-Aufgabe; Akzeptanz: Screens entsprechen den Design-Screens in Hell/Dunkel und bei großer Textgröße, alle HIG-Kriterien der W2-Aufgabe gelten weiter, bestehende Tests grün.

---

## 7. Tech-Lead-Abnahme pro Welle

Opus, Effort High. Für W2 und D zusätzlich: Skill `apple-design` laden (`CLAUDE.md › UI`) und die HIG-Kriterien der Aufgaben prüfen.

### 7.1 Checkliste (jede Welle, im Haupt-Working-Tree nach dem Integrieren)

1. **Zuständigkeit:** `diff -rq` jeder Arbeitskopie gegen `_base` zeigt nur zugewiesene Pfade (2.2). `git status --porcelain` zeigt nur erwartete Dateien; `ios/project.yml` und `ios/Planktrainer.xcodeproj` sind nach W0 unverändert.
2. **Build grün, keine Warnungen in Projektdateien:**
   `xcodebuild -project ios/Planktrainer.xcodeproj -scheme Planktrainer -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath ios/DerivedData build 2>&1 | grep -E 'warning:|error:' | grep 'ios/Planktrainer'` → leer.
3. **Tests grün:** `xcodebuild … test` (vollständig, alle Suites).
4. **Verbotene APIs:**
   `grep -rnE 'import Combine|ObservableObject|@Published|@StateObject|@ObservedObject|@EnvironmentObject|UIViewRepresentable|UIViewControllerRepresentable|UIHostingController|fatalError\(|try!|try\?|as!' ios/Planktrainer ios/PlanktrainerTests` → leer.
5. **Force-Unwrap (Heuristik, Treffer manuell prüfen):** `grep -rnE '[[:alnum:]_)\]]![^=]' --include='*.swift' ios/Planktrainer ios/PlanktrainerTests`.
6. **Fehler bis in die UI:** `grep -rn 'catch' ios/Planktrainer` – jede Fundstelle ist entweder UI-Schicht (Alert/Inline) oder eine der vier dokumentierten Ausnahmen aus 3.4; Services werfen typisierte Fehler.
7. **Lokalisierung:** `grep -rnE 'Text\("[^"]*"\)' --include='*.swift' ios/Planktrainer` (Text ohne `tableName`) und `grep -rnE '(Button|Label|Toggle|LabeledContent|Section|navigationTitle)\("' --include='*.swift' ios/Planktrainer/Features` → nur begründete Ausnahmen (`verbatim`, Zahlen). `LocalizationCompletenessTests` grün.
8. **Tokens:** `grep -rnE 'Color\.(red|green|blue|orange|yellow|gray|black|white)|Color\(red:|\.font\(\.system\(size' ios/Planktrainer/Features` → leer.
9. **Review gegen Spec und `CLAUDE.md`:** Verträge wörtlich eingehalten (4.x), Regeln aus 5.x umgesetzt, YAGNI (nichts aus Spec 9), Kommentare sparsam und englisch, Standardwerte nur an den vorgesehenen Stellen.
10. **Platzhalter:** `grep -rn 'PLACEHOLDER(' ios/Planktrainer` – nach W2 leer.
11. **Nur W2/D – Sichtprüfung im Simulator** (keine UI-Tests):

```sh
APP=ios/DerivedData/Build/Products/Debug-iphonesimulator/Planktrainer.app
xcrun simctl boot "iPhone 17"; xcrun simctl install "iPhone 17" "$APP"
xcrun simctl ui "iPhone 17" appearance dark            # bzw. light
xcrun simctl ui "iPhone 17" content_size accessibility-extra-extra-extra-large   # danach: large
xcrun simctl launch "iPhone 17" de.liehrit.planktrainer -AppleLanguages "(de)" -AppleLocale de_DE
xcrun simctl io "iPhone 17" screenshot /tmp/pt-<screen>-<variant>.png
```

   Je Tab sowie Session-Vollbild in Deutsch/Englisch, Hell/Dunkel, Standard/AX-Größe ansehen und gegen die HIG-Kriterien der Aufgabe prüfen.

### 7.2 Nach bestandener Abnahme

1. Pro Aufgabe `git add <Dateien>` und `git commit` (für M1 dauerhaft erlaubt, Abschnitt 11); kein Push.
2. Dem Nutzer im Abnahmebericht die Commit-Liste (Aufgabe → Dateien → Commit-Message) nennen.
3. Arbeitskopien und Simulator-Klone entfernen.
4. Bei Nacharbeit nach dem Commit: neue Korrekturaufgabe an den ursprünglichen Eigentümer, eigener `fix(...)`-Commit.

---

## 8. Abschluss-Phase M1

1. **Komplette Testausführung** im Haupt-Working-Tree nach einem sauberen Build:

```sh
rm -rf ios/DerivedData
cd ios && xcodegen generate && cd ..
git status --porcelain ios/Planktrainer.xcodeproj      # muss leer sein (Projekt reproduzierbar)
xcodebuild -project ios/Planktrainer.xcodeproj -scheme Planktrainer -destination 'platform=iOS Simulator,name=iPhone 17' build
xcodebuild -project ios/Planktrainer.xcodeproj -scheme Planktrainer -destination 'platform=iOS Simulator,name=iPhone 17' test
```

2. **Checkliste 7.1** einmal über den Gesamtstand.
3. **Sichtprüfung im Simulator** (7.1 Punkt 11) für alle Screens.
4. **Manuelle Geräte-Checkliste** (Spec 5) auf einem echten iPhone mit TestFlight- oder Debug-Build; der Nutzer führt sie aus und meldet Befunde direkt (kein eigenes Protokoll):

| # | Prüfung | Erwartung |
|---|---|---|
| 1 | Session über den **iPhone-Lautsprecher** (1:00, Coach „Fordernd“) | „Mach dich bereit“, 3-2-1, Start-Satz, 0:30, 0:15, 0:10, 5…1, „Planking Session abgeschlossen“ + Satz; Ergebnis gespeichert |
| 2 | Dasselbe mit **AirPods/Bluetooth** | Ausgabe über AirPods, gleiche Ansagen, keine Verzögerung > 1 s |
| 3 | **Musik** einer anderen App läuft | Musik wird während jeder Ansage leiser und danach wieder laut (kein dauerhaftes Ducking, kein Stopp) |
| 4 | **Stumm-Modus** an | Ansagen sind trotzdem hörbar |
| 5 | **Anruf** während running (zweites Telefon) | Session pausiert automatisch; nach dem Anruf weiter nur per „Weiter“ mit 3-2-1 |
| 6 | **Siri/Wecker** während running | wie 5 |
| 7 | **App-Wechsel** und **Sperrtaste** während running, preparing und resuming | Session ist danach pausiert; Zeit lief nicht weiter |
| 8 | **Display bleibt an** während einer 3-min-Session ohne Berührung; nach Schließen des Vollbilds geht das Display wieder normal aus | wie beschrieben |
| 9 | **+10 s** mehrfach, **Pause/Weiter**, **Stop** vor und nach dem Ziel, **Abbrechen** mit Rückfrage | Werte im Ergebnis und im Verlauf stimmen (erreicht ohne Pausen, Ziel ohne Verlängerung) |
| 10 | **Rekord**: Session länger als bisheriger Rekord | „Rekord in Sicht“ 5 s vorher, „Neuer Rekord“ 1 s danach (wenn nicht in den letzten 10 s), Ergebnis „Neuer Rekord!“, Markierung im Verlauf |
| 11 | **Haptik** an/aus | 3-2-1 und 5…1 leicht, Start mittel, Erfolg bei geschafft; aus → keine |
| 12 | **Dynamic Type** (größte Accessibility-Größe) | alle Screens bedienbar, Restzeit skaliert, nichts abgeschnitten, was nicht scrollbar ist |
| 13 | **Dark Mode** in abgedunkeltem Raum, **Kontrast erhöhen**, **Transparenz reduzieren** | gut lesbar, keine blendenden Flächen |
| 14 | **VoiceOver** | Tabs, Picker, Ring („Restzeit, …“), Buttons, Verlaufszeilen und Diagramm werden sinnvoll vorgelesen |
| 15 | **Bewegung reduzieren** | Ring springt sekundenweise, keine Zahl-/Symbolanimation |
| 16 | **Deutsch und Englisch** (Systemsprache umstellen) | UI und Ansagen vollständig in der jeweiligen Sprache, Stimme passend |
| 17 | **Coach-Stile** Ruhig, Fordernd, Frech, Aus; Haltungs-Hinweise an/aus | Sätze passen zum Stil; „Aus“ nur Zeit-Ansagen und feste Sätze |
| 18 | **Löschen per Wischen** und über „Bearbeiten“ | Session weg, Rekord neu berechnet |

5. Offene Befunde werden als Korrekturaufgaben vergeben; M1 ist abgeschlossen, wenn Tests grün und alle Geräte-Prüfungen bestanden sind.

---

## 9. Risiken und technische Fallstricke

| # | Risiko | Gegenmaßnahme / frühe Verifikation |
|---|---|---|
| R1 | **SwiftData `@Model` unter Default-Isolation MainActor** (Makro-Code, `PersistentModel`-Konformanz, Sendable-Diagnosen) | Im Spike mit Xcode 27.2 ohne Warnung kompiliert und getestet. Erneute Prüfung in W0-T1 (Akzeptanzkriterium „ohne Warnung“, Container-Test). Bleibt ein Problem: Tech Lead entscheidet vor W1 (z. B. `nonisolated` am Modell) – nicht in W1 verschleppen. |
| R2 | **`AVSpeechSynthesizer`-Delegate und Concurrency** (Callbacks auf beliebigem Thread, Delegate-Protokoll nicht isoliert) | Proxy-Objekt mit `nonisolated`-Methoden, die nur in einen `AsyncStream` schreiben; Auswertung auf dem MainActor (W1-T5). Muster im Spike warnungsfrei kompiliert. Kein `@preconcurrency`, kein `DispatchQueue.main`. |
| R3 | **`AVAudioSession`**: `.playback` + `.voicePrompt` + `.duckOthers` + `.interruptSpokenAudioAndMixWithOthers`; Deaktivieren während laufender Ausgabe schlägt fehl; `setActive` blockiert kurz | Aktivieren pro Ansage, Deaktivieren erst wenn `!isSpeaking` nach `didFinish`/`didCancel`, mit `.notifyOthersOnDeactivation`; Fehler beim Deaktivieren nur loggen. Ducking-Verhalten nur auf dem Gerät prüfbar → Geräte-Checkliste 3/4. Falls Ducking zwischen schnell aufeinanderfolgenden Ansagen (5…1) flackert: Deaktivierung um 1 s verzögern (Entscheidung Tech Lead nach Gerätetest). |
| R4 | **Audio-Unterbrechungen** über `NotificationCenter.notifications(named:)`: Benachrichtigungen kommen ggf. nur, solange die eigene Session aktiv ist; zwischen Ansagen ist sie inaktiv, ein Anruf könnte dann unbemerkt bleiben | Anrufe lösen in der Praxis meist zusätzlich `scenePhase`-Wechsel aus; Geräte-Checkliste 5/6 prüft das. Risiko vom Nutzer akzeptiert; keine Ergänzung über `CXCallObserver` (Abschnitt 11). |
| R5 | **Auto-Pause über `scenePhase`**: `.inactive` tritt auch bei Kontrollzentrum/Mitteilungen auf; im `fullScreenCover` muss `scenePhase` korrekt ankommen | Nur `.background` pausiert (Spec 3.3). Sperrtaste und App-Wechsel in Geräte-Checkliste 7. `scenePhase` wird in `ActiveSessionContent` gelesen (Environment wird in den Cover vererbt) – vom Tech Lead in W2 im Simulator (Home-Geste) zu verifizieren. |
| R6 | **Testbarkeit der Zeit**: echte Uhr macht Engine-Tests langsam/flaky | `SessionClock`-Protokoll mit `ContinuousClock.Instant`; eigene `TestSessionClock` (Ursprung `ContinuousClock.now` + manueller Offset, im Spike geprüft); Engine wird über `tick()` getrieben, `run()` ist nur eine dünne Schleife. Laufbeginn = Phasenstart + N s, damit Tick-Verzögerungen die Messung nicht verfälschen. |
| R7 | **`isIdleTimerDisabled`** bleibt versehentlich an (Akku) oder wird zu früh zurückgesetzt | Setzen in `onAppear`, Zurücksetzen in `onDisappear` des Vollbilds; Geräte-Checkliste 8. |
| R8 | **Parallele Builds/Tests** stören sich (DerivedData-Locks, gleiche Bundle-ID auf einem Simulator, halbfertige Dateien anderer Agenten) | Arbeitskopien mit eigenem DerivedData und Simulator-Klon je Aufgabe (2.1), höchstens 4 Agenten gleichzeitig. |
| R9 | **String Catalogs**: Xcode-IDE könnte beim Bauen extrahierte Schlüssel in Kataloge schreiben; Schlüssel ohne Tabellenname landen in `Localizable` | Alle Einträge `extractionState: manual` mit expliziten Werten; Agenten bauen nur per `xcodebuild` (verändert die Quellen laut Spike nicht); Grep-Prüfung 7.1 Punkt 7; `LocalizationCompletenessTests`. Ob das Öffnen in der Xcode-IDE Kataloge oder `knownRegions` umschreibt, ist **vom Tech Lead in Welle 0 zu verifizieren** (einmal öffnen, bauen, `git status`). |
| R10 | **`knownRegions` ohne `de`** bei reinen `syncedFolder`-Quellen | `ios/SupportingFiles/InfoPlist.xcstrings` als nicht synchronisierte Quelle (im Spike: `de` erscheint). W0-T1-Akzeptanzkriterium. |
| R11 | **Ansage-Verzögerung**: lange zusammengeführte Sätze vor dem Countdown, Warteschlange des Synthesizers | Planer garantiert 1 s Puffer vor der nächsten Ansage; Countdown-Zahlen sind kurz; Geräte-Checkliste 1. |
| R12 | **Foundation-Ausgaben** (`Duration.UnitsFormatStyle`, relative Datumsformate) variieren je OS-Version | Tests prüfen nur mit `contains`; `TimeText.clock` wird manuell gebildet. |
| R13 | **API-Details, die nicht im Spike liefen** (vom Tech Lead in Welle 0 zu verifizieren, per kurzem Kompiliertest bei der W0-Abnahme): `SensoryFeedback`-Vergleich mit `==` (W2-T4-Test), `Tab(value:content:label:)` mit Label-Closure (W0-T2), `PreviewHost` mit throwing Container-Erzeugung (W0-T2), `ContentUnavailableView` in `List` (W2-T2) | Bei Abweichung: kleinste funktionsgleiche Alternative wählen und in der Abnahme dokumentieren; Verträge aus Abschnitt 4 ändert nur der Tech Lead (mit Plan-Nachtrag). |
| R14 | **Ruckelnder Ring** durch `TimelineView(.animation)` plus `@Observable`-Änderungen jede Sekunde | Ring liest die Fraktion direkt aus der Uhr; nicht beobachtete Engine-Zustände sind `@ObservationIgnored`; `elapsedSeconds` wird nur bei Änderung gesetzt. |

---

## 10. Annahmen

Diese Punkte füllen Lücken oder lösen Widersprüche der Spezifikation. Sie gelten, bis der Nutzer anders entscheidet.

| # | Annahme | Begründung |
|---|---|---|
| A1 | **Mehrere String-Tabellen** statt eines `Localizable.xcstrings` (Spec 3.12) | Parallele Arbeit ohne Konflikte; Standardmechanismus; im Spike verifiziert (3.2). |
| A2 | **UI-Welle W2 läuft vor den Claude-Design-Ergebnissen** mit Platzhalter-Tokens; Einarbeitung in Welle D (Spec 6 sagt: UI-Welle startet erst mit Design-Ergebnissen) | Vorgabe des Auftrags; Tokens trennen Gestaltung von Funktion. Liegt das Design vor W2 vor, läuft D1 zuerst. |
| A3 | Design-Ergebnisse werden unter `docs/design/` abgelegt | Kein Ort in Spec/Brief festgelegt. |
| A4 | **Auto-Pause auch in `preparing` und `resuming`** → `paused`; danach „Weiter“ mit 3-2-1. War noch kein Lauf, folgt der Start-Satz statt des Weiter-Satzes. `pauseCount` zählt jeden Eintritt in `paused`. | Spec nennt Auto-Pause nur allgemein; das Zustandsdiagramm kennt keinen Übergang aus `preparing`. |
| A5 | Die Engine reicht Audio-Fehler als beobachtbaren Zustand (`announcementError`) an die UI weiter; Fehler beim Deaktivieren der Audio-Session werden nur geloggt | Die Engine ist kein UI-Code, die Ansagen laufen ohne Nutzeraktion; der Fehler erreicht trotzdem die UI (Spec 3.6, 3.11). |
| A6 | Rekord-Satz im Abschluss nur, wenn „Neuer Rekord“ nicht schon während der Session angesagt wurde; bei Stil „Aus“ gibt es keinen Rekord-Satz | Spec 3.5 „sonst Teil des Abschluss-/Stop-Satzes“; für „Aus“ gibt es keine Rekord-Sätze. |
| A7 | Stop nach erreichtem Ziel: „Planking Session abgeschlossen.“ + Abschluss-Satz | Spec 3.5 „bei erreichtem Ziel stattdessen Abschluss-Satz“. |
| A8 | Treffen Halbzeit und Endspurt auf die 15-s-Marke, gewinnt die Halbzeit | Gleiche Prioritätsstufe; Halbzeit ist seltener. |
| A9 | Countdown 5…1 ist vom Mindestabstand ausgenommen; alle Planungsdetails wie in 5.1 (Passt-Prüfung mit 4 s Abstand nach dem Start der vorigen Ansage, Zusammenführungsregeln) | Spec lässt die genaue Kollisionsbehandlung offen. |
| A10 | Lückenfüller-Fenster: ab 10 s aktiver Zeit, nur bei Restzeit > 15 s, ≥ 20 s zwischen zwei Lücken-Ansagen (Füller und Haltung gemeinsam), Wechsel beginnt mit Füller | Spec 3.5 präzisiert. |
| A11 | „Außerhalb der letzten 10 s“ heißt Restzeit > 10 s zum Zeitpunkt des Ereignisses | Präzisierung. |
| A12 | Haptik `.success`, wenn die Session mit erreichtem Ziel endet (Zeit abgelaufen **oder** Stop nach Ziel) | Spec 3.7 „Session abgeschlossen“. |
| A13 | Zusätzlich zum Wischen ein `EditButton` im Verlauf | HIG `accessibility.md › Mobility`: „Offer alternatives to gestures.“ |
| A14 | Rekord = größte erreichte Zeit > 0; bei Gleichstand ist die früheste Session die Rekord-Session; 0-Sekunden-Sessions setzen keinen Rekord | Spec definiert Gleichstand nicht. |
| A15 | Fehlende `id` (nur bei fremden/defekten Daten) → feste Null-UUID als Ersatz | Optionale Eigenschaften (CloudKit-Vorbereitung) verlangen einen Standardwert; Detail-Navigation bleibt möglich. |
| A16 | Stop ist auch bei 0 s aktiver Zeit möglich (z. B. nach Auto-Pause in der Vorbereitung) und wird gespeichert | Spec erlaubt Stop in `paused` ohne Einschränkung; Nutzer kann löschen. |
| A17 | Bei verzögertem Tick werden nur Ansagen der letzten Sekunde nachgeholt, ältere übersprungen | Verhindert eine Kaskade veralteter Ansagen. |
| A18 | Texte für Bildschirmelemente, die Spec/Brief nicht wörtlich vorgeben (z. B. „Gleich geht's weiter“, Footer in den Einstellungen, Fehlertexte), stammen aus diesem Plan | Gegenlesen durch den Nutzer wie bei den Ansagetexten. |
| A19 | Stimme: App-Sprache; stimmt die Systemstimmen-Sprache mit der App-Sprache überein (z. B. `de-AT`), wird deren Region verwendet | Spec 3.6 „Standard-Systemstimme der aktiven App-Sprache“. |
| A20 | Isolierte Arbeitskopien statt Git-Worktrees; Commits pro Aufgabe nach Abnahme und Zustimmung | `CLAUDE.md › Git` (2.1). |

---

## 11. Entscheidungen des Nutzers (2026-11-21)

1. **A1/A2:** angenommen – getrennte String-Tabellen; Screens entstehen vor dem Claude-Design mit Platzhalter-Tokens und werden in Welle D angepasst.
2. **Commits:** Für M1 dauerhaft erlaubt – der Tech Lead committet pro Aufgabe nach der Abnahme ohne erneute Rückfrage. Push, Merge, Rebase, Tags und Branches weiterhin nur nach Absprache.
3. **A4/A16:** bleiben so.
4. **A18:** Der Nutzer liest die neuen UI-Texte gegen. Der Tech Lead legt ihm nach der Abnahme von W2 die Text-Tabellen vor.
5. **A3:** Design-Ergebnisse liegen unter `docs/design/`.
6. **Geräte-Checkliste:** Kein eigenes Protokoll; der Nutzer meldet Befunde direkt.
7. **R4:** Risiko akzeptiert; keine Ergänzung über `CXCallObserver`.
