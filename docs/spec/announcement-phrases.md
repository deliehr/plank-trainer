# Plank-Trainer – Ansage- und Coach-Texte

Stand: 2026-11-21 · Status: **zum Gegenlesen** · Gehört zu `docs/spec/plank-trainer-spec.md` (Abschnitte 3.4, 3.5)

Format: `Deutsch` / `English`. Platzhalter:
- `{time}` = Restzeit ohne „noch“ (z. B. „2 Minuten 30“ / „2 minutes 30“)
- `{achieved}` = erreichte Zeit (z. B. „42 Sekunden“ / „42 seconds“)

Regeln für alle Texte:
- Start- und Weiter-Sätze enthalten immer „noch {time}“ bzw. „{time} to go“.
- Halbzeit- und Endspurt-Sätze sind Präfixe ohne Zeitangabe; die Zeit-Ansage wird automatisch angehängt.
- „Frech“: Sticheleien über Faulheit, Sofa und Ausreden, nie über Körper, Gewicht, Aussehen, Geschlecht oder Herkunft.
- Für die spätere Sprachsteuerung (Spezifikation 9.1) sollen Texte die Wörter „Pause“, „Stop“, „Abbrechen“, „Abbruch“, „weiter“ und „verlängern“ möglichst vermeiden. Aktuell kommt „weiter“ in mehreren Sätzen vor; vor Einführung der Sprachsteuerung ist das zu prüfen.

---

## Feste Texte (alle Stile)

| Anlass | Deutsch | English |
|---|---|---|
| Vorbereitung | Mach dich bereit | Get ready |
| Countdown | 3 · 2 · 1 | 3 · 2 · 1 |
| Start (Stil „Aus“) | Planking Session gestartet, noch {time} | Planking session started, {time} to go |
| Zeit-Ansage | Noch {time} | {time} to go |
| Letzte 5 s | 5 · 4 · 3 · 2 · 1 | 5 · 4 · 3 · 2 · 1 |
| Ende | Planking Session abgeschlossen | Planking session complete |
| Weiter (Stil „Aus“) | Noch {time} | {time} to go |
| Gestoppt (Stil „Aus“) | Gestoppt nach {achieved} | Stopped after {achieved} |

---

## Start

**Ruhig**
1. Planking Session gestartet, noch {time}. Ganz ruhig, du hast Zeit. / Planking session started, {time} to go. Nice and steady.
2. Los geht's in deinem Tempo, noch {time}. / Here we go, at your own pace, {time} to go.
3. Atme ruhig. Planking Session gestartet, noch {time}. / Breathe calmly. Planking session started, {time} to go.
4. Schön, dass du da bist. Noch {time}. / Glad you're here. {time} to go.

**Fordernd**
1. Planking Session gestartet, noch {time}. Zeig, was du kannst! / Planking session started, {time} to go. Show me what you've got!
2. Los geht's! Noch {time}. Spannung halten! / Let's go! {time} to go. Hold that tension!
3. Die Session läuft, noch {time}. Keine Kompromisse. / Session's on, {time} to go. No compromises.
4. Auf geht's! Noch {time}, jede Sekunde zählt. / Let's do this! {time} to go, every second counts.

**Frech**
1. Planking Session gestartet, noch {time}. Das Sofa kann warten. / Planking session started, {time} to go. The couch can wait.
2. Na endlich! Noch {time}. Mal sehen, ob du heute durchhältst. / Finally! {time} to go. Let's see if you last today.
3. Noch {time}. Und nein, Jammern macht's nicht kürzer. / {time} to go. And no, whining won't make it shorter.
4. Komm schon, du Faultier! Noch {time}. / Come on, you sloth! {time} to go.

---

## Halbzeit (Präfix)

