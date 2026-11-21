# Plank-Trainer – Spezifikation

Stand: 2026-11-21 · Status: Entwurf für Meilenstein 1 · Quelle: `docs/initial-spec.md`

Begleitdokumente:
- `docs/spec/announcement-phrases.md` – alle Ansage- und Coach-Texte (Deutsch/Englisch)
- `docs/spec/claude-design-brief.md` – Auftrag für Claude Design

---

## 1. Produkt

### 1.1 Vision

Eine iPhone-App, die beim Planking begleitet: Sie sagt die Zeit an, feuert mit einem Coach mit Persönlichkeit an und zeigt einen ehrlichen Verlauf mit Rekorden. Sie soll Spaß machen und motivieren, ohne Druck-Mechaniken.

### 1.2 Leitlinien

- **Hände frei, Blick frei.** Während der Session muss niemand aufs Display schauen; alles Wichtige wird angesagt. Was angezeigt wird, ist aus ca. 60–80 cm Entfernung (iPhone liegt auf dem Boden) lesbar.
- **Mit sich selbst vergleichen.** Motivation kommt aus Rekorden und dem eigenen Verlauf. **Keine Streaks** (bewusste Entscheidung), keine Abzeichen.
- **Charakter.** Ein wählbarer Coach-Stil, von ruhig bis frech.
- **Offline und privat.** Keine Konten, kein Netzwerk, keine Berechtigungsabfragen in M1.

### 1.3 Eckdaten

| Punkt | Wert |
|---|---|
| Produkt-/Target-Name | `Planktrainer` |
| Anzeigename | Plank-Trainer |
| Bundle-ID | `de.liehrit.planktrainer` |
| Development Team | `8HM2FV529D` |
| Geräte / Ausrichtung | nur iPhone, nur Portrait |
| Minimum | iOS 26 |
| Sprache/Tooling | Swift 6, Default-Isolation `MainActor`, Approachable Concurrency, SwiftUI, SwiftData, Swift Charts, Swift Testing |
| Projektgenerierung | XcodeGen (`ios/project.yml`, Quellen als `syncedFolder`); das generierte `.xcodeproj` wird eingecheckt (Xcode Cloud) |
| Lokalisierung | Entwicklungssprache Englisch, Hauptsprache für Nutzer Deutsch, Englisch unterstützt (String Catalog) |
| CI/CD | Xcode Cloud → TestFlight |
| Lizenz | MIT |
| Drittanbieter-Pakete | keine |

---

## 2. Meilensteine

| Meilenstein | Inhalt | Status |
|---|---|---|
| **M1** | Planking-Sessions mit Ansagen, Coach, Verlauf, Rekorden | diese Spezifikation |
| M2 | Video-Unterstützung, Körperhaltung via Vision (`VNHumanBodyPoseObservation`) | nicht final |
| M3 | Apple Watch | nicht final |
| M4 | Kompetitiv mit Freunden/Einladungen; Backend (Java 25, Spring Boot 4, Maven, Postgres), WebSockets, REST; GitLab CI/CD, Portainer, Traefik, Watchtower | nicht final |

Zurückgestellte Funktionen ohne Meilenstein-Zuordnung: Abschnitt 9.

---

## 3. M1 – Funktionsumfang

### 3.1 Navigation

- `TabView` mit drei Tabs, Start auf **Training**:

| Tab | Titel (de / en) | SF Symbol (Vorschlag) | Push-Ziele |
|---|---|---|---|
| Training | Training / Training | `figure.core.training` | – |
| Verlauf | Verlauf / History | `chart.bar.fill` | Session-Detail |
| Einstellungen | Einstellungen / Settings | `gearshape.fill` | Info |

- Jeder Tab hat einen eigenen `NavigationStack` mit **genau einer Push-Ebene** (Konvention).
- Sheets und Vollbild-Ansichten (`fullScreenCover`) werden **zentral in der `RootView`** präsentiert.
- Die laufende Session ist ein `fullScreenCover`: Sie lässt sich nicht versehentlich wegwischen und darf die Tab Bar verdecken (HIG `tab-bars.md › Best practices`: Ausnahme für Modale).

**AppRouter** (vereinfacht gegenüber Dimillian/AppRouter: kein generischer Router-Typ, keine Deep Links, keine verschachtelten Router):

