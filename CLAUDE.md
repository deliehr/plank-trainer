# CLAUDE.md – Plank-Trainer

iOS-App, die beim Planking mit Ansagen und einem Coach begleitet. Später kommt ein Backend dazu.

- Spezifikation: `docs/spec/plank-trainer-spec.md`
- Ansage-Texte: `docs/spec/announcement-phrases.md`
- Design-Brief: `docs/spec/claude-design-brief.md`
- Pläne: `docs/plans/`

## Repository

| Pfad | Inhalt |
|---|---|
| `ios/` | iOS-App; Projekt per XcodeGen aus `ios/project.yml`; das generierte `.xcodeproj` ist eingecheckt (Xcode Cloud) |
| `backend/` | später: Java 25, Spring Boot 4, Maven, Postgres |
| `docs/spec/` | Spezifikation, Ansage-Texte, Design-Brief |
| `docs/plans/` | Implementierungspläne pro Meilenstein |
| `docs/swift/` | Struktur-Vorlagen (nur Muster übernehmen, nicht den Inhalt) |

## Befehle

Nach jeder Änderung an `ios/project.yml`: `cd ios && xcodegen generate` und `project.yml` und `Planktrainer.xcodeproj` zusammen committen. `project.pbxproj` nie von Hand bearbeiten. Quellordner sind `syncedFolder`; neue Dateien brauchen keine Projektänderung.

```sh
xcodebuild -project ios/Planktrainer.xcodeproj -scheme Planktrainer -destination 'platform=iOS Simulator,name=iPhone 17' build
xcodebuild -project ios/Planktrainer.xcodeproj -scheme Planktrainer -destination 'platform=iOS Simulator,name=iPhone 17' test
```

## Sprache

- Kommunikation mit dem Nutzer und **mit allen Code-Agenten auf Deutsch**.
- Code, Bezeichner, Kommentare, Log-/Fehlermeldungen, Test-Namen und Commit-Messages auf **Englisch**.
- Nutzer-sichtbare Texte stehen im String Catalog (Quellsprache Englisch, Übersetzungen Deutsch und Englisch).

## Code-Regeln

- SOLID, KISS, DRY, YAGNI, wo sinnvoll.
- So wenige Kommentare wie möglich; nur bei schwer nachvollziehbaren Berechnungen.
- **Kein Force-Unwrap** (`!`, `try!`, `as!`) und kein stilles `try?`.
- **Fehlerbehandlung:** Services werfen typisierte Fehler (`LocalizedError`). Gefangen und angezeigt wird ausschließlich in der UI-Schicht: Alert bei vom Nutzer ausgelösten Aktionen, Inline-Hinweis bei nicht-blockierenden Problemen. Kein `fatalError` für erwartbare Fehler.
- Swift 6, Default-Isolation `MainActor`, strikte Concurrency.
- **Benutzen:** `@Observable`, `NavigationStack`, `@Query`, Swift Charts, async/await, SwiftUI `.sensoryFeedback`.
- **Nicht benutzen:** Combine, `ObservableObject`/`@Published`, UIKit-Views. Erlaubt ist `UIApplication.shared.isIdleTimerDisabled`.
- Keine Drittanbieter-Pakete.
- iPhone only, Portrait only, iOS 26+.

## Architektur (Kurzfassung, Details in der Spezifikation Abschnitt 4)

- `AppEnvironment` (`@Observable`, per `.environment` injiziert) hält App-weite Dependencies, nach dem Muster in `docs/swift/`.
- `AppRouter` (`@Observable`): Tabs mit je einem `NavigationStack` und genau einer Push-Ebene; Sheets und `fullScreenCover` werden zentral in der `RootView` präsentiert.
- Logik (Ansageplan, Zeitformatierung, Session-Zustandsautomat) als testbare Typen ohne UI-Abhängigkeit; Systemdienste hinter Protokollen.
- **SwiftData:**
  - immer über `VersionedSchema` und `SchemaMigrationPlan`, Struktur nach `docs/swift/database/` (Abweichungen: Spezifikation 4.4)
  - CloudKit-tauglich: alle gespeicherten Eigenschaften optional, kein `@Attribute(.unique)`, Beziehungen optional mit Inverse
  - Standardwerte an genau einer Stelle (Erweiterung mit berechneten Zugriffen)
- Netzwerk (ab Backend-Meilenstein): Requests gebündelt in einem Client-Package; Modelle werden aus der OpenAPI-Spec des Backends abgeleitet (das Backend ist die Single Source of Truth).

## UI

- Die Human Interface Guidelines beachten. Für UI-Pläne und UI-Reviews **muss die Skill `apple-design` geladen werden**. Fehlt sie, abbrechen und darauf hinweisen.
- Systemkomponenten für Navigation und Steuerelemente; Design-Tokens aus den Ergebnissen von Claude Design.
- Dynamic Type, VoiceOver, „Bewegung reduzieren“, Kontrast ≥ 4,5:1, Status nie nur über Farbe.

## Tests

- Swift Testing für Logik. **Keine UI-Tests.**
- Nach jedem Meilenstein: alle Tests plus die manuelle Geräte-Checkliste aus der Spezifikation (Abschnitt 5).

## Arbeitsweise mit Agenten

- **Implementierungspläne** schreibt ein Opus-Modell mit Effort High. Sie sind auf parallele Umsetzung optimiert: Wellen mit unabhängigen Aufgaben, eindeutige Dateizuständigkeiten, klare Akzeptanzkriterien.
- **Umsetzung** durch mehrere parallele Subagenten mit Modell Sonnet 5.5 und Effort Medium; Aufträge an Agenten auf Deutsch.
- **Tech Lead** ist ein Opus-Modell mit Effort High. Es nimmt jede Welle ab: Build grün, Tests grün, Review gegen Spezifikation und diese Datei.
- Ein Implementierungsplan umfasst immer nur den aktuell freigegebenen Meilenstein.

## Git

- Conventional Commits 1.0.0 (`feat:`, `fix:`, `docs:`, `chore:`, `test:`, `refactor:` …, optional mit Scope, z. B. `feat(session): …`).
- Ein Commit pro Aufgabe; Abnahme pro Welle.
- Lizenz: MIT (`LICENSE`).