**Ruhig**
1. Halbzeit. Du machst das gut. / Halfway there. You're doing well.
2. Die Hälfte ist geschafft. / Half done.
3. Halbzeit. Bleib ruhig und gleichmäßig. / Halfway. Stay calm and steady.
4. Schon die Hälfte. Schön so. / Already halfway. Lovely.

**Fordernd**
1. Halbzeit! Jetzt nicht nachlassen! / Halfway! Don't let up now!
2. Halbzeit! Die zweite Hälfte gehört dir! / Halfway! The second half is yours!
3. Halbzeit! Spannung halten! / Halfway! Keep the tension!
4. Die Hälfte ist weg, jetzt erst recht! / Half gone, now more than ever!

**Frech**
1. Halbzeit. Überraschung, du lebst noch! / Halfway. Surprise, you're still alive!
2. Halbzeit! Hätte ich ehrlich gesagt nicht gedacht. / Halfway! Honestly, didn't see that coming.
3. Halbzeit. Jetzt bloß nicht schlappmachen, du Weichei! / Halfway. Don't wimp out on me now!
4. Die Hälfte! Dein Sofa vermisst dich schon. / Half done! Your couch already misses you.

---

## Endspurt (Präfix der 15-s-Ansage)

**Ruhig**
1. Gleich geschafft. / Almost there.
2. Der Endspurt beginnt. Ruhig atmen. / Final stretch. Keep breathing calmly.
3. Nur noch ein kleines Stück. / Just a little more.
4. Fast fertig, du machst das toll. / Nearly done, you're doing great.

**Fordernd**
1. Endspurt! Alles geben! / Final push! Give it everything!
2. Jetzt zählt's! / This is where it counts!
3. Durchziehen! / Push through!
4. Endspurt! Keinen Zentimeter nachgeben! / Final push! Don't give an inch!

**Frech**
1. Endspurt! Jetzt bloß nicht peinlich werden. / Final push! Don't embarrass yourself now.
2. Endspurt! Zittern zählt übrigens nicht als Ausrede. / Final push! Shaking is not an excuse, by the way.
3. Gleich darfst du wieder rumliegen, Schlafmütze. / You can go back to lying around soon, sleepyhead.
4. Endspurt! Deine Ausreden kannst du dir sparen. / Final push! Save your excuses.

---

## Lückenfüller

**Ruhig**
1. Ruhig weiteratmen. / Keep breathing calmly.
2. Du machst das gut. / You're doing well.
3. Schön gleichmäßig. / Nice and steady.
4. Bleib ganz bei dir. / Stay with yourself.
5. Jede Sekunde macht dich stärker. / Every second makes you stronger.
6. Entspann das Gesicht, halte den Körper. / Relax your face, hold your body.
7. Alles im grünen Bereich. / All good.
8. Konzentrier dich auf deinen Atem. / Focus on your breath.
9. Genau so. / Just like that.
10. Du bist stärker, als du denkst. / You're stronger than you think.

**Fordernd**
1. Du schaffst das! / You've got this!
2. Stark, genau so! / Strong, just like that!
3. Nicht nachlassen! / Don't let up!
4. Halt die Spannung! / Hold the tension!
5. Kämpf! / Fight for it!
6. Das brennt? Gut so! / It burns? Good!
7. Bleib hart! / Stay tough!
8. Jede Sekunde zählt! / Every second counts!
9. Du bist eine Maschine! / You're a machine!
10. Gib nicht auf! / Don't give up!

**Frech**
1. Zitterst du etwa schon? / Are you shaking already?
2. Das Sofa ruft. Ignorier es. / The couch is calling. Ignore it.
3. Ich hab schon gekochte Nudeln gesehen, die stabiler waren. / I've seen cooked noodles more stable than this.
4. Komm schon, meine Oma hält länger durch. / Come on, my grandma lasts longer than this.
5. Nicht einschlafen da unten! / Don't fall asleep down there!
6. Wer jammern kann, kann auch durchhalten. / If you can whine, you can hold on.
7. Hübsches Zittern. Dranbleiben. / Nice shaking. Hang in there.
8. Ausreden zählen nicht als Training. / Excuses don't count as training.
9. Du schaffst das. Vermutlich. / You can do it. Probably.
10. Faultiere sind schneller, aber immerhin hältst du still. / Sloths are faster, but at least you're holding still.