```swift
enum AppTab: Hashable, CaseIterable { case training, history, settings }
enum Route: Hashable { case sessionDetail(UUID), about }
enum FullScreen: Identifiable { case activeSession(SessionConfiguration) }

@Observable final class AppRouter {
    var selectedTab: AppTab = .training
    var paths: [AppTab: [Route]] = [:]
    var fullScreen: FullScreen?
    func push(_ route: Route)
    func popToRoot()
    func present(_ fullScreen: FullScreen)
    func dismissFullScreen()
}
```

Ein `Sheet`-Enum wird erst angelegt, wenn es ein Sheet gibt (in M1 ist keines geplant, YAGNI). Die Präsentations-Infrastruktur in der `RootView` ist so gebaut, dass ein Sheet-Fall ohne Umbau ergänzt werden kann.

### 3.2 Training-Tab

Inhalt von oben nach unten (Feinlayout von Claude Design):
1. **Rekord und letzte Session** – kompakt: „Rekord 2:15“ · „Zuletzt: gestern, 1:30 ✓“. Leer beim ersten Start.
2. **Session-Zeit** – Rad-Picker mit zwei Rädern (Minuten 0–10, Sekunden 0–55 in 5-s-Schritten), inline sichtbar. Gültiger Bereich 0:10–10:00. Ungültige Kombinationen (z. B. 0:05 oder 10:30) werden auf den nächsten gültigen Wert korrigiert.
3. **Vorbereitungszeit** – Zeile mit Wert (Standard 10 s); Antippen klappt inline einen Rad-Picker auf (5–60 s, 5-s-Schritte). Kein Sheet (HIG `pickers.md`: „Avoid switching views to show a picker“).
4. **Start-Button** – prominent, im unteren Daumenbereich.

Beim Start werden Session- und Vorbereitungszeit als neue Standardwerte gespeichert (`UserSettings`).

### 3.3 Session-Ablauf (Vollbild)

#### Zustände

```
preparing ──► running ◄──► paused ──► resuming (3-2-1) ──► running
   │             │            │
   │             ├──► finished(completed)   Zeit abgelaufen
   │             ├──► finished(stopped)     „Stop“
   └─────────────┴──► cancelled             „Abbrechen“ (verwerfen)
```

| Zustand | Anzeige | Ansagen | Bedienung |
|---|---|---|---|
| preparing | große Zahl zählt N…1 herunter | „Mach dich bereit“ bei Beginn, „3“, „2“, „1“ | Abbrechen (ohne Rückfrage, es geht nichts verloren) |
| running | schrumpfender Ring (wie Apple Timer), Restzeit groß, vergangene Zeit klein | Zeit- und Coach-Ansagen (3.4, 3.5) | Pause, Stop, +10 s, Abbrechen |
| paused | Ring und Zeit eingefroren, Hinweis „Pausiert“ | laufende Ansage wird abgebrochen, keine neue | Weiter, Stop, +10 s, Abbrechen |
| resuming | 3-2-1-Countdown über dem eingefrorenen Ring | „3“, „2“, „1“, danach Weiter-Satz mit Restzeit | Abbrechen |
| finished | Ergebnis: erreichte Zeit, Ziel, geschafft ja/nein, ggf. „Neuer Rekord“ | Abschluss- bzw. Stop-Satz | Fertig |

Regeln:
- **Keine automatische Beendigung** einer Pause; die Session bleibt pausiert, bis der Nutzer handelt.
- **Automatische Pause**, wenn die App in den Hintergrund geht (`scenePhase == .background`: App-Wechsel, Sperrtaste) und bei einer Audio-Unterbrechung (Anruf, Siri, Wecker). Danach geht es nur per „Weiter“ weiter.
- **+10 s** ist beliebig oft möglich, im Zustand running und paused. Der Ansageplan wird neu berechnet.
- **Stop** beendet sofort und speichert. **Abbrechen** fragt im Zustand running/paused/resuming per `confirmationDialog` („Session verwerfen?“) nach und verwirft ohne Speichern.
- **Gespeichert** wird beim Übergang nach finished, nicht erst beim Tippen auf „Fertig“, damit ein Speicherfehler im Ergebnis-Screen sichtbar wird.
- **Display bleibt an**, solange das Vollbild offen ist (`UIApplication.shared.isIdleTimerDisabled`; das ist keine UIKit-View und damit zulässig).
- **Zeitmessung** über eine monotone Uhr (`ContinuousClock`, injizierbar für Tests), nicht über das Zählen von Ticks. `achievedSeconds` = aktive Zeit ohne Pausen und ohne Resume-Countdowns, abgerundet auf ganze Sekunden.
- **Ziel erreicht** gilt, wenn `achievedSeconds >= plannedSeconds` (ursprüngliche Zeit ohne Verlängerung). Wer während einer Verlängerung stoppt, hat das Ziel also erreicht.
- **Neuer Rekord**, wenn `achievedSeconds` größer ist als das bisherige Maximum aller gespeicherten Sessions. Bei der allerersten Session gibt es keine Rekord-Ansage.

