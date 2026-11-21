Ich möchte eine iOS App entwickeln und gemeinsam mit dir die Umsetzung planen: eine Planking App. Stelle so viele Rückfragen wie möglich.
Die App soll Spaß machen und der Motivation dienen.

# Generell

- Implementierungspläne schreibt immer ein Opus Model mit Effort High
- Implementierungspläne sind auf parallele Umsetzung hin zu optimieren. Dabei sollen im optimalen Fall mehrere Subagenten mit Model Sonnet 5.5 mit Effort Medium ausgeführt werden.
- Ein Opus Model mit Effort High nimmt die Arbeit ab, quasi als Technical Lead
- Nach der Umsetzung eines Meilensteins wird getestet.
- Schreibe cleanen Code nach SOLID, KISS, DRY und YAGNI wenn sinnvoll
- Schreibe so wenig Kommentare wie möglich, nur wenn nötig bei schwer nachvollziehbaren Berechnungsschritten
- Code ausschließlich in Englisch, Kommentare in Englisch
- Die Kommunikation mit Code Agenten immer auf Deutsch
- Achte auf klare Fehlerbehandlung, Exceptions sollen immer in die UI durchgereicht werden, wo sie abgefangen werden müssen
- Hinterfrage meine Vorschläge konstruktiv, wenn eine einfachere, robustere oder architekturtechnisch passendere Lösung existiert
- Vermeide force unwrapping von Optionals
- Lege eine CLAUDE.md an
- Lege eine passende gitignore Datei für beide Projekttypen an.
- Beachte bei der Implementierung der UI/der iOS App die Human Interface Guidelines, dafür gibt es extra einen Skill (apple-design-skill). Der Skill soll geladen werden, um den Implementierungsplan aufzustellen. Gibt es den Skill nicht, breche ab und gebe einen Hinweis aus
- Output dieser Planung: 
    - a) Ein Implementierungsplan, den Sonnet 5.5-Medium Subagenten verstehen und ausführen können
    - b) Eine größer gefasste Spezifikation, eventuell für Claude Code Design
- Eine Lizenzbestimmung muss noch zum Repository hinzugefügt werden
- Commits nach dem Convential Commits Style: https://www.conventionalcommits.org/en/v1.0.0/#specification
- Ein Implementierungsplan soll erstmal nur Meilenstein 1 berücksichtigen, die Planung für anderen Meilensteine ist noch nicht abgeschlossen

## Technik

### iOS App

- Geräteklasse: Erstmal nur iPhone
- Ausrichtung: Erstmal nur Portrait
- Swift-Version: Swift 6 mit MainActor als Standard-Isolation.
- Datenbank: Swift Data
- UI via SwiftUI
- Minimale iOS Version: 18
- Benutzen: @Observable, NavigationStack, @Query, Swift Charts, async/await. 
- Nicht benutzen: Combine, ObservableObject, UIKit-Views
- Vermeiden: Drittanbieter-Pakete.
- Das Xcode projekt der App soll im Ordner "ios" liegen.
- CI/CD über Xcode Cloud / Testflight 

#### Architektur

- Für eventuelle Netzwerk Requests bündel diese in einem Client/Package. Leite Model-Klassen aus der OpenAPI Spec des Backends ab. Das Backend ist die Single Source of Truth.
- Verwende zur Navigation einen AppRouter (NavigationStack) mit den Abstraktionen push, sheet, aktuell gibt es nur eine Ebene, siehe dir dazu https://github.com/Dimillian/AppRouter an. Da es nur eine Navigationsebene gibt, kannst du das Modell vereinfachen, bitte mit mir diskutieren wie du das vorhast
- App-weite Dependencies einbetten wie in docs/swift/Dependencies.swift, lese auch die AppEnvironment.swift und UserSettings.swift dazu. Das sind nur Vorlagen/Beispiele, es soll nur die allgemeine Struktur übernommen werden

#### Datenbank