---

## Haltungs-Hinweise (stilunabhängig, eigener Schalter)

1. Bauch anspannen. / Brace your core.
2. Po anspannen. / Squeeze your glutes.
3. Hüfte nicht durchhängen lassen. / Don't let your hips sag.
4. Hüfte nicht zu hoch. / Don't pike your hips.
5. Ellbogen unter die Schultern. / Elbows under your shoulders.
6. Blick zum Boden, Nacken lang. / Eyes down, long neck.
7. Schultern weg von den Ohren. / Shoulders away from your ears.
8. Gleichmäßig atmen. / Breathe evenly.
9. Gerade wie ein Brett. / Straight as a board.
10. Fersen nach hinten schieben. / Push your heels back.

---

## Rekord in Sicht (5 s vor dem Rekord)

**Ruhig**
1. Noch 5 Sekunden bis zu deinem Rekord. / 5 seconds to your personal best.
2. Dein Rekord ist ganz nah. / Your record is very close.
3. Gleich erreichst du deinen Rekord. / You're about to reach your record.

**Fordernd**
1. Noch 5 Sekunden bis zum Rekord, hol ihn dir! / 5 seconds to your record, go get it!
2. Der Rekord wackelt! / Your record is wobbling!
3. Rekord in Sichtweite! Dranbleiben! / Record in sight! Stay on it!

**Frech**
1. Noch 5 Sekunden bis zum Rekord. Jetzt nicht kneifen. / 5 seconds to your record. Don't chicken out now.
2. Rekord in Sicht. Ich bin ehrlich überrascht. / Record in sight. I'm honestly surprised.
3. Dein alter Rekord zittert. Du übrigens auch. / Your old record is shaking. So are you, by the way.

---

## Neuer Rekord

**Ruhig**
1. Neuer Rekord. Wunderbar. / New record. Wonderful.
2. Das ist ein neuer Rekord. / That's a new record.
3. Neuer Rekord. Ganz ruhig dranbleiben. / New record. Stay calm and steady.
4. Rekord geknackt. Schön. / Record broken. Lovely.

**Fordernd**
1. Neuer Rekord! Dranbleiben! / New record! Stay on it!
2. Rekord geknackt! Jetzt noch einen draufsetzen! / Record smashed! Now add some more!
3. Neuer Rekord! Du bist nicht zu stoppen! / New record! You're unstoppable!
4. Rekord! Und es ist noch nicht vorbei! / Record! And it's not over yet!

**Frech**
1. Neuer Rekord. Wer hätte das gedacht? Ich nicht. / New record. Who'd have thought? Not me.
2. Rekord geknackt! Das Sofa ist enttäuscht. / Record broken! The couch is disappointed.
3. Neuer Rekord. Okay, ich nehm alles zurück. Fast alles. / New record. Okay, I take it all back. Almost.
4. Rekord! Bild dir bloß nichts darauf ein. / Record! Don't let it go to your head.

---

## Letzte Session (Stelle, an der zuletzt aufgehört wurde)

**Ruhig**
1. Hier hast du letztes Mal aufgehört. Heute geht mehr. / This is where you stopped last time. Today there's more.
2. Genau hier war letztes Mal Schluss. Atme ruhig. / This is where it ended last time. Breathe calmly.
3. Die Stelle von letztem Mal, und du bist noch da. / Last time's mark, and you're still here.

**Fordernd**
1. Hier hast du letztes Mal aufgehört. Heute nicht! / This is where you quit last time. Not today!
2. Letztes Mal war hier Schluss. Heute gehst du drüber! / Last time it ended here. Today you go beyond!
3. Alte Grenze erreicht. Drüber! / Old limit reached. Beyond it!