### 3.4 Zeit-Ansagen

#### Regel

Ansagen erfolgen bei folgenden Restzeiten:
1. **Start:** Gesamtzeit (Start-Satz des Coach-Stils, siehe 3.5).
2. **Restzeit > 2:00:** jede volle Minute (z. B. 4:00, 3:00).
3. **Restzeit ≤ 2:00:** jede volle halbe Minute (2:00, 1:30, 1:00, 0:30).
4. **15 s und 10 s.**
5. **5, 4, 3, 2, 1** – nur die Zahl.
6. **Ende:** „Planking Session abgeschlossen“ plus Abschluss-Satz.

- Das Wort „noch“ wird immer gesprochen, außer bei 5…1.
- **Mindestabstand:** Eine Marke entfällt, wenn sie weniger als 4 s nach dem Beginn der vorherigen Ansage läge oder die vorherige Ansage laut geschätzter Sprechdauer (3.5) dann noch läuft.
- Nach +10 s und nach dem Resume wird der Plan ab der aktuellen Restzeit neu berechnet.

#### Beispiele (Referenz für Tests)

| Sessionzeit | Ansagen (Restzeit) |
|---|---|
| 5:00 | Start „noch 5 Minuten“ · 4:00 · 3:00 · 2:00 · 1:30 · 1:00 · 0:30 · 0:15 · 0:10 · 5 · 4 · 3 · 2 · 1 · Ende |
| 2:30 | Start „noch 2 Minuten 30“ · 2:00 · 1:30 · 1:00 · 0:30 · 0:15 · 0:10 · 5…1 · Ende |
| 1:00 | Start „noch 1 Minute“ · 0:30 · 0:15 · 0:10 · 5…1 · Ende |
| 0:45 | Start „noch 45 Sekunden“ · 0:30 · 0:15 · 0:10 · 5…1 · Ende |
| 0:20 | Start „noch 20 Sekunden“ · 0:15 · 0:10 · 5…1 · Ende |
| 2:10 | Start „noch 2 Minuten 10“ · 2:00 · 1:30 · … |
| 0:35 | Start „noch 35 Sekunden“ + Stil-Zusatz · 0:30 nur, wenn der Start-Satz bis dahin fertig gesprochen ist · 0:15 · 0:10 · 5…1 · Ende |

**Nach +10 s** gibt es keine sofortige Ansage. Die Anzeige aktualisiert sich, und der Plan wird ab der neuen Restzeit neu berechnet (Gesamtzeit = Ziel + Verlängerung). Bereits vergangene Marken, z. B. die Halbzeit, werden nicht nachgeholt.

#### Formulierung der Zeit

| Restzeit | Deutsch | Englisch |
|---|---|---|
| 45 s | „noch 45 Sekunden“ | „45 seconds to go“ |
| 60 s | „noch 1 Minute“ | „1 minute to go“ |
| 90 s | „noch 1 Minute 30“ | „1 minute 30 to go“ |
| 150 s | „noch 2 Minuten 30“ | „2 minutes 30 to go“ |
| 120 s | „noch 2 Minuten“ | „2 minutes to go“ |

Bei Minuten mit Restsekunden wird „Sekunden“ weggelassen. Singular/Plural über die Plural-Varianten des String Catalogs.

### 3.5 Coach und Motivation

#### Coach-Stile

