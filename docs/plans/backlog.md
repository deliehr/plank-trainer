# Backlog – offene Punkte

Punkte, die bewusst auf später verschoben sind. Erledigte Punkte werden mit Commit-Verweis entfernt.

## Ducking: fremde Audioausgabe wird nach Ansagen nicht zuverlässig wieder lauter

- **Herkunft:** M1-Geräte-Checkliste, Punkt 3 (2026-11-21). Vom Nutzer auf später verschoben.
- **Symptom:** Läuft Musik aus einer anderen App, bleibt sie nach einer Ansage manchmal auf dem abgesenkten Pegel, statt wieder lauter zu werden.
- **Bisheriger Versuch:** `a80f905`. Die Deaktivierung der Audio-Session wird bis zu 5-mal im Abstand von 200 ms wiederholt; das Flag `isSessionActive` wird erst nach Erfolg zurückgesetzt; die Audioarbeit läuft auf einer eigenen seriellen Queue. Ergebnis auf dem Gerät: besser, aber nicht behoben. Das Ruckeln der Animationen ist damit behoben.
- **Betroffen:** `ios/Planktrainer/Services/SpeechAnnouncer.swift` (`SpeechOutput.handleSpeechEnded`), `ios/Planktrainer/Services/AudioSessionController.swift`.
- **Nächste Schritte:**
  1. Ursache am Gerät eingrenzen: Console.app, Subsystem `de.liehrit.planktrainer`, Kategorie `audio`. Prüfen, ob „Deactivating audio session failed (attempt n)“ erscheint und ob alle 5 Versuche scheitern.
  2. Hypothesen prüfen:
     - Das Retry-Fenster (ca. 0,8 s) ist zu kurz. Alternative: Deaktivierung leicht verzögern und länger wiederholen.
     - Die Optionen `.duckOthers` und `.interruptSpokenAudioAndMixWithOthers` interagieren ungünstig. Nur `.duckOthers` testen.
     - `AVSpeechSynthesizer` hält die Session über `usesApplicationAudioSession` selbst aktiv. Verhalten mit expliziter Steuerung prüfen.
     - Zwischen dem Ende der Retry-Schleife und der nächsten Ansage fehlt ein Fallback. Zusätzlich beim Session-Ende (`stop`, Abschlussansage) und in `deinit` deaktivieren.
  3. Im M1-Abschluss ist dieser Punkt der einzige offene Geräte-Befund.
