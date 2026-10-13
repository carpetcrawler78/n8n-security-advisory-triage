---
version: 4
updated: 2026-09-16
---

# Fünfzehn synthetische Security-Advisories für den n8n-Prototyp

> **English summary.** Fifteen synthetic security advisories used to test the prototype, plus the synthetic asset inventory (seven installations at three fictional customers). All vendors, products, customers and reference numbers are invented; no real CVE numbers are used. The texts are deliberately German, because the scenario is set at a German IT service provider and the language model has to read German input. Each case lists its input text and the expected result: 4 × `POTENTIALLY_AFFECTED` (PA), 4 × `NO_MATCH_FOUND` (NM), 4 × `REVIEW_REQUIRED` (RR), 3 × `INVALID_ADVISORY` (IA), received via e-mail, PDF, portal or phone. The same texts are available as webhook requests in [`examples/requests/`](../examples/requests/). Results: [`docs/architecture.md`](../docs/architecture.md#7-tests).

**Stand:** 8. September 2026
**Zweck:** Fachliche Testgrundlage für die KI-gestützte Relevanzprüfung von Herstellerhinweisen gegen ein synthetisches Asset-Inventar.

Alle Hersteller, Produkte, Kunden, Kennnummern und Inhalte in diesem Dokument sind frei erfunden. Es werden bewusst keine realen CVE-Nummern verwendet. Die unter „Erwartetes Testergebnis“ angegebenen Werte bleiben die fachlichen Sollwerte; die gemessenen Ist-Ergebnisse sind in [`docs/architecture.de.md`](../docs/architecture.de.md) dokumentiert.

## Synthetisches Asset-Inventar

| Asset-ID | Kunde | Gerät | Hersteller | Produkt | Installierte Version |
| --- | --- | --- | --- | --- | --- |
| A-REM-01 | Kunde A – Werkzeugbau | Fernwartungsserver 1 | Musterwerk Systems GmbH | MusterLink Remote Gateway | 2.3.1 |
| A-REM-02 | Kunde A – Werkzeugbau | Fernwartungsserver 2 | Musterwerk Systems GmbH | MusterLink Remote Gateway | 2.3.2 |
| A-BKP-01 | Kunde A – Werkzeugbau | Sicherungsserver | SicherWerk Software AG | DataSafe Backup | 6.1 |
| B-REM-01 | Kunde B – Verpackungstechnik | Fernwartungsserver | Musterwerk Systems GmbH | MusterLink Remote Gateway | 2.4.0 |
| B-HMI-01 | Kunde B – Verpackungstechnik | Produktionsrechner | Anlagenblick GmbH | PlantView HMI | 7.4 |
| C-REM-01 | Kunde C – Medizintechnik-Zulieferer | Fernwartungsserver | Musterwerk Systems GmbH | MusterLink Remote Gateway | 2.3.0 |
| C-ERP-01 | Kunde C – Medizintechnik-Zulieferer | Verwaltungsserver | Warenstrom Software GmbH | WarenFlow ERP | 3.8 |

## Verteilung der fünfzehn Fälle

| Erwarteter Status | E-Mail | PDF | Portal | Telefon |
| --- | --- | --- | --- | --- |
| `POTENTIALLY_AFFECTED` | PA-01 | PA-02 | PA-03 | PA-04 |
| `NO_MATCH_FOUND` | NM-01 | NM-02 | NM-03 | NM-04 |
| `REVIEW_REQUIRED` | RR-01 | RR-02 | RR-03 | RR-04 |
| `INVALID_ADVISORY` | IA-01 | IA-02 | IA-03 | – |

Bei `INVALID_ADVISORY` wurde bewusst kein Telefon-Fall ergänzt: Eine telefonische Nicht-Meldung hätte gegenüber den bestehenden Fällen wenig zusätzliche Testschärfe gebracht. Bei `POTENTIALLY_AFFECTED` wurde der Telefon-Fall am 2026-09-08 nachträglich ergänzt (`PA-04`), damit alle drei Telefonmitschriften die drei unterschiedlichen Statuswerte abdecken, bei denen ein Telefon-Kanal realistisch ist.

Die Texte unterscheiden sich zusätzlich in ihrer Schreibweise: automatisch erzeugte Standardmeldungen, teilweise strukturierte Sicherheitsbulletins, frei formulierte Mitteilungen von Mitarbeitenden sowie drei intern erfasste Telefonmitschriften.

---

# 1. Erwarteter Status: `POTENTIALLY_AFFECTED`

## PA-01 – Automatisch erzeugte Hersteller-E-Mail

### Eingabetext

> **Von:** security-notifications@musterwerk.example  
> **Betreff:** Sicherheitsinformation MS-2026-014 – MusterLink Remote Gateway  
> **Meldungstyp:** Security Advisory  
> **Herstellerbewertung:** Hoch
>
> Bei einer internen Sicherheitsprüfung wurde ein Fehler in der Anmeldekomponente von MusterLink Remote Gateway festgestellt. Unter bestimmten Umständen könnte dadurch ein unbefugter Zugriff auf das Fernwartungssystem ermöglicht werden.
>
> Betroffen sind die Versionen 2.3.0 bis einschließlich 2.3.2. Installationen ab Version 2.4.0 sind nach unserem derzeitigen Kenntnisstand nicht betroffen. Wir empfehlen, vorhandene Installationen zeitnah zu überprüfen und betroffene Systeme auf Version 2.4.0 zu aktualisieren.
>
> Eine CVE-Nummer wurde bislang nicht vergeben. Diese Nachricht wurde automatisch über den Sicherheitsverteiler der Musterwerk Systems GmbH versendet.

### Erwartetes Testergebnis

- Status: `POTENTIALLY_AFFECTED`
- Erkannte Versionen: 2.3.0 bis einschließlich 2.3.2
- Erwartete Treffer: `A-REM-01`, `A-REM-02`, `C-REM-01`
- Nicht betroffen: `B-REM-01` mit Version 2.4.0
- Erwartete Prüfaufträge: einer für Kunde A mit zwei Assets, einer für Kunde C mit einem Asset

## PA-02 – Manuell verfasstes Sicherheitsbulletin als PDF

### Eingabetext des PDF-Dokuments

> # SicherWerk Software AG
>
> ## Technisches Sicherheitsbulletin SW-2026-009
>
> **Produkt:** DataSafe Backup  
> **Veröffentlichung:** 4. September 2026
>
> Unser Entwicklungsteam hat bei der Prüfung der Wiederherstellungsfunktion einen Fehler entdeckt. Ein angemeldeter Benutzer mit eingeschränkten Rechten kann unter bestimmten Bedingungen auf Sicherungssätze zugreifen, für die ihm keine Berechtigung erteilt wurde.
>
> Nach Abschluss der internen Analyse können wir bestätigen, dass DataSafe Backup 6.0 und 6.1 betroffen sind. Die Korrektur ist in Version 6.2 enthalten. Die von uns angegebene Schwere ist **hoch**.
>
> Betreiber sollen vor dem Update prüfen, ob bestehende Sicherungsaufträge erfolgreich abgeschlossen wurden. Anschließend empfehlen wir die Aktualisierung auf Version 6.2. Eine CVE-Zuordnung liegt zum Zeitpunkt der Veröffentlichung nicht vor.
>
> *Dieses Bulletin wurde von der Produkt-Security-Abteilung der SicherWerk Software AG manuell erstellt.*

### Erwartetes Testergebnis

- Status: `POTENTIALLY_AFFECTED`
- Erkannte betroffene Versionen: 6.0 und 6.1
- Erwarteter Treffer: `A-BKP-01`
- Erwarteter Prüfauftrag: einer für Kunde A

## PA-03 – Kurze Portalmeldung

### Eingabetext

> **Musterwerk Partnerportal / Sicherheitsmeldungen**  
> **Eintrag:** AB-2026-117  
> **Veröffentlicht:** 6. September 2026, 08:40 Uhr
>
> Für PlantView HMI 7.4 steht ein dringendes Sicherheitsupdate bereit. Bei der Verarbeitung einer fehlerhaften Projektdatei kann die Anwendung unerwartet Befehle mit den Rechten des angemeldeten Benutzers ausführen. Andere Versionen wurden im Rahmen dieser Meldung nicht bewertet.
>
> Anlagenblick GmbH empfiehlt Kunden mit Version 7.4, die Anwendung nicht unbeaufsichtigt mit Dateien aus unbekannter Herkunft zu verwenden und auf Version 7.4.2 zu wechseln. Einstufung durch den Hersteller: hoch.

### Erwartetes Testergebnis

- Status: `POTENTIALLY_AFFECTED`
- Erkannte betroffene Version: 7.4
- Erwarteter Treffer: `B-HMI-01`
- Erwarteter Prüfauftrag: einer für Kunde B

## PA-04 – Telefonmitschrift (Service Desk) mit eindeutigem Versionsbezug

### Eingabetext

> **Interne Service-Desk-Notiz** – erfasst nach Telefonat
> **Datum:** 8. September 2026, 09:50 Uhr
> **Bearbeiter/in:** R. Vogel
>
> Jemand von Warenstrom Software GmbH hat angerufen, ziemlich kurzfristig, wollte eigentlich nur schnell Bescheid geben. Es geht wohl um WarenFlow ERP, ein Sicherheitsthema beim Im- oder Export von Dokumenten, genau wusste er es selbst nicht mehr, aber er war sich sicher: alle Versionen bis einschließlich 3.8 sind betroffen, ab 3.9 sei es behoben. Er sagte, das sei mittlerweile auch offiziell bestätigt, nicht mehr nur ein Verdacht wie letzte Woche. Ein schriftliches Bulletin soll noch folgen, lag zum Zeitpunkt des Anrufs aber noch nicht vor.

### Erwartetes Testergebnis

- Status: `POTENTIALLY_AFFECTED`
- Erkannte Versionsregel: alle Versionen bis einschließlich 3.8 betroffen, behoben ab 3.9
- Erwarteter Treffer: `C-ERP-01` (WarenFlow ERP, installierte Version 3.8)
- Nachvollziehbarer Versionsgrund: installierte Version 3.8 liegt innerhalb der genannten oberen Grenze (`version_rule_type: through`, `upper_bound: 3.8`, `upper_inclusive: true`)
- Zusätzlicher Testpunkt: informelle, mündlich erfasste Meldung ohne Tabellenstruktur, die dennoch eine eindeutige Versionsgrenze enthält — Abgrenzung zu `RR-03` (gleiches Produkt, dort aber ausdrücklich unklare Version)

---

# 2. Erwarteter Status: `NO_MATCH_FOUND`

## NM-01 – Frei formulierte Support-E-Mail

### Eingabetext

> **Von:** Lena Vogt, LogicGate Produktsupport  
> **Betreff:** Bitte Installationen von LogicGate Control Center prüfen
>
> Guten Tag,
>
> wir möchten Sie vorsorglich auf ein Problem aufmerksam machen, das uns am Wochenende gemeldet wurde. Speziell aufgebaute Konfigurationsdateien können dazu führen, dass der Dienst von LogicGate Control Center beendet wird und anschließend neu gestartet werden muss.
>
> Nach aktuellem Stand betrifft das die Ausgaben 4.1.0 bis 4.1.6. In 4.2.0 ist die Korrektur bereits enthalten. Wir bewerten das Problem als mittel. Bitte prüfen Sie bei Ihren betreuten Installationen, ob noch eine der genannten Versionen eingesetzt wird.
>
> Viele Grüße  
> Lena Vogt

### Erwartetes Testergebnis

- Status: `NO_MATCH_FOUND`
- Begründung: LogicGate Control Center ist nicht im vorhandenen Asset-Inventar enthalten.
- Verpflichtender Hinweis: Kein Treffer im vorhandenen Bestand ist keine allgemeine Entwarnung.

## NM-02 – Automatisch erzeugtes PDF-Bulletin

### Eingabetext des PDF-Dokuments

> # ArchivePoint Security Notice
>
> | Feld | Inhalt |
> | --- | --- |
> | Dokument-ID | AP-SN-2026-044 |
> | Produkt | ArchivePoint Document Server |
> | Betroffene Versionen | 8.2.0–8.2.4 |
> | Behoben in | 8.2.5 |
> | Schwere | Kritisch |
> | CVE | Noch nicht vergeben |
>
> ArchivePoint Document Server verarbeitet bestimmte Archivpakete nicht korrekt. Ein Angreifer könnte dadurch im ungünstigsten Fall Programmcode auf dem Server ausführen. Der Hersteller empfiehlt, alle Installationen der Versionen 8.2.0 bis einschließlich 8.2.4 unverzüglich auf 8.2.5 zu aktualisieren.
>
> Dieses Dokument wurde automatisch aus dem Produktsicherheitsregister der ArchivPlus Systems GmbH erstellt.

### Erwartetes Testergebnis

- Status: `NO_MATCH_FOUND`
- Begründung: ArchivePoint Document Server ist nicht im vorhandenen Asset-Inventar enthalten.
- Verpflichtender Hinweis: Kein Treffer im vorhandenen Bestand ist keine allgemeine Entwarnung.

## NM-03 – Automatisierte Portalmeldung

### Eingabetext

> **FleetSoft Kundenportal**  
> Meldungsnummer: FS-SEC-8831  
> Status: offen  
> Priorität: hoch
>
> Sicherheitsupdate für FleetDesk Agent verfügbar. Betroffen sind alle Versionen vor 5.7.0. Die Schwachstelle betrifft die lokale Speicherung von Zugangsdaten. Version 5.7.0 enthält die Korrektur.
>
> Automatisch veröffentlicht am 05.09.2026 um 22:15 Uhr. Bitte verteilen Sie diese Information an die für FleetDesk zuständigen Administratoren.

### Erwartetes Testergebnis

- Status: `NO_MATCH_FOUND`
- Erkannte Versionsregel: alle Versionen kleiner als 5.7.0
- Begründung: FleetDesk Agent ist nicht im vorhandenen Asset-Inventar enthalten.
- Verpflichtender Hinweis: Kein Treffer im vorhandenen Bestand ist keine allgemeine Entwarnung.

## NM-04 – Telefonmitschrift (Service Desk)

### Eingabetext

> **Interne Service-Desk-Notiz** – erfasst nach Telefonat
> **Datum:** 7. September 2026, 11:15 Uhr
> **Bearbeiter/in:** T. Albrecht
>
> Anruferin (IT-Dienstleister eines Kunden) meldet, dass ihr Hersteller „PixNet Networks" sie heute telefonisch über ein Sicherheitsproblem in der Firmware der „PixNet Edge Router" informiert habe. Details zur betroffenen Version konnte sie aus dem Gedächtnis nicht nennen, wollte aber sicherstellen, dass wir informiert sind. Ein schriftliches Dokument liegt uns noch nicht vor, soll laut Anruferin aber per E-Mail nachgereicht werden.

### Erwartetes Testergebnis

- Status: `NO_MATCH_FOUND`
- Begründung: PixNet Edge Router ist nicht im vorhandenen Asset-Inventar enthalten.
- Zusätzlicher Testpunkt: Die Meldung ist mündlich, informell und ohne Versionsangabe erfasst. Das System muss trotzdem korrekt zwischen „kein Treffer" und „unklar, weil Angaben fehlen" unterscheiden (Abgrenzung zu `REVIEW_REQUIRED`) – hier fehlt eindeutig schon das Produkt selbst im Inventar, nicht nur die Version.
- Verpflichtender Hinweis: Kein Treffer im vorhandenen Bestand ist keine allgemeine Entwarnung.

---

# 3. Erwarteter Status: `REVIEW_REQUIRED`

## RR-01 – Manuell geschriebene Hersteller-E-Mail mit fehlender Versionsangabe

### Eingabetext

> **Von:** Martin Keller, Musterwerk Systems GmbH  
> **Betreff:** Vorabinformation zu MusterLink Remote Gateway
>
> Guten Morgen,
>
> unsere Technik untersucht momentan ein mögliches Sicherheitsproblem bei bestimmten älteren Installationen von MusterLink Remote Gateway. Nach bisherigen Erkenntnissen kann das Problem unter besonderen Bedingungen die Anmeldung am Fernwartungssystem beeinträchtigen.
>
> Ich kann Ihnen heute leider noch nicht mitteilen, welche Versionsstände genau betroffen sind. Bitte prüfen Sie daher zunächst nur, bei welchen Kunden das Produkt eingesetzt wird, und nehmen Sie noch keine pauschale Bewertung aller Installationen vor. Wir stellen eine ergänzte Meldung bereit, sobald die Untersuchung abgeschlossen ist.
>
> Freundliche Grüße  
> Martin Keller

### Erwartetes Testergebnis

- Status: `REVIEW_REQUIRED`
- Begründung: Das Produkt ist erkennbar, aber die betroffenen Versionen fehlen.
- Verbotene Schlussfolgerung: Das System darf nicht automatisch alle Versionen vor 2.4.0 als betroffen behandeln.

## RR-02 – PDF-Bulletin mit widersprüchlichen Versionsangaben

### Eingabetext des PDF-Dokuments

> # Vorläufiges Sicherheitsbulletin SW-2026-011
>
> **SicherWerk Software AG – DataSafe Backup**  
> Stand: 7. September 2026, 09:00 Uhr
>
> In der Zusammenfassung dieses Bulletins wird DataSafe Backup bis einschließlich Version 6.1 als betroffen bezeichnet. Die korrigierte Fassung soll mit Version 6.2 bereitgestellt werden.
>
> ## Technische Übersicht
>
> | Version | Bewertung |
> | --- | --- |
> | 6.0 | betroffen |
> | 6.1 | nach aktueller Prüfung nicht betroffen |
> | 6.2 | Korrekturversion |
>
> Die Angaben werden derzeit durch das Entwicklungsteam überprüft. Bis zur Veröffentlichung einer korrigierten Fassung sollen Partner keine endgültige Aussage gegenüber Kunden treffen.

### Erwartetes Testergebnis

- Status: `REVIEW_REQUIRED`
- Begründung: Der Fließtext bezeichnet Version 6.1 als betroffen, die Tabelle dagegen als nicht betroffen.
- Möglicher Bezug zum Bestand: `A-BKP-01` verwendet Version 6.1, darf aber wegen des Widerspruchs nicht automatisch als betroffen oder nicht betroffen eingestuft werden.

## RR-03 – Knapp formulierte Portalmeldung

### Eingabetext

> **Warenstrom Supportportal**  
> Kategorie: Sicherheit  
> Beitrag von: Produktbetreuung
>
> Bei einzelnen Installationen von WarenFlow ERP aus der Produktgeneration 3.x kann es zu einem sicherheitsrelevanten Fehler beim Dokumentenexport kommen. Nicht jede Ausgabe der Produktgeneration ist betroffen. Eine vollständige Liste der Versionsstände liegt dem Support noch nicht vor.
>
> Kunden mit einer 3.x-Installation sollen ihre genaue Build-Nummer bereithalten und auf eine ergänzende Mitteilung warten.

### Erwartetes Testergebnis

- Status: `REVIEW_REQUIRED`
- Begründung: Das Inventar enthält WarenFlow ERP 3.8, die Meldung nennt jedoch keine ausreichende Versionsgrenze und erklärt ausdrücklich, dass nicht jede 3.x-Version betroffen ist.

## RR-04 – Telefonmitschrift (Service Desk) mit erkennbarem Produkt, aber unklarer Version

### Eingabetext

> **Interne Service-Desk-Notiz** – erfasst nach Telefonat
> **Datum:** 7. September 2026, 14:05 Uhr
> **Bearbeiter/in:** S. Nowak
>
> Techniker von Anlagenblick GmbH hat angerufen und vor einem möglichen Problem bei PlantView HMI gewarnt: Bei bestimmten Netzwerkkonfigurationen könne die Anmeldemaske umgangen werden. Er war sich nicht sicher, ob das nur die aktuelle Version oder auch ältere Stände betrifft, wollte das intern noch abklären und sich in den nächsten Tagen mit Genauerem melden. Ich habe ihn um eine schriftliche Bestätigung gebeten, die liegt uns aber noch nicht vor.

### Erwartetes Testergebnis

- Status: `REVIEW_REQUIRED`
- Begründung: Das Produkt (PlantView HMI, vorhanden als `B-HMI-01`) ist erkennbar, aber die betroffene Version ist ausdrücklich unklar und selbst dem Hersteller noch nicht final bestätigt.
- Verbotene Schlussfolgerung: Das System darf PlantView HMI 7.4 nicht vorsorglich als betroffen einstufen, nur weil es das einzige im Inventar erfasste PlantView-System ist.
- Zusätzlicher Testpunkt: informelle, mündlich erfasste Meldung ohne Versions-, CVE- oder Schweregradangabe – prüft, ob die Extraktion auch aus unstrukturiertem Fließtext ohne Tabellenstruktur ein plausibles, aber unvollständiges Ergebnis erzeugt, statt abzubrechen oder zu raten.

---

# 4. Erwarteter Status: `INVALID_ADVISORY`

## IA-01 – Marketing-E-Mail mit dem Wort „Sicherheit“

### Eingabetext

> **Von:** veranstaltungen@musterwerk.example  
> **Betreff:** Einladung zum Online-Seminar „Sicher fernwarten“
>
> Sehr geehrte Partnerinnen und Partner,
>
> am 18. September zeigen wir Ihnen in einem kostenlosen Online-Seminar, wie Sie Benutzerrollen in MusterLink Remote Gateway verwalten und die Sicherheit Ihrer Fernwartungsprozesse verbessern können. Außerdem stellen wir die neue Übersichtsseite der Version 2.4.1 vor.
>
> Die Veranstaltung enthält eine Live-Demonstration und Zeit für Fragen. Es wird kein Produktfehler oder aktueller Sicherheitshinweis gemeldet.
>
> Wir freuen uns auf Ihre Teilnahme.

### Erwartetes Testergebnis

- Status: `INVALID_ADVISORY`
- Begründung: Der Text bewirbt eine Veranstaltung und meldet keine Schwachstelle.
- Wichtiger Testpunkt: Das bloße Auftreten des Wortes „Sicherheit“ darf nicht zur Einstufung als Security-Advisory führen.

## IA-02 – Produktversionshinweise als PDF

### Eingabetext des PDF-Dokuments

> # WarenFlow ERP 3.9 – Versionshinweise
>
> **Warenstrom Software GmbH**  
> Veröffentlichung: September 2026
>
> Die neue Version erweitert den Dokumentenexport um eine Vorschau und ermöglicht das Speichern häufig verwendeter Filter. In der Artikelverwaltung können mehrere Datensätze gleichzeitig gekennzeichnet werden.
>
> Zusätzlich wurden Bezeichnungen in der Benutzeroberfläche vereinheitlicht und die Ladezeit der Startseite verkürzt. Dieses Dokument beschreibt funktionale Änderungen. Es enthält keine Meldung zu einer Sicherheitslücke und fordert kein sicherheitsbedingtes Update.

### Erwartetes Testergebnis

- Status: `INVALID_ADVISORY`
- Begründung: Es handelt sich um gewöhnliche Versionshinweise ohne Sicherheitsproblem.

## IA-03 – Automatische Wartungsmeldung im Herstellerportal

### Eingabetext

> **Anlagenblick Serviceportal**  
> Meldungstyp: Geplante Wartung  
> Automatisch veröffentlicht: 07.09.2026, 06:00 Uhr
>
> Das Anlagenblick Serviceportal ist am 12. September 2026 zwischen 20:00 und 22:00 Uhr wegen planmäßiger Wartungsarbeiten nicht erreichbar. Installierte PlantView-HMI-Systeme und laufende Produktionsanlagen sind davon nicht betroffen.
>
> Für Kunden oder IT-Dienstleister besteht kein Handlungsbedarf. Diese Meldung beschreibt keine Produktschwachstelle.

### Erwartetes Testergebnis

- Status: `INVALID_ADVISORY`
- Begründung: Die Meldung betrifft ausschließlich die Verfügbarkeit des Herstellerportals und keine Sicherheitslücke im Produkt.

---

## Teststatus

Die fünfzehn fachlich festgelegten Fälle wurden im finalen Workflow vollständig ausgeführt. Alle 15 lieferten nach den während der Testphase dokumentierten Korrekturen den erwarteten Status. Ergebnisse, Laufzeiten, Zusatztests und bekannte Grenzen stehen in [`docs/architecture.de.md`](../docs/architecture.de.md) (English: [`docs/architecture.md`](../docs/architecture.md)).

Die Volltexte bleiben hier unverändert die fachliche Testgrundlage. Eine Aufbereitung als JSON-Fixtures und automatisierte Regression ist für den Prototyp nicht erforderlich, wäre aber vor produktiven Änderungen an Prompt, Schema, Validator oder Statusregeln sinnvoll.