| Stil | Charakter | Standard |
|---|---|---|
| Ruhig | gelassen, achtsam | |
| Fordernd | sportlich, antreibend | ✓ |
| Frech | humorvoll, leicht beleidigend; nur auf Wunsch | |
| Aus | nur Zeit-Ansagen und die festen Sätze, keine Motivation | |

**Leitplanke für „Frech“:** Sticheleien über Faulheit, Sofa, Ausreden und Durchhaltevermögen. Nie über Körper, Gewicht, Aussehen, Geschlecht oder Herkunft. Keine Schimpfwörter jenseits von „Weichei“/„Faultier“-Niveau.

#### Anlässe

| Anlass | Zeitpunkt | Bemerkung |
|---|---|---|
| Vorbereitung | Beginn der Vorbereitung | fest: „Mach dich bereit“ |
| Start | Beginn running | Stil-Satz, enthält immer „noch {Zeit}“; bei „Aus“: „Planking Session gestartet, noch {Zeit}“ |
| Halbzeit | Restzeit = ⌊Gesamt/2⌋ | wird als Präfix an eine Zeit-Ansage angehängt, wenn diese weniger als 4 s entfernt ist |
| Endspurt | Präfix der 15-s-Ansage | |
| Lückenfüller | in Lücken zwischen Pflichtansagen | höchstens alle 20 s, nicht in den ersten 10 s und nicht in den letzten 15 s |
| Haltungs-Hinweis | wie Lückenfüller | eigener Schalter, unabhängig vom Stil; bei Aktivierung abwechselnd mit Lückenfüllern |
| Rekord in Sicht | vergangene Zeit = Rekord − 5 s | nur wenn ein Rekord existiert und der Zeitpunkt außerhalb der letzten 10 s liegt |
| Neuer Rekord | vergangene Zeit = Rekord + 1 s | gleiche Bedingung; sonst Teil des Abschluss-/Stop-Satzes |
| Letzte Session | vergangene Zeit = erreichte Zeit der letzten Session | nur wenn diese das Ziel verfehlt hat und ihre erreichte Zeit kleiner als die aktuelle Gesamtzeit ist |
| Weiter | nach dem 3-2-1 des Resume | enthält „noch {Zeit}“; entfällt bei Restzeit ≤ 10 s |
| Abschluss | nach „Planking Session abgeschlossen“ | bei neuem Rekord zusätzlich ein Rekord-Satz |
| Gestoppt | bei Stop vor Erreichen des Ziels | enthält die erreichte Zeit; bei erreichtem Ziel stattdessen Abschluss-Satz |

#### Planungsregeln

- **Priorität** bei Konflikten: Zeit-Ansage > Rekord-Ereignis > Halbzeit/Endspurt > Letzte Session > Haltungs-Hinweis > Lückenfüller.
- **Sprechdauer** wird geschätzt (Zeichenanzahl ÷ 14 pro Sekunde). Eine Ansage wird nur eingeplant, wenn sie mindestens 1 s vor der nächsten höher priorisierten Ansage endet. Sonst entfällt sie (oder wird bei Halbzeit/Endspurt als Präfix zusammengeführt).
- **Keine Wiederholung:** Pro Anlass und Stil wird ohne Zurücklegen gezogen (Shuffle-Bag), erst wenn alle Sätze verbraucht sind, wird neu gemischt. Zufallsquelle injizierbar.
- Der **Ansageplan ist eine reine Funktion** der Eingaben (Gesamtzeit, vergangene Zeit, Rekord, letzte Session, Stil, Haltungs-Hinweise, Zufallsquelle) und vollständig testbar.

### 3.6 Audio und Sprachausgabe

- `AVSpeechSynthesizer` mit der Standard-Systemstimme der aktiven App-Sprache; Stimme und Tempo sind nicht einstellbar.
- `AVAudioSession`: Kategorie `.playback` (Ansagen auch im Stumm-Modus), Modus `.voicePrompt`, Optionen `.duckOthers` und `.interruptSpokenAudioAndMixWithOthers`.
- Die Session wird pro Ansage aktiviert und danach mit `.notifyOthersOnDeactivation` deaktiviert, damit fremde Musik wieder auf volle Lautstärke geht.
- Funktioniert mit iPhone-Lautsprecher und AirPods/Bluetooth.
- Unterbrechungen (`AVAudioSession.interruptionNotification`) führen zu Auto-Pause. Benachrichtigungen werden per `NotificationCenter.notifications(named:)` als `AsyncSequence` gelesen (kein Combine).
- Schlägt die Audio-Konfiguration fehl, läuft die Session ohne Ton weiter und zeigt einen nicht-blockierenden Hinweis („Ansagen nicht verfügbar“).

