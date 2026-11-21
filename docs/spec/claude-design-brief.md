# Design-Brief für Claude Design: Plank-Trainer (iOS)

Stand: 2026-11-21 · Grundlage: `docs/spec/plank-trainer-spec.md` (Meilenstein 1)

Diesen Brief als Ganzes an Claude Design übergeben. Er beschreibt, was gestaltet werden soll, welche Grenzen gelten und in welcher Form die Ergebnisse gebraucht werden.

---

## 1. Auftrag

Gestalte das visuelle Design einer iPhone-App, die beim Planking (Unterarmstütz) begleitet. Die App zählt die Zeit herunter, macht Sprachansagen und hat einen Coach mit wählbarer Persönlichkeit. Sie zeigt einen Verlauf mit persönlichen Rekorden.

Die App soll **Spaß machen und motivieren** und gleichzeitig **unverkennbar eine native iOS-App** sein (iOS 26, Liquid Glass, SwiftUI-Systemkomponenten).

## 2. Nutzer und Situation

- Erwachsene, die regelmäßig kurz trainieren (Sessions von 10 s bis 10 min), meist allein zu Hause.
- **Während der Session liegt das iPhone auf dem Boden**, ca. 60–80 cm vom Gesicht entfernt, Blick schräg nach unten. Der Nutzer stützt sich auf die Unterarme und kann nur kurz tippen. Alles im Session-Screen muss aus dieser Distanz lesbar und mit einem schnellen, ungenauen Tipp bedienbar sein.
- Außerhalb der Session: normales Halten in einer Hand, kurze Interaktionen (Zeit wählen, Verlauf ansehen).
- Tonalität: sportlich, warm, mit Humor. Der Coach-Stil „Frech“ darf frech sein, das UI bleibt aber freundlich.
- **Bewusst ohne Streaks, Abzeichen und Gamification-Lärm.** Motivation kommt aus dem eigenen Rekord und dem Verlauf.

## 3. Plattform-Grenzen (nicht verhandelbar)

- iPhone, nur Portrait, iOS 26. Hell und Dunkel, dazu „Kontrast erhöhen“ und „Transparenz reduzieren“.
- Navigation und Steuerelemente nutzen Systemkomponenten: `TabView` mit Tab Bar (Liquid Glass), `NavigationStack`, `List`, `Form`, `Picker` im Wheel-Stil, `Toggle`, `Button`-Stile, `confirmationDialog`, `ContentUnavailableView`, Swift Charts.
  - Markenausdruck lebt in Farbe, Typografie, dem Ring und wenigen prägenden Momenten (HIG `branding.md`).
- **Liquid Glass** nur auf der schwebenden Funktionsebene (Tab Bar, Toolbars, Buttons über Inhalt), nie in Inhaltsflächen (HIG `materials.md`).
- **Typografie:** SF Pro bzw. SF Pro Rounded und SF Mono/Monospaced Digits für Zeiten. Keine eigenen Schriftdateien. Alles skaliert mit Dynamic Type bis zu den Accessibility-Größen.
- **Icons:** SF Symbols, gefüllte Varianten in der Tab Bar.
- **Kontrast:** Text mindestens 4,5:1, großer Text (≥ 18 pt bzw. fett) mindestens 3:1, in Hell und Dunkel. Status nie nur über Farbe.
- **Trefferflächen:** mindestens 44 × 44 pt. Im Session-Screen deutlich größer.
- **Bewegung:** sparsam und abschaltbar („Bewegung reduzieren“); nie der einzige Bedeutungsträger.
- Keine eigenen Sounds, keine Bild-Assets außer dem App-Icon.

## 4. Das prägende Element: der Ring

Ein **schrumpfender Fortschrittsring** wie im Apple-Timer, aber mit eigenem Charakter. Er ist das, woran man die App erkennt, und taucht an drei Stellen auf:
1. **Session-Screen (groß):** Der Ring läuft während der Session von voll nach leer. In der Mitte steht die Restzeit, riesig, mit Monospaced-Ziffern, aus 80 cm lesbar.
2. **Session-Detail (mittel):** erreichte Zeit im Verhältnis zum Ziel. Ein voller Ring heißt „geschafft“.
3. **Optional klein** im Verlauf oder auf dem Training-Tab als Rekord-Andeutung.

Bitte ausarbeiten:
- Strichstärke, Enden, Farbverlauf ja/nein, Hintergrundspur
- Pausen-Zustand: eingefroren, klar als pausiert erkennbar, **nicht nur über Farbe**
- letzte 5 Sekunden: dezente Steigerung
- Verlängerung (+10 s): Wie zeigt der Ring, dass Zeit dazugekommen ist?
- Abschluss-Moment: ein einziger orchestrierter Moment, der „geschafft“ bzw. „neuer Rekord“ feiert, mit Variante für „Bewegung reduzieren“

## 5. Screens und Zustände

UI-Texte sind deutsch (Hauptsprache). Englisch wird unterstützt, Layouts müssen längere englische bzw. deutsche Wörter vertragen.

### 5.1 Tab Bar
Drei Tabs: **Training** (`figure.core.training`), **Verlauf** (`chart.bar.fill`), **Einstellungen** (`gearshape.fill`). Die App startet auf Training.

### 5.2 Training (Start)
- Kompakte Info: „Rekord 2:15“ und „Zuletzt: gestern · 1:30 ✓“. Erststart-Variante ohne Daten.
- **Session-Zeit:** Wheel-Picker mit zwei Rädern (Minuten 0–10, Sekunden 0–55 in 5er-Schritten), inline.
- **Vorbereitungszeit:** Zeile „Vorbereitung · 10 s“, die beim Antippen inline einen Wheel-Picker aufklappt (5–60 s).
- **Start-Button:** groß, prominent, im Daumenbereich unten. Text „Session starten“.

