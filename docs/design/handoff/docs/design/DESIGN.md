# Plank-Trainer – Design-Spezifikation für die Umsetzung (Meilenstein 1)

Stand: 2026-11-21 · Quelle: Design-Canvas „Plank-Trainer“ · Grundlage: `docs/spec/plank-trainer-spec.md`

Dieses Dokument ist die verbindliche Vorlage für die SwiftUI-Umsetzung. Die PNGs unter `docs/design/screens/` zeigen das Ziel visuell. Bei Widersprüchen gilt dieses Dokument.

## 0. So arbeitest du damit

1. Kopiere `PlankTrainer/DesignSystem/*.swift` ins App-Target. Alle Farben, Schriften, Abstände, Ring-Maße und Animationen kommen von dort. Keine Hex-Werte oder Magic Numbers in Views.
2. Setze die Screens in der Reihenfolge von Abschnitt 6 um. Vergleiche jeden Screen mit seinen PNGs (Hell und Dunkel).
3. Arbeite die Checkliste in Abschnitt 10 ab.

**Wichtig zu den PNGs:** Die Mockups wurden im Browser gerendert. Sie nutzen Ersatzschriften statt SF Pro und nachgezeichnete Symbole statt SF Symbols. Wheel-Picker, Toggles, Segment-Picker, Tab Bar, Listen und Dialog sind Annäherungen an die Systemkomponenten. **Immer die echte Systemkomponente verwenden**, nie das Mockup nachbauen. Maßgeblich sind Farben, Größen, Abstände, Texte und Anordnung.

## 1. Idee

Beim Planken ist der Körper eine gerade Linie, die man hält. Die App zeigt das als einen ruhigen Ring in Iris-Violett, der sich wie die Kraft leert. Oben auf dem Ring liegt quer eine kleine Capsule, die **Waagemarke** (das Brett, die gerade Linie). Sie ist das Wiedererkennungsmerkmal von Session-Screen bis App-Icon. Alles andere ist iOS-Standard. Der eine große Moment: Der Ring schließt sich und wird grün; bei einem neuen Rekord legt sich eine zweite dünne Bahn um ihn. Keine Streaks, keine Abzeichen, kein Konfetti.

Drei Regeln:

- **Eine Farbe, eine Bedeutung.** Iris = läuft/Aktion, Moos = geschafft, Bernstein = pausiert, Signal = verwerfen/löschen.
- **Vom Boden lesbar.** Im Session-Screen ist alles mindestens doppelt so groß wie sonst.
- **Status nie nur über Farbe.** Jeder Zustand hat zusätzlich Form (gestrichelt, Häkchen, Symbol) und Text.

## 2. Farb-Tokens (`PlankColors.swift`)

Text, Listen und Formulare nutzen Systemfarben: `.primary`, `.secondary`, `Color(.systemBackground)`, `Color(.systemGroupedBackground)`, `Color(.secondarySystemGroupedBackground)`. Eigene Farben gibt es nur für Bedeutung. App-Tint: `.tint(.plankIris)` am Root.

| Token | Rolle | Hell | Dunkel | HC Hell | HC Dunkel |
|---|---|---|---|---|---|
| `plankMatte` | Fläche, **nur Session-Screen** | #F5F3FC | #0B0A12 | #FFFFFF | #000000 |
| `.primary` | Inhalt | #000000 (19,0:1) | #FFFFFF (19,6:1) | 21:1 | 21:1 |
| `plankIris` | Akzent, Ring läuft, Tint | #5B3FD9 (6,1:1) | #A496FF (7,9:1) | #3F25B8 (9,7:1) | #C2B8FF (11,6:1) |
| `plankMoss` | Erfolg / geschafft | #1E7F45 (4,6:1) | #3DD67A (10,4:1) | #136434 (7,2:1) | #6BEA9E (13,9:1) |
| `plankAmber` | Pause | #9A5B00 (4,9:1) | #FFB547 (11,2:1) | #7A4700 (7,7:1) | #FFCB7A (14,1:1) |
| `plankSignal` | Destruktiv | #C8261B (5,1:1) | #FF6B61 (7,1:1) | #B0170C (7,1:1) | #FF9890 (10,1:1) |