### 3.7 Haptik

Über SwiftUI `.sensoryFeedback` (keine UIKit-Generatoren), abschaltbar in den Einstellungen:

| Ereignis | Feedback |
|---|---|
| 3, 2, 1 (Vorbereitung, Resume) und 5…1 am Ende | `.impact(weight: .light)` |
| Beginn running | `.impact(weight: .medium)` |
| Session abgeschlossen | `.success` |

Keine eigenen Töne. System-Sound-IDs sind keine öffentliche API, deshalb trägt die Stimme den Ton.

### 3.8 Verlauf-Tab

- **Diagramm** (Swift Charts) über der Liste: Balken = erreichte Zeit der letzten 30 Sessions in zeitlicher Reihenfolge, horizontale Linie = Rekord. „Ziel erreicht“ wird nicht nur über Farbe unterschieden (zusätzlich Füllung/Muster und Accessibility-Label).
- **Liste**, neueste zuerst. Jede Zeile zeigt:
  - Datum und Uhrzeit
  - erreicht / Ziel (z. B. „1:30 / 1:30“)
  - Status-Symbol (geschafft / nicht geschafft)
  - Rekord-Markierung an der Rekord-Session
- **Löschen per Wischen**, ohne Rückfrage (Plattform-Standard). Der Rekord ergibt sich danach neu.
- **Leerzustand:** `ContentUnavailableView` mit Aktion „Erste Session starten“ → wechselt zum Training-Tab.
- Antippen einer Zeile → Push zum Session-Detail.

### 3.9 Session-Detail

- **Ring:** erreichte Zeit im Verhältnis zum Ziel.
- **Werte:**
  - Datum und Uhrzeit
  - Ziel, erreicht, Vorbereitungszeit
  - Anzahl Pausen, Verlängerung gesamt
  - Abstand zum Rekord: „Rekord“ oder „12 s unter deinem Rekord“
- **Button „Nochmal mit gleicher Zeit“:** startet eine Session (Vollbild) mit derselben Ziel- und Vorbereitungszeit und speichert beide als neue Standardwerte.
- Kein Bearbeiten, kein Löschen hier.

### 3.10 Einstellungen

| Einstellung | Werte | Standard |
|---|---|---|
| Erscheinungsbild | System / Hell / Dunkel | System |
| Coach-Stil | Ruhig / Fordernd / Frech / Aus, mit Kurzbeschreibung | Fordernd |
| Haltungs-Hinweise | an/aus | an |
| Haptik | an/aus | an |
| Info (Push) | Version, Lizenz MIT, Link zum Repository | – |

Das Erscheinungsbild ist eine **bewusste Abweichung** von HIG `dark-mode.md › Best practices` („Avoid offering an app-specific appearance setting“); es war eine Entscheidung des Nutzers.

Persistenz über `UserSettings` (`@Observable`, `UserDefaults`), Struktur nach `docs/swift/UserSettings.swift`. Zusätzlich werden die letzte Session- und Vorbereitungszeit gespeichert.

### 3.11 Fehlerbehandlung

- Services werfen **typisierte Fehler** (`enum …Error: LocalizedError`). Fangen und Anzeigen geschieht ausschließlich in der UI-Schicht.
- Vom Nutzer ausgelöste Aktion schlägt fehl (Speichern, Löschen) → Alert mit verständlicher Meldung.
- Nicht-blockierende Probleme während der Session (Audio) → Hinweis im Screen, die Session läuft weiter (HIG `feedback.md`: Feedback in der Oberfläche statt in Alerts).
- `ModelContainer` lässt sich beim Start nicht erzeugen → Fehler-Screen mit Meldung, kein `fatalError`.
- Kein stilles `try?`. Kein Force-Unwrap.

### 3.12 Lokalisierung

- Ein String Catalog (`Localizable.xcstrings`), Quellsprache Englisch, Übersetzungen Deutsch und Englisch.
- Ansagen, Coach-Sätze und Zeitformulierungen liegen ebenfalls im Catalog (Schlüssel z. B. `coach.demanding.filler.03`).
- Die Sprache der Sprachausgabe folgt der aktiven App-Lokalisierung.