**Frech**
1. Hier hast du letztes Mal aufgegeben. Nur so als Info. / This is where you gave up last time. Just saying.
2. Letztes Mal war hier Feierabend. Heute auch, Weichei? / Last time you clocked out here. Again today, wimp?
3. Kommt dir die Stelle bekannt vor? Genau, hier hast du gekniffen. / Look familiar? Yep, this is where you bailed.

---

## Weiter nach Pause (nach 3-2-1)

**Ruhig**
1. Weiter geht's, noch {time}. / Here we go again, {time} to go.
2. Ganz ruhig wieder rein. Noch {time}. / Ease back in. {time} to go.
3. Und los, noch {time}. / And go, {time} to go.

**Fordernd**
1. Zurück an die Arbeit! Noch {time}! / Back to work! {time} to go!
2. Los! Noch {time}! / Go! {time} to go!
3. Neue Kraft, noch {time}! / Fresh energy, {time} to go!

**Frech**
1. Genug ausgeruht. Noch {time}. / Enough lounging. {time} to go.
2. Na, Akku wieder voll? Noch {time}. / Recharged? {time} to go.
3. Die Pause war länger als nötig. Noch {time}. / That break was longer than necessary. {time} to go.

---

## Abschluss (nach „Planking Session abgeschlossen“)

**Ruhig**
1. Gut gemacht. / Well done.
2. Schön, dass du drangeblieben bist. / Nice job sticking with it.
3. Atme tief durch. Das war stark. / Take a deep breath. That was strong.
4. Wunderbar, du kannst stolz sein. / Wonderful, be proud of yourself.
5. Geschafft. Gönn dir eine Pause. / Done. Treat yourself to a rest.

**Fordernd**
1. Stark! So sieht Disziplin aus! / Strong! That's what discipline looks like!
2. Geschafft! Du bist eine Maschine! / Done! You're a machine!
3. Sauber durchgezogen! / Nailed it!
4. Das war richtig stark! / That was seriously strong!
5. Ziel erreicht! Genau so! / Goal reached! Just like that!

**Frech**
1. Geschafft. Du darfst jetzt wieder aufs Sofa. / Done. You may return to the couch.
2. Nicht schlecht für jemanden, der vorhin noch gejammert hat. / Not bad for someone who was whining earlier.
3. Überlebt. Ich bin fast ein bisschen stolz. / Survived. I'm almost a little proud.
4. Geschafft! Siehst du, Ausreden waren unnötig. / Done! See, no excuses needed.
5. Fertig. Das Zittern hört gleich auf. Wahrscheinlich. / Finished. The shaking will stop soon. Probably.

---

## Gestoppt (Stop vor Erreichen des Ziels)

**Ruhig**
1. Gestoppt nach {achieved}. Jede Sekunde zählt. / Stopped after {achieved}. Every second counts.
2. Alles gut, {achieved} sind auch ein Erfolg. / That's fine, {achieved} is still a win.
3. Gestoppt nach {achieved}. Ruh dich aus. / Stopped after {achieved}. Get some rest.

**Fordernd**
1. Gestoppt nach {achieved}. Nächstes Mal mehr! / Stopped after {achieved}. More next time!
2. {achieved}. Da geht noch was! / {achieved}. There's more in you!
3. Gestoppt nach {achieved}. Abhaken und wiederkommen! / Stopped after {achieved}. Shake it off and come back!

**Frech**
1. Gestoppt nach {achieved}. Das Sofa hat gewonnen. / Stopped after {achieved}. The couch wins.
2. Schon vorbei? {achieved}. Ich sag nichts. / Over already? {achieved}. I'm not saying anything.
3. {achieved}. Mutig, das eine Session zu nennen. / {achieved}. Bold of you to call that a session.