Kontrast jeweils gegen `plankMatte` bzw. bei HC gegen Weiß/Schwarz. Auf `systemGroupedBackground` (#F2F2F7) und `secondarySystemGroupedBackground` dunkel (#1C1C1E) bleiben alle Paare ≥ 4,5:1.

- Text auf Iris-Flächen: `plankOnIris` (hell Weiß 6,7:1, dunkel #0B0A12 7,9:1).
- Warum eigene Farben statt `systemGreen`/`systemOrange`/`systemRed`: diese erreichen auf Weiß als Text nur ca. 2,2:1 bzw. 3,6:1.

## 3. Typografie (`PlankTypography.swift`)

Nur SF Pro / SF Pro Rounded, Ziffern immer `.monospacedDigit()`. Alles skaliert mit Dynamic Type.

| Rolle | SwiftUI |
|---|---|
| Session-Zeit | `.sessionTimeFont()`: 96 pt semibold rounded, @ScaledMetric relativ zu `.largeTitle`, begrenzt 72–150 pt |
| Countdown (Vorbereitung, 3-2-1) | `.countdownFont()`: 160 pt bold rounded, begrenzt 120–200 pt |
| Screen-Titel | System-Navigation, großer Titel |
| Ergebnis-Headline | `.plankResultHeadline` (`.title`, rounded, bold) |
| Rekordwert, Detailwerte | `.plankRecordValue` (`.title2`, rounded, semibold, monospacedDigit) |
| Session-Tasten | `.plankSessionButton` (`.title3`, rounded, semibold) |
| Zeilentitel | `.headline` |
| Fließtext | `.body` |
| Zeiten in Listen | `.plankListTime` |
| Sekundärtext | `.subheadline` + `.foregroundStyle(.secondary)` |
| Chart-Achsen | `.plankChartAxis` |

## 4. Abstände und Radien (`PlankMetrics.swift`)

Abstände: 4 · 8 · 12 · 16 · 24 · 32, dazu 48 nur im Session-Screen. Radien: Listen und Gruppen über Systemformen (inset grouped, `ConcentricRectangle`). Tasten im Session-Screen sind Capsules.

## 5. Der Ring (`RingMetrics`, `PlankMotion`)

Siehe `screens/01-ring-uebersicht.png`.

**Geometrie**

- Session: Durchmesser D = 0,78 × Bildschirmbreite, max. 340 pt (390 pt Breite → 304 pt). Strich 7,5 % von D (≈ 23 pt). Ab Accessibility-Textgrößen: D = 0,92 × Breite.
- Session-Detail: D = 0,5 × Breite, Strich 8 %.
- Mini (Training-Kopf, optional Verlauf): 28 pt, Strich 4 pt, ohne Waagemarke.
- Bogen beginnt bei 12 Uhr und liegt **gegen den Uhrzeigersinn**. Mit fortschreitender Zeit läuft der Kopf im Uhrzeigersinn zurück zur Waagemarke. Umsetzung: `Circle().trim(from: 0, to: progress).stroke(style: StrokeStyle(lineWidth:, lineCap: .round)).rotationEffect(.degrees(-90)).scaleEffect(x: -1)`.
- Hintergrundspur: gleiche Farbe wie der Bogen, Deckkraft 16 % (hell) / 22 % (dunkel), 30 % bei „Transparenz reduzieren“ oder „Kontrast erhöhen“ (`RingTrackOpacity`).
- Waagemarke: Capsule 0,13 D × 0,03 D, Farbe `.primary`, mittig auf der Spur bei 12 Uhr, immer über dem Bogen. Immer sichtbar außer beim Mini-Ring.
- Kein Farbverlauf.
- Fortschritt kontinuierlich über `TimelineView(.animation)`, keine Sprünge pro Sekunde.

**Zustände (Farbe + Form + Text)**

| Zustand | Bogen | In der Mitte |
|---|---|---|
| Läuft | `plankIris`, durchgezogen, runde Enden | Restzeit, darunter „von 1:30“ |
| Letzte 5 s | wie Läuft, Strich 9 % von D | Restzeit pulsiert 1,00 → 1,04 → 1,00 pro Sekunde |
| Pausiert | `plankAmber`, gestrichelt (Strich 0,6 × / Lücke 0,45 × Strichbreite, `lineCap: .butt`), Spur in Bernstein | Symbol `pause.fill` + „Pausiert“ über der eingefrorenen Zeit |
| +10 s | Bogen wächst; der neue Anteil 1 s lang mit 55 % Deckkraft und 2 pt Kerbe, dann verschmilzt er | Chip „+10 s“ für 2 s |
| Geschafft | voll, `plankMoss` | `checkmark` + erreichte Zeit + „Ziel 1:30“ |
| Neuer Rekord | wie Geschafft, zusätzlich äußere Bahn `plankIris`, 3 pt, 6 pt Abstand | wie Geschafft; darunter Plakette „Neuer Rekord!“ mit `trophy.fill` |

## 6. Screens

Alle UI-Texte deutsch (Hauptsprache), über String Catalog lokalisierbar; Englisch muss ins Layout passen (keine festen Breiten für Text).

### 6.1 Tab Bar

`TabView` mit System-Tab-Bar (Liquid Glass). Tabs: **Training** (`figure.core.training`), **Verlauf** (`chart.bar.fill`), **Einstellungen** (`gearshape.fill`). Start auf Training.

### 6.2 Training (`screens/10-training-*.png`)

`NavigationStack` mit großem Titel „Training“, Inhalt als `Form`/`List` (inset grouped).

1. **Info-Zeile:** Mini-Ring (Fortschritt = letzte Zeit / Rekord), daneben „Rekord 2:15“ (`.plankRecordValue`) und darunter „Zuletzt: gestern · 1:30“ + `checkmark.circle.fill` in `plankMoss` (bzw. Symbol für nicht geschafft, siehe 6.4). Erststart: leerer Mini-Ring, „Noch kein Rekord“, „30 Sekunden sind ein guter Anfang.“
2. **Abschnitt „Session-Zeit“:** `Picker` im Stil `.wheel`, zwei Räder nebeneinander: Minuten 0–10 („Min“), Sekunden 0–55 in 5er-Schritten („s“). 0:00 ist nicht startbar (Taste deaktiviert). Erststart-Vorgabe 0:30.
3. **Zeile „Vorbereitung“** mit Wert „10 s“ rechts. Antippen klappt inline einen Wheel-Picker 5–60 s (5er-Schritte) auf; Wert dann in `plankIris`, Chevron dreht nach unten.
4. **Start-Taste** „Session starten“ mit `play.fill`: `.buttonStyle(.glassProminent)`, volle Breite, Höhe 64, in `.safeAreaInset(edge: .bottom)` direkt über der Tab Bar.

Accessibility-Größen (`10-training-05`): Info-Zeile stapelt, Vorbereitungs-Zeile bricht zweizeilig um, Start-Taste min. 88 pt hoch und bleibt angeheftet, Inhalt scrollt.

### 6.3 Session (`screens/20-session-*.png`)

Vollbild über der Tab Bar (`.fullScreenCover`). Hintergrund `plankMatte`. `UIApplication.shared.isIdleTimerDisabled = true` während der Session. Alle Tasten schweben über Inhalt → Liquid Glass erlaubt.

**Feste Anordnung (verhindert Verwechslungen):**

- Oben links: **„Abbrechen“** (`xmark` + Text), `.buttonStyle(.glass)`, Höhe 48. Löst immer den Bestätigungsdialog aus. Einzige Stelle zum Verwerfen.
- Oben rechts (nur Läuft/Pausiert, optional): Coach-Hinweis „Coach: Frech“ mit `bubble.left`, sekundär, nicht interaktiv.
- Mitte: Ring, Oberkante 176 pt bei 844 pt Höhe; darunter Zeilen (vergangene Zeit, letzte Coach-Zeile kursiv).
- Unten, 20 pt Rand, 40 pt über Unterkante:
  - Primär **„Pause“** (`pause.fill`) bzw. **„Weiter“** (`play.fill`): `.glassProminent`, volle Breite, Höhe 88.
  - Darunter zwei Tasten nebeneinander, Höhe 72, 16 pt Abstand: links **„+10 s“** (`plus`), rechts **„Stop“** (`stop.fill`) mit zweiter Zeile „speichern“. Beide `.glass`.
- Ab Accessibility-Größen (`10-training-06`): Ring 0,92 × Breite, Tasten untereinander (96/76/76 pt), „Stop & speichern“ einzeilig, vergangene Zeit und Coach-Zeile ausgeblendet (bleiben im VoiceOver-Label des Rings).

| # | Zustand | Inhalt | Bedienung |
|---|---|---|---|
| 1 | Vorbereitung | Countdown-Zahl in `plankIris` (`.countdownFont()`), „Mach dich bereit“, „Ziel 1:30 · Start mit Ansage“; unten Hinweis „iPhone flach vor dich legen. Unterarme auf den Boden, Körper in eine Linie.“ mit Waagemarken-Glyphe | nur „Abbrechen“ |
| 2 | Läuft | Ring Iris, Restzeit, „von 1:30“, „0:34 vergangen“, Coach-Zeile kursiv | Pause, +10 s, Stop, Abbrechen |
| 3 | Pausiert | Ring Bernstein gestrichelt, Pause-Symbol + „Pausiert“, eingefrorene Zeit, „Ansagen pausiert“ | Weiter, +10 s, Stop, Abbrechen |
| 4 | Weiter-Countdown | Ring wie Pausiert mit 30 % Deckkraft, große Ziffer 3-2-1 in Iris darüber, „Weiter in …“ | nur Abbrechen |
| 5 | Dialog | `confirmationDialog("Session verwerfen?", …)`, Nachricht „Die bisherige Zeit wird nicht gespeichert.“, Aktionen „Verwerfen“ (`role: .destructive`) und „Weiter planken“ (`role: .cancel`). Timer läuft während des Dialogs weiter. | – |
| 6 | Hinweis | Nicht blockierende Glass-Capsule oben mittig „Ansagen nicht verfügbar“ mit `speaker.slash.fill`, verschwindet nach 4 s, Session läuft normal | – |
| 7 | Ergebnis: geschafft / Rekord | Ring Moos voll + Häkchen, erreichte Zeit, „Ziel 1:30“; Headline „Geschafft“; Zeile „15 s über dem alten Rekord (1:30)“; Plakette „Neuer Rekord!“ (`trophy.fill`, Iris auf Iris 12–18 %) | „Fertig“ (`.glassProminent`, Höhe 88) |
| 8 | Ergebnis: nicht geschafft | Ring Iris mit erreichtem Anteil, erreichte Zeit, „von 1:30“; Headline „Gut gehalten“; „Noch 32 s bis zum Ziel“; „Gespeichert im Verlauf“ | „Fertig“ |

Ohne Rekord entfallen in Zustand 7 äußere Bahn, Rekordzeile und Plakette.

### 6.4 Verlauf (`screens/30-verlauf-*.png`)

`NavigationStack`, Titel „Verlauf“, `List` inset grouped.

- **Diagramm** (Swift Charts, eigene Section oben): Titel „Letzte 30 Sessions“, rechts „Ø 1:12“. `BarMark` pro Session (erreichte Zeit), älteste links.
  - Geschafft: gefüllt `plankMoss`.
  - Nicht geschafft: nur Kontur (1,5 pt) in `.secondary`, ohne Füllung.
  - Rekord: `RuleMark` gestrichelt (5/4) in `.primary`, Beschriftung „2:15“ rechts.
  - Y-Achse rechts, Werte als m:ss. Legende darunter: „geschafft“, „nicht geschafft“, „Rekord“.
- **Liste**, neueste zuerst. Zeile:
  - links Status-Symbol: `checkmark.circle.fill` in `plankMoss` (geschafft) bzw. `circle.lefthalf.filled` in `.secondary` (nicht geschafft); jeweils mit `accessibilityLabel`.
  - Titel „1:30 / 1:30“ (`.plankListTime`), Untertitel Datum („Heute, 07:42“, „Gestern, 18:10“, sonst „Mo., 16. Nov., 07:35“).
  - Rekord: im Untertitel „· Rekord“ mit `trophy.fill`, beides `plankIris`.
  - Chevron → Push auf Detail.
- **Löschen:** `.swipeActions` mit `Button(role: .destructive)` „Löschen“ (`trash.fill`), Vollwisch erlaubt.
- **Leerzustand:** `ContentUnavailableView` mit leerem Ring (Spur + Waagemarke) als Bild, Titel „Noch keine Sessions“, Beschreibung „Hier erscheinen deine Zeiten und dein Rekord. Die erste Linie hältst du gleich.“, Aktion „Erste Session starten“ (`.borderedProminent`) → wechselt auf Tab Training.

### 6.5 Session-Detail (`screens/30-verlauf-06/07`)

Push aus dem Verlauf, Inline-Titel = Datum der Session („Gestern, 18:10“).

- Mittlerer Ring (erreicht/Ziel, Zustandsfarben wie oben), Zeit + „von 1:30“ in der Mitte, darunter Status mit Symbol („Geschafft“ / „Nicht geschafft“, bei Rekord zusätzlich „Rekord“).
- Werte als `LabeledContent` in einer Section: Datum, Ziel, Erreicht, Vorbereitung, Pausen („keine“ oder Anzahl + Dauer), Verlängerung („keine“ oder „+10 s (1×)“), Zum Rekord („Rekord“ bzw. „12 s unter deinem Rekord“).
- Taste „Nochmal mit gleicher Zeit“ (`arrow.counterclockwise`, `.borderedProminent`, volle Breite) → startet Session mit gleicher Ziel- und Vorbereitungszeit.

### 6.6 Einstellungen (`screens/40-einstellungen-*.png`)

`Form`, Titel „Einstellungen“.

- **Erscheinungsbild:** `Picker` `.segmented`: System / Hell / Dunkel → `.preferredColorScheme`.
- **Coach-Stil:** `Picker` `.inline` mit Häkchen. Jede Option dreizeilig: Name (`.headline`), Beschreibung (`.subheadline`, secondary), Beispielsatz kursiv in deutschen Anführungszeichen:
  - Ruhig – „Gelassen, viel Atem, wenig Worte.“ – „Ruhig weiteratmen.“
  - Fordernd – „Klar und direkt, wie im Kurs.“ – „Halt die Spannung!“
  - Frech – „Mit Augenzwinkern. Nichts für Zartbesaitete.“ – „Das Sofa ruft. Ignorier es.“
  - Aus – „Nur Zeitansagen.“ – „Noch 30 Sekunden.“
- **Toggle „Haltungs-Hinweise“** und **Toggle „Haptik“**, Tint Iris. Footer: „Hinweise wie „Hüfte nicht hängen lassen“ kommen höchstens alle 20 s.“
- **Info** (Push): App-Icon, „Plank-Trainer“, `LabeledContent` Version (aus Bundle), Lizenz „MIT“, `Link` „Quellcode auf GitHub“ (`arrow.up.right`) → Repository-URL [aus der Spec einsetzen]. Footer: „Keine Konten, keine Tracker; alle Daten bleiben auf dem iPhone.“

## 7. Haptik- und Bewegungs-Momente

Haptik über `.sensoryFeedback`, nur wenn Einstellung „Haptik“ an ist. Bei „Bewegung reduzieren“ (`@Environment(\.accessibilityReduceMotion)`) alle Übergänge als `PlankMotion.reducedCrossfade`; Ring läuft trotzdem weiter (er ist Information).

| Moment | Bewegung | Haptik | Bewegung reduzieren |
|---|---|---|---|
| Start | Ring füllt sich in 0,4 s von leer auf voll (`PlankMotion.start`), dann läuft er | `.impact(weight: .light)` bei 3, 2, 1; `.impact(weight: .medium)` beim Start | Ring sofort voll, 0,2 s Überblendung |
| Letzte 5 s | Strich 7,5 % → 9 % (0,3 s), Zeit pulsiert pro Sekunde | `.impact(flexibility: .soft)` jede Sekunde | kein Puls, nur dickerer Strich |
| +10 s | Bogen wächst (`PlankMotion.extend`), neues Stück 1 s heller, Chip 2 s | `.impact(weight: .light)` | Bogen springt, Chip bleibt |
| Pause | Bogen friert ein, 0,25 s zu Bernstein + gestrichelt | `.impact(weight: .medium)`; beim Weiter 3-2-1 wie Start | sofortiger Wechsel |
| Geschafft | max. 1,2 s: Ring zu Moos (0,35 s), Häkchen zeichnet sich ein (`.symbolEffect(.drawOn)`), eine Welle löst sich (Skala 1 → 1,15, Deckkraft 0,5 → 0, 0,6 s) | `.success` mit dem Häkchen | Überblendung zu Moos + Häkchen, keine Welle |
| Neuer Rekord | danach äußere Rekord-Bahn im Uhrzeigersinn (0,8 s), Plakette gleitet 12 pt nach oben | `.success`, nach 0,15 s `.impact(weight: .heavy)` | Bahn und Plakette sofort sichtbar |

## 8. App-Icon (`screens/02-app-icon-uebersicht.png`)

Icon Composer, drei Ebenen, kein Text:

1. Hintergrund: flaches Iris #5B3FD9 (Dunkel: #0B0A12; Getönt: Graustufen).
2. Ring: Spur 24 % + Bogen 270° (oben rechts offen), Strich 11 % der Kantenlänge, runde Enden, Mittelpunkt leicht unter der Mitte. Hell: Weiß; Dunkel: #A496FF; Getönt: Hellgrau.
3. Waagemarke: Capsule 21 % × 5,5 % der Kantenlänge quer auf dem Bogenanfang. Hell: #1C1B24; Dunkel und Getönt: Weiß. Oberste Ebene, stärkste Glass-Tiefe.

Die Vorlage liegt nur als Bild vor; die Ebenen als SVG in Icon Composer nachbauen.

## 9. Accessibility

- VoiceOver: Ring als ein Element, Label z. B. „Restzeit 56 Sekunden von 1 Minute 30. 34 Sekunden vergangen.“; Pausen- und Ergebniszustand im Label. Zeiten als gesprochene Dauer, nicht „0:56“.
- Alle Trefferflächen ≥ 44 × 44 pt; im Session-Screen ≥ 72 pt hoch.
- Status immer mit Symbol + Text, nie nur Farbe.
- „Kontrast erhöhen“: HC-Farben (automatisch über `PlankColors`) + Spur 30 %.
- „Transparenz reduzieren“: Glass wird vom System ersetzt; Spur 30 %.
- Dynamic Type bis AX5 testen, mindestens Training und Session bei AX3.

## 10. Checkliste

- [ ] DesignSystem-Dateien eingebunden, `.tint(.plankIris)` am Root
- [ ] Keine Hex-Werte, Schriftgrößen oder Animationen außerhalb von `DesignSystem/`
- [ ] Tab Bar mit drei Tabs, Start auf Training
- [ ] Training inkl. Erststart und aufklappbarer Vorbereitung
- [ ] Ring-View mit allen 6 Zuständen und Waagemarke, Größen Session/Detail/Mini
- [ ] Session: alle 8 Zustände, Dialog, Hinweis, Display bleibt an
- [ ] „Abbrechen“ nur oben links, immer mit Dialog; „Stop“ speichert ohne Rückfrage
- [ ] Verlauf: Chart mit Füllung/Kontur/Rekordlinie, Liste, Swipe-to-delete, Leerzustand
- [ ] Session-Detail mit allen Werten und „Nochmal mit gleicher Zeit“
- [ ] Einstellungen + Info
- [ ] Haptik-Momente, abschaltbar über Einstellung
- [ ] „Bewegung reduzieren“ für jeden Moment geprüft
- [ ] Hell, Dunkel, Kontrast erhöhen, Transparenz reduzieren geprüft
- [ ] Dynamic Type bis AX5 geprüft, Englisch-Lokalisierung ohne abgeschnittene Texte
- [ ] Screens mit den PNGs verglichen

## Anhang: verwendete SF Symbols

`figure.core.training`, `chart.bar.fill`, `gearshape.fill`, `play.fill`, `pause.fill`, `stop.fill`, `plus`, `xmark`, `checkmark`, `checkmark.circle.fill`, `circle.lefthalf.filled`, `trophy.fill`, `speaker.slash.fill`, `bubble.left`, `chevron.right`, `trash.fill`, `arrow.counterclockwise`, `arrow.up.right`

## Anhang: Screens

| Datei | Inhalt |
|---|---|
| `00-grundlagen-uebersicht.png` | Idee, Tokens, Typo, Abstände, Momente |
| `01-ring-uebersicht.png` | Ring-Zustände Hell/Dunkel + Spezifikation |
| `02-app-icon-uebersicht.png` | Icon Hell/Dunkel/Getönt |
| `10-training-01…06` | Training Hell/Dunkel, Erststart, Vorbereitung offen, AX3 Training, AX3 Session |
| `20-session-01…08` | Session-Zustände 1–8 Hell |
| `20-session-09…16` | Session-Zustände 1–8 Dunkel |
| `30-verlauf-01…07` | Verlauf Hell/Dunkel, Löschen, Leer Hell/Dunkel, Detail Hell/Dunkel |
| `40-einstellungen-01…03` | Einstellungen Hell/Dunkel, Info |
| `*-uebersicht.png` | ganze Artboards im Überblick |
