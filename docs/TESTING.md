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

GitLab-CI-YAML zusätzlich mit dem GitLab-eigenen YamlProcessor geprüft: keine Fehler, keine Warnungen.

## Build 2

Vollständiger Xcode-MCP-Lauf: 24 Tests, 24 bestanden, 0 fehlgeschlagen, 0 übersprungen. Zusätzlich zum bisherigen Umfang: Standortentscheidung und App-Aktivität als Startbedingung, verweigerter Standortzugriff, verständliche Erklärung für fehlende Ausrichtung, verzögerte Erstfreigabe, Abbruch während der Vorbereitung sowie nativer CSV-Share direkt aus der Titelleiste.

Startansage ist explizit, um 650 ms verzögert und als VoiceOver-Warteschlangenansage markiert. Der Simulator-Test bestätigt nicht die tatsächlich gehörte Sprachausgabe oder den realen iOS-Erstfreigabedialog auf Niklas’ Gerät.

MCP-Screenshot `screenshots/03-build2-waagerecht-und-teilen.jpg` nach realer MCP-UI-Navigation mit Simulator-Demodaten aufgenommen und visuell geprüft: Erklärung vollständig lesbar, CSV-Button oben rechts. MCP-Accessibility-Hierarchie bestätigt den vollständigen Begründungstext im Accessibility-Wert von „Ausrichtung“.

Lokaler MCP-UI-Treiber AXe 1.8.0 ist vorhanden. Homebrew-Linking scheiterte an einem fremden Tailscale-Link; daher privaten MCP-Wrapper auf den absoluten Cellar-Pfad setzen. Die in der AXe-Formel vorgesehenen ad-hoc-Post-Install-Signaturen wurden gezielt nachgeholt. Keine Tailscale-Konfiguration verändert. Screenshot nach MCP-Testlauf erfordert gegebenenfalls erneutes `boot_sim`, da Tests den Simulator herunterfahren können.

## Build 3

Vollständiger finaler Xcode-MCP-Lauf: 27 Tests, 27 bestanden, 0 fehlgeschlagen, 0 übersprungen. Neue Abdeckung: Sammel-CSV mit einmaliger Kopfzeile/BOM, zwei verschiedenen Datensätzen und Formelschutz; Alle-Löschen mit Neustart-Persistenz und Schutz korrupter Dateien; UI-Gesamtexport mit nativem Share-Sheet, Abbrechen und Bestätigen einer Wisch-Löschung sowie Abbrechen und Bestätigen der gesamten Löschung.

Zusätzlich wurde eine tatsächlich über die UI erzeugte Sammel-CSV mit einem unabhängigen CSV-Parser gelesen: 16 Messungen, je 20 Spalten und genau eine Kopfzeile. MCP-Screenshot `screenshots/04-build3-messverlauf.jpg` visuell geprüft: Export oben rechts, Alle-Löschen unter allen Einträgen. Die MCP-Accessibility-Hierarchie enthält die benannte Aktion „Messung löschen“. Alle Screenshots verwenden gekennzeichnete Simulator-Demodaten.
