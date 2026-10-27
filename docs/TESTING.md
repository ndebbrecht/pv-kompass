# Testnachweise

## Umgebung

- Mac mini, Xcode 26.2, iOS-26.2-Simulator „PV Kompass Test“ (iPhone 17 Pro).
- Tatsächlicher MCP-Zugang über XcodeBuildMCP 2.0.0 und mcporter; Telemetrie deaktiviert.
- Physische Geräte liefern erst im späteren TestFlight-Praxistest reale Sensorwerte. Simulator-Demodaten sind ausdrücklich markiert und auf iPhones nicht aktivierbar.

## Prüfumfang

- 14 Unit-Tests: Kardinalrichtungen/Diagonalen und mehrere Neigungen; Rotation des Handsets innerhalb der Modulfläche; magnetische Deklinationskorrektur mit Nordübergang; waagerechte Module ohne erfundenen Azimut; ungültige/falsch herum gerichtete Auflage; zirkuläre Mittelung; Stabilitätsprüfung bei Bewegung und gestörtem Feld; CSV-Quoting inklusive Unicode/Zeilenumbruch; Tabellenformel-Schutz nur für Benutzereingaben; negative numerische CSV-Werte; GPS-/Zeitstempel-Roundtrip; magnetische/Demo-Werte nicht als HA-Werte ausgeben; Speichern/Benennen/Laden/Löschen; beschädigte Archive nicht überschreiben.
- Vier UI-Tests: vollständiger Ablauf mit Demo-Messung, Benennung, App-Neustart, persistentem Verlauf und nativem CSV-Share-Sheet; Accessibility-Audit des Hauptbildschirms; größte barrierefreie Schrift mit erreichbarer Messaktion und Audit; Simulator ohne expliziten Demomodus erfindet keine Sensorwerte.
- Kontrastfarben gegenüber SwiftUI-Standardsekundärfarben verstärkt; lange Texte vertikal flexibel, Startbildschirm zugunsten kurzer Anweisungen vereinfacht.
- Bei größter Schrift kann iOS 26 halb aus dem Scrollbereich ragende Textabschnitte hinter der nativen schwebenden Tabbar ausblenden. Deren Kontrast-Audit wird nur bei tatsächlich außerhalb der freien Sichtfläche liegenden Elementen ausgenommen. Kontrast auf vollständig sichtbaren Elementen sowie Beschriftungs-, Textkürzungs- und Trefferflächenprüfungen bleiben aktiv. Das ist keine pauschale Unterdrückung des Kontrastchecks.

## Ergebnis

Am 27.10.2026: **18/18 Tests bestanden**, ausgeführt über XcodeBuildMCP (`test_sim`, vollständiger Lauf 10). Der Hauptbildschirm-Audit, größte Schrift, persistenter Verlauf und nativer CSV-Export bestehen.

## Releaseprüfungen

- App-Icon: 1024×1024, RGB ohne Alphakanal.
- Release mit vorhandenem Apple-Distribution-Zertifikat und app-spezifischem App-Store-Profil signiert; keine Zertifikate widerrufen.
- Release-Archiv und IPA-Export erfolgreich. Version/Buildnummer aus Buildsettings, damit spätere CI-Buildnummern funktionieren.
- TestFlight-Upload und tatsächliche Bereitstellung werden separat nachgewiesen; ein Simulator-Erfolg ist kein TestFlight-Nachweis.

Aktuelle detaillierte Logs, XCResult-Bundles und MCP-Screenshots liegen in Alfreds privaten Release-Arbeitsdateien bzw. lokalem ignoriertem build-Verzeichnis; keine Zugangsdaten oder fremden App-Daten im Repository.

## MCP-Screenshots

- `screenshots/01-messung.jpg`: finaler Messungsbildschirm, per MCP aufgenommen und visuell geprüft.
- `screenshots/02-detail-frueher-pruefstand.jpg`: Detailansicht aus einem früheren Prüflauf; ausdrücklich gekennzeichnete Simulator-Beispielmessung ohne GPS.