- Swift Data verwenden
- Datenbank vorbereiten, sodass später Migrationen ohne Probleme möglich sind
- Dazu die Vorlage aus ???

### Backend

- Das spätere Backend soll im Ordner "backend" liegen
- Das Backend soll via Java 25, Maven (pom.xml) und Spring Boot 4 umgesetzt werden
- Datenbank: Postgres

# Meilenstein 1:

Eine iOS Planking App, welche mich beim Planking unterstützt, Ansagen macht und sich per Voice steuern lässt. Eine Planking Session soll gestartet werden können mit einer Vorbereitungszeit (default 10 Sekunden) und einer Session Zeit (default: 1 Minute). Beide Zeiten sollen jedes mal eingestellt werden können, wobei die vorher eingestellte Session Zeit die neue Default-Zeit ist.
Während der Vorbereitungszeit und der Planking Session wird durch Ansagen unterstützt. Bevor die Planking Session beginnt wird ein Countdown angezeigt und vorgelesen. Die eigentliche Planking Session wird ebenfalls optisch durch einen immer kleiner werdenden Kreis (ähnlich Apple Timer) angezeigt und auch angesagt: 

"Planking Session" gestartet, noch 60 Sekunden
Spätestens nach 30 Sekunden gibt es immer eine Ansage
Dann bei der Hälfte, "noch 30 Sekunden"
Dann wieder bei der Hälfte, "noch 15 Sekunden"
Ab Sekunde 10 wird runtergezählt bis auf 0.

Beispiel: Planking Zeit = 1 Minute, Ansagen: 

"Planking Session gestartet, noch 60 Sekunden"
"Noch 30 Sekunden"
"Noch 15 Sekunden"
"Noch 10 Sekunden"
"5"
"4"
"3"
"2"
"1"
"Planking Session abgeschlossen"

Beispiel: Planking Zeit = 2 Minuten und 30 Sekunden, Ansagen: 

"Planking Session gestartet, noch 2 Minuten und 30 Sekunden"
"Noch 2 Minuten"
"Noch 1 Minute 30"
"Noch 1 Minute"
Der Rest analog zu den Ansagen für 1 Minute.

Während der Planking Session hört die App auf Kommandos wie Pause, Stop, Abbrechen oder Abbruch. Auch eine Nachfrage wie "wie lange noch" oder "wieviel Zeit ist schon vergangen" soll die App dann beantworten können.

Für die Nachfragen "wie lange noch" und "wieviel Zeit ist schon vergangen" sollen möglichst viele Varianten und Abwandlungen hinterlegt werden. Es kann sein, dass dieser Punkt wieder aufgrund schlechter technischer Umsetzbarkeit wieder verworfen werden muss.

Die Planking Sessions werden in einer Liste angezeigt.

Ich bin am überlegen, Voice-Funktionen wie "verlängern" mit reinzunehmen. Bitte diskutiere das mit mir auf technische Machbarkeit.

Ich bin am überlegen, mental-unterstützende Ansagen zu ergänzen in der Art wie "du schaffst das", "gut gemacht", oder "nur noch 10 Sekunden" für die Motivation. Was fällt dir dazu ein?

Vewende als zentrales Navigationselement eine Tab View.

Ich möchte mir auch von Claude Design ein Design entwickeln lassen. Wann soll das Design erstellt werden, nach dem Implementierungsplan? Oder du erstellst eine umfassende Spezifikation / Prompt für Claude Design, für die iOS App? Siehe Outputs.

# Meilenstein 2:

- NICHT FERTIG -

Video Unterstützung
Vision human body pose estimation
https://developer.apple.com/documentation/vision/detecting-human-body-poses-in-images
https://developer.apple.com/documentation/vision/vnhumanbodyposeobservation

# Meilenstein 3:

- NICHT FERTIG -

Apple Watch

# Meilenstein 4:

- NICHT FERTIG -

Kompetitiv via Freunde/Einladung
WebSockets, Live Updates & REST
CI/CD gitlab
Portainer compose skript
traefik
watchtower