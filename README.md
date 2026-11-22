# Plank-Trainer

iPhone-App, die beim Planking begleitet: Sie sagt die Zeit an, feuert mit einem Coach mit Persönlichkeit an und zeigt einen ehrlichen Verlauf mit Rekorden. Während der Session muss niemand aufs Display schauen.

Offline und privat: keine Konten, kein Netzwerk, keine Berechtigungsabfragen. Keine Streaks, keine Abzeichen.

<p>
  <img src="docs/design/screens/10-training-01-training-hell.png" width="200" alt="Training">
  <img src="docs/design/screens/20-session-02-laeuft-hell.png" width="200" alt="Laufende Session">
  <img src="docs/design/screens/30-verlauf-01-verlauf-hell.png" width="200" alt="Verlauf">
  <img src="docs/design/screens/40-einstellungen-01-einstellungen-hell.png" width="200" alt="Einstellungen">
</p>

<sub>Design-Mockups aus <code>docs/design/screens/</code>; die App verwendet die echten Systemkomponenten.</sub>

## Funktionen (Meilenstein 1)

- **Session** mit Vorbereitungszeit, schrumpfendem Ring, Pause, Stop, +10 s und Auto-Pause bei App-Wechsel oder Anruf
- **Zeit-Ansagen** per Sprachausgabe, auch im Stumm-Modus; fremde Musik wird währenddessen leiser
- **Coach** mit vier Stilen: Ruhig, Fordernd, Frech, Aus; optional Haltungs-Hinweise
- **Verlauf** mit Diagramm (Swift Charts), Rekord und Session-Detail
- **Haptik**, Hell/Dunkel, Deutsch und Englisch
- Barrierefrei: Dynamic Type, VoiceOver, „Bewegung reduzieren“

## Voraussetzungen

- Xcode mit iOS 26 SDK oder neuer
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (nur für Änderungen an `ios/project.yml`): `brew install xcodegen`
- iPhone oder iPhone-Simulator mit iOS 26+

## Bauen und testen

```sh
open ios/Planktrainer.xcodeproj
```

Oder über die Kommandozeile:

```sh
xcodebuild -project ios/Planktrainer.xcodeproj -scheme Planktrainer \
  -destination 'platform=iOS Simulator,name=iPhone 17' build

xcodebuild -project ios/Planktrainer.xcodeproj -scheme Planktrainer \
  -destination 'platform=iOS Simulator,name=iPhone 17' test
```

Für ein eigenes Gerät in Xcode unter *Signing & Capabilities* das eigene Team wählen.

Das Xcode-Projekt wird aus `ios/project.yml` erzeugt und ist eingecheckt (Xcode Cloud). Nach jeder Änderung an `project.yml`:

```sh
cd ios && xcodegen generate
```

`project.yml` und `Planktrainer.xcodeproj` gehören in denselben Commit. Die Quellordner sind synchronisiert; neue Swift-Dateien brauchen keine Projektänderung.

## Technik

- Swift 6 mit strikter Concurrency, Default-Isolation `MainActor`
- SwiftUI, SwiftData (versioniertes Schema, CloudKit-tauglich), Swift Charts, Swift Testing
- `AVSpeechSynthesizer` für die Ansagen
- Keine Drittanbieter-Pakete
- Nur iPhone, nur Portrait

## Projektstruktur

| Pfad | Inhalt |
|---|---|
| `ios/Planktrainer/App` | Einstieg, `AppEnvironment`, `AppRouter`, `RootView` |
| `ios/Planktrainer/Core` | UI-unabhängige Logik: Ansageplan, Session-Zustandsautomat, Zeitformatierung |
| `ios/Planktrainer/Features` | Screens: Training, laufende Session, Verlauf, Detail, Einstellungen |
| `ios/Planktrainer/Services` | Sprachausgabe und Audio-Session |
| `ios/Planktrainer/Persistence` | SwiftData-Schemas, Migrationen, `SessionStore` |
| `ios/Planktrainer/DesignSystem` | Farben, Schriften, Maße, Fortschrittsring |
| `ios/PlanktrainerTests` | Tests (Swift Testing, keine UI-Tests) |
| `docs/spec` | Spezifikation, Ansage-Texte, Design-Brief |
| `docs/design` | Design-Spezifikation, Mockups, Tokens |
| `docs/plans` | Implementierungspläne und Backlog |

## Dokumentation

- [Spezifikation](docs/spec/plank-trainer-spec.md)
- [Ansage- und Coach-Texte](docs/spec/announcement-phrases.md)
- [Design-Spezifikation](docs/design/DESIGN.md)
- [Backlog](docs/plans/backlog.md)

## Ausblick

| Meilenstein | Inhalt |
|---|---|
| M1 | Sessions mit Ansagen, Coach, Verlauf, Rekorden |
| M2 | Video-Unterstützung, Körperhaltung per Vision |
| M3 | Apple Watch |
| M4 | Wettbewerb mit Freunden; Backend mit Java 25, Spring Boot 4, Postgres |

M2 bis M4 sind noch nicht final.

## Lizenz

[MIT](LICENSE)