### 5.3 Session (Vollbild, verdeckt die Tab Bar)

| Zustand | Inhalt | Bedienung |
|---|---|---|
| Vorbereitung | sehr große Countdown-Zahl (10…1), Text „Mach dich bereit“ | „Abbrechen“ |
| Läuft | Ring + Restzeit groß, vergangene Zeit klein, Coach-Stil-Andeutung optional | „Pause“, „Stop“, „+10 s“, „Abbrechen“ (sekundär) |
| Pausiert | eingefrorener Ring, „Pausiert“ | „Weiter“, „Stop“, „+10 s“, „Abbrechen“ |
| Weiter-Countdown | 3-2-1 über dem Ring | „Abbrechen“ |
| Ergebnis | erreichte Zeit, Ziel, geschafft/nicht geschafft, ggf. „Neuer Rekord!“ | „Fertig“ |
| Dialog | „Session verwerfen?“ (`confirmationDialog`) | „Verwerfen“ (destruktiv), „Weiter planken“ |
| Hinweis | nicht-blockierend: „Ansagen nicht verfügbar“ | – |

Anforderungen: Die Buttons sind vom Boden aus treffsicher, klar unterscheidbar und nicht zu dicht beieinander. „Stop“ (speichern) und „Abbrechen“ (verwerfen) dürfen nicht verwechselbar sein. Das Display bleibt die ganze Zeit an. Denke an Dark Mode in einem abgedunkelten Raum.

### 5.4 Verlauf
- **Diagramm** oben: Balken = erreichte Zeit der letzten 30 Sessions, horizontale Linie = Rekord. „Geschafft“ und „nicht geschafft“ sind unterscheidbar, nicht nur über Farbe.
- **Liste** darunter, neueste zuerst. Jede Zeile zeigt:
  - Datum/Uhrzeit (z. B. „Heute, 07:42“)
  - „1:30 / 1:30“ (erreicht / Ziel)
  - Status-Symbol
  - Rekord-Markierung
- Wischen zum Löschen.
- **Leerzustand:** freundlich, mit Aktion „Erste Session starten“.

### 5.5 Session-Detail (Push aus dem Verlauf)
- Mittlerer Ring (erreicht/Ziel).
- Werte: Datum, Ziel, erreicht, Vorbereitung, Pausen, Verlängerung, Abstand zum Rekord („Rekord“ bzw. „12 s unter deinem Rekord“).
- Button **„Nochmal mit gleicher Zeit“**.

### 5.6 Einstellungen
- **Erscheinungsbild:** System / Hell / Dunkel
- **Coach-Stil:** Ruhig / Fordernd / Frech / Aus, jeweils mit einer Zeile Beschreibung und einem Beispielsatz, z. B.:
  - Ruhig: „Ruhig weiteratmen.“
  - Fordernd: „Halt die Spannung!“
  - Frech: „Das Sofa ruft. Ignorier es.“
  - Aus: nur Zeitansagen
- **Haltungs-Hinweise** (Toggle)
- **Haptik** (Toggle)
- **Info:** Push mit Version, Lizenz (MIT) und Link zum Repository

### 5.7 App-Icon
Ein Konzept für das App-Icon: geschichtet, klare Formen, ohne Text, mit Varianten für Hell, Dunkel und getönt (HIG `app-icons.md`). Es soll den Ring aufgreifen dürfen.

## 6. Vermeiden

- Generische Fitness-App-Optik: Neon auf Schwarz, aggressive Rot-Orange-Verläufe, Stockfotos von Sixpacks.
- Aktuelle Vorlagen-Looks:
  - Creme mit Serifenschrift und Terrakotta
  - Fast-Schwarz mit einer Neonfarbe
  - Zeitungs-Layout mit Haarlinien
  - „Große Zahl über kleinem Label mit Verlaufsakzent“ als Standard-Hero
- Streak-Flammen, Abzeichen, Konfetti-Overload.
- Eigene Nachbauten von Systemkomponenten (eigene Tab Bar, eigene Picker).
- Eine Farbe mit mehreren Bedeutungen.

## 7. Gewünschte Ergebnisse

Bitte so liefern, dass Entwickler es 1:1 in SwiftUI übertragen können:

1. **Farb-Tokens:** 4–6 benannte Farben mit Rolle (Fläche, Inhalt, Akzent, Erfolg, Warnung/destruktiv, Pause). Je Hex-Wert für Hell, Dunkel und Hoher Kontrast, mit Kontrastwert gegenüber der jeweiligen Fläche. Wo möglich, auf Systemfarben aufsetzen (`.primary`, `.secondary`, `systemBackground` …) und das begründen.
2. **Typo-Skala:** Rolle → SwiftUI-Textstil (`.largeTitle` … `.caption`), Schriftbreite/-design (`.rounded`, `.monospaced`), Gewicht. Für die Session-Zeit ein eigener, mit Dynamic Type skalierender Stil.
3. **Abstände und Radien:** kleine Skala (z. B. 4/8/12/16/24/32).
4. **Ring-Spezifikation:** Maße relativ zur Bildschirmbreite, Strichstärke, Farben pro Zustand, Animation (Dauer, Kurve) und Variante für „Bewegung reduzieren“.
5. **Screens:** alle Zustände aus Abschnitt 5 in Hell und Dunkel, dazu mindestens Session-Screen und Training bei einer großen Accessibility-Textgröße.
6. **Haptik-/Bewegungs-Momente:** kurze Beschreibung des Abschluss- und Rekord-Moments.
7. **App-Icon-Konzept.**
8. **Begründung:** ein Absatz: Was ist die Idee, woran erinnert man sich, warum passt es zu Planking?