### 3.13 Barrierefreiheit

- Dynamic Type bis zu den Accessibility-Größen; die Restzeit im Session-Screen skaliert mit.
- VoiceOver-Labels für Ring, Zeitwerte und alle Buttons; der Ring meldet die Restzeit als Wert.
- „Bewegung reduzieren“: Der Ring springt sekundenweise statt kontinuierlich zu animieren.
- Kontrast mindestens 4,5:1; Status nie nur über Farbe.
- Trefferflächen mindestens 44 × 44 pt; die Session-Buttons deutlich größer, weil das iPhone auf dem Boden liegt.

---

## 4. Architektur

### 4.1 Projektstruktur

```
ios/
  project.yml                     XcodeGen-Definition
  Planktrainer/
    App/          PlanktrainerApp, RootView, AppEnvironment, AppRouter
    Core/
      Session/        SessionConfiguration, SessionEngine (Zustandsautomat)
      Announcements/  AnnouncementPlanner, SpokenDurationFormatter, CoachStyle, PhraseCatalog, ShuffleBag
    Services/     SpeechAnnouncer (AVSpeechSynthesizer), AudioSessionController
    Persistence/  DatabaseSchemas, MigrationPlans, ModelContainer (Factory), Models/PlankSession, SessionStore
    Settings/     UserSettings
    Features/
      Training/  History/  SessionDetail/  ActiveSession/  Settings/
    Resources/    Localizable.xcstrings, Assets.xcassets
  PlanktrainerTests/              Swift Testing
```

- Quellen als `syncedFolder` (Xcode „Folder-synchronized Groups“): Neue oder gelöschte Dateien ändern weder `project.yml` noch `project.pbxproj`, deshalb können Agenten parallel arbeiten.
- Das generierte `ios/Planktrainer.xcodeproj` wird eingecheckt, weil Xcode Cloud es braucht. Wer `project.yml` ändert, führt `xcodegen generate` aus und committet beides zusammen; `project.pbxproj` wird nie von Hand bearbeitet.
- Build-Einstellungen:
  - `SWIFT_VERSION = 6`
  - `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`
  - `SWIFT_APPROACHABLE_CONCURRENCY = YES`
  - `SWIFT_STRICT_CONCURRENCY = complete`
  - `TARGETED_DEVICE_FAMILY = 1`
  - nur Portrait
  - `DEVELOPMENT_TEAM = 8HM2FV529D`

### 4.2 Abhängigkeiten

`AppEnvironment` nach dem Muster in `docs/swift/` (nur die Struktur, nicht der Inhalt):
- `@Observable`, einmal in `PlanktrainerApp` erzeugt und per `.environment(_:)` injiziert.
- Hält `userSettings` und `announcer`.
- Der `AppRouter` ist ein eigenes Environment-Objekt, der `ModelContainer` kommt über `.modelContainer(_:)`.

Services werden hinter Protokollen versteckt (z. B. `protocol Announcing { func speak(_ text: String); func stopSpeaking() }`), damit `SessionEngine` mit Test-Doubles testbar ist.

### 4.3 Kernkomponenten

| Komponente | Art | Aufgabe |
|---|---|---|
| `SessionEngine` | `@Observable` Klasse | Zustandsautomat aus 3.3. Uhr und `Announcing` sind injiziert. Liefert Zustand, Restzeit und Fortschritt für die UI sowie Haptik-Trigger (Zähler/Ereignisse für `.sensoryFeedback`). |
| `AnnouncementPlanner` | reine `struct` | Eingaben → sortierte Liste `ScheduledAnnouncement(elapsedSecond, kind, text)`; Regeln aus 3.4/3.5 |
| `SpokenDurationFormatter` | reine `struct` | Sekunden → gesprochene Zeit (de/en, mit/ohne „noch“) |
| `PhraseCatalog` + `ShuffleBag` | `struct` | Coach-Sätze pro Stil und Anlass, Ziehen ohne Wiederholung |
| `SpeechAnnouncer` | Klasse, `Announcing` | `AVSpeechSynthesizer` + Audio-Session-Aktivierung |
| `SessionStore` | Klasse | Speichern/Löschen über `ModelContext`, wirft typisierte Fehler |

Die UI liest Sessions per `@Query`. Die Ring-Animation rechnet den Fortschritt in einer `TimelineView` aus dem Engine-Zustand (Startzeitpunkt, Pausensumme) statt sekündlicher Updates.

### 4.4 Datenmodell (SwiftData)

Vorbereitet für eine spätere CloudKit-Synchronisierung:
- Alle gespeicherten Eigenschaften sind optional (Entscheidung des Nutzers).
- Kein `@Attribute(.unique)`; Beziehungen, falls sie hinzukommen, optional mit Inverse.
- Die Standardwerte stehen an genau einer Stelle: einer Erweiterung mit nicht-optionalen, berechneten Zugriffen. Views verwenden nur diese, damit `??` nicht über die Views verstreut wird.

`PlankSession` (Schema V1):

| Eigenschaft | Typ | Bedeutung |
|---|---|---|
| `id` | `UUID?` | stabile ID, später auch für das Backend |
| `startedAt` | `Date?` | Beginn der running-Phase |
| `endedAt` | `Date?` | Ende |
| `preparationSeconds` | `Int?` | Vorbereitungszeit |
| `plannedSeconds` | `Int?` | ursprüngliches Ziel |
| `extensionSeconds` | `Int?` | Summe der +10 s |
| `achievedSeconds` | `Int?` | aktive Zeit |
| `pauseCount` | `Int?` | Anzahl Pausen |

Abgeleitet (nicht gespeichert): `isGoalReached`. Der Rekord wird aus dem Maximum von `achievedSeconds` berechnet.

**Persistenz-Struktur nach der Vorlage `docs/swift/database/`:**

| Datei | Inhalt |
|---|---|
| `DatabaseSchemas.swift` | `enum DatabaseSchemaV1: VersionedSchema` (Version 1.0.0, Modell-Liste, `schema`), `let currentDatabaseSchema = DatabaseSchemaV1.schema`, `typealias PlankSession = DatabaseSchemaV1.PlankSession` |
| `MigrationPlans.swift` | `enum DatabaseMigrationPlan: SchemaMigrationPlan` mit `schemas = [DatabaseSchemaV1.self]`, `stages = []` |
| `Models/PlankSession.swift` | `extension DatabaseSchemaV1 { @Model final class PlankSession { … } }` (Abschnitt „MARK: - v1“; spätere Versionen kommen als weitere Erweiterung hinzu) |
| `ModelContainer.swift` | Erzeugung des Containers mit `currentDatabaseSchema` und `DatabaseMigrationPlan`, persistent und In-Memory (Previews, Tests) |

Bewusste Abweichungen von der Vorlage, wegen der Regeln zur Fehlerbehandlung:
- **Kein `fatalError`:** Die Container-Erzeugung ist eine `throws`-Funktion. Die App hält das Ergebnis und zeigt bei einem Fehler einen Fehler-Screen (3.11).
- **Kein `trySave()`:** Gespeichert wird mit `try context.save()` im `SessionStore`; Fehler gehen bis in die UI.
- **Kein Extension auf den App-Typ mit statischen Containern:** Eine eigene `enum ModelContainerFactory` mit `make(inMemory:) throws -> ModelContainer`. Den Preview-Container mit Beispieldaten gibt es nur für `#Preview`.
- **Eigenschaften des Modells optional** (CloudKit-Vorbereitung), im Gegensatz zum nicht-optionalen `MyEntity` der Vorlage.

---

## 5. Qualität und Tests

- **Swift Testing** für die Logik, **keine UI-Tests**:
  - `AnnouncementPlanner`: Tabellentests mit allen Beispielen aus 3.4, plus Mindestabstand, +10 s, Resume, Prioritäten, Halbzeit-Zusammenführung, Rekord- und Letzte-Session-Marken
  - `SpokenDurationFormatter`: de/en, Singular/Plural
  - `ShuffleBag`: keine Wiederholung bis zum Verbrauch, deterministisch mit Seed
  - `SessionEngine` mit Test-Uhr und Fake-`Announcing`: alle Zustandsübergänge, Auto-Pause, erreichte Zeit ohne Pausen, Ziel-erreicht-Logik
  - `UserSettings`: Persistenz mit eigener `UserDefaults`-Suite
  - Persistenz: In-Memory-Container, Speichern/Löschen, Rekord-Berechnung
- **Manuelle Geräte-Checkliste** nach dem Meilenstein:
  - Lautsprecher und AirPods
  - Musik einer anderen App wird geduckt und wieder laut
  - Stumm-Modus
  - Anruf
  - App-Wechsel und Sperrtaste (Auto-Pause)
  - Display bleibt an
  - Dynamic Type, Dark Mode, VoiceOver
  - Deutsch und Englisch
- **Abnahme pro Welle** durch den Tech Lead: Build grün, Tests grün, Review gegen diese Spezifikation und `CLAUDE.md`.

---

## 6. Design

- Das visuelle Design entsteht mit Claude Design auf Basis von `docs/spec/claude-design-brief.md`.
- Ablauf: Claude Design arbeitet parallel zu den Logik-Wellen des Implementierungsplans. Die UI-Welle startet erst mit den Design-Ergebnissen (Tokens und Screens).

---

## 7. Prozess

Siehe `CLAUDE.md`: Agenten-Workflow, Commits, Konventionen.

---

## 8. Offene Punkte

| Punkt | Verantwortlich |
|---|---|
| Vorlage für SwiftData-Migrationen | geliefert (`docs/swift/database/`), eingearbeitet in 4.4 |
| Gegenlesen der Coach-Texte (`announcement-phrases.md`) | Nutzer |
| Design-Ergebnisse von Claude Design | Nutzer / Claude Design |

---

## 9. Zurückgestellt (ohne Meilenstein)

### 9.1 Sprachsteuerung

Ursprünglich Teil von M1. Wurde herausgenommen, ist aber machbar. Analyse aus der Planung:

- **Kommandos:** Pause, Weiter, Stop, Abbrechen/Abbruch, „verlängern“ (+10 s, später „um X verlängern“ mit Zahlen-Parsing aus Ziffern und Zahlwörtern).
- **Fragen:** „Wie lange noch?“ (Restzeit), „Wie viel Zeit ist schon vergangen?“ (vergangene Zeit), in vielen Varianten.
- **Technik:** On-device-Erkennung mit `SpeechAnalyzer`/`SpeechTranscriber` (iOS 26). Intent-Erkennung über Schlüsselwörter auf normalisiertem Text statt fester Phrasenlisten, z. B. {„lange“, „noch“} / „übrig“ / „Restzeit“ → Restzeit; „vergangen“ / „geschafft“ / „schon rum“ → vergangene Zeit. Absicherung per Tabellentest. Ein On-device-LLM ist zu langsam und unnötig.
- **Echo:** Das Mikro hört die eigenen Ansagen. Gegenmittel: Voice Processing (Echo-Unterdrückung), Erkennung während der eigenen Ausgabe ignorieren, und kein Ansagetext darf ein Kommando-Wort enthalten (per Test abgesichert, z. B. „keine Pause“ verboten).
- **AirPods:** Ein aktives AirPods-Mikro schaltet auf das Telefonie-Profil (Musik mono/schlecht). Deshalb: Eingang über das iPhone-Mikro, Ausgabe über A2DP (`.allowBluetoothA2DP`).
- **Berechtigungen:** Mikrofon und Spracherkennung erst beim ersten Aktivieren abfragen. Ohne Freigabe funktioniert die App weiter wie in M1.
- **Easter Egg:** Auf „ich kann nicht mehr“ antwortet die App mit einer Ermutigung und der Restzeit.
- Kommandos sollen ohne Bestätigungsansage ausgeführt werden.

### 9.2 Weitere

- iCloud-Sync (Datenmodell ist vorbereitet)
- Apple Health (Workout speichern)
- Erinnerungs-Benachrichtigungen
- Widget, Live Activity
- **Plank-Varianten:** Unterarmstütz, hoher Plank, Seitstütz links/rechts, umgekehrter Plank, dynamische Varianten (Beinheben, Shoulder Taps, Plank Jacks, Spiderman-Plank). Umsetzung als neues Feld per leichter Migration, Rekorde pro Variante.
- Intervalle/Sätze (z. B. 3 × 45 s mit Pause)

### 9.3 Bewusst nicht geplant

- Streaks
- Abzeichen/Erfolge
