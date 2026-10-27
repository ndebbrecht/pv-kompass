# PV Kompass

Native, deutschsprachige iPhone-App für die Vermessung einer PV-Modulfläche. iOS 17+, SwiftUI, Core Motion und Core Location. Ohne Konto, Backend, Werbung oder Tracking.

## Funktionen

- Zwei Tabs: Messung und Messverlauf.
- Start per Tippen bei aufgelegtem iPhone; automatische Erfassung über ein stabiles Zeitfenster.
- Modulneigung und Richtung der Modulvorderseite, unabhängig von der Drehung des iPhones in der Modulfläche.
- Geografisch-Nord-Korrektur aus gültigem Core-Location-Kompassbezug; ausdrücklich gekennzeichneter magnetischer Fallback ohne HA-Kopierfunktion.
- Kalibrierungs-, Bewegungs- und Fehlerhinweise, Abbruch und Neustart.
- Haptisches und VoiceOver-Abschlusssignal, Status auf Abruf statt dauernder Zahlenansagen.
- Automatisch lokal gespeicherter Verlauf mit Datum, Uhrzeit und Zeitzone. Messungen benennen und nach Bestätigung löschen.
- GPS inklusive gemeldeter Genauigkeit und GPS-Zeitpunkt, soweit erlaubt/verfügbar.
- Einzelne Messung als UTF-8-CSV mit Kopfzeile über das native Apple-Share-Sheet.
- HA-Werte kopieren; getrennte Spalten für HA Forecast.Solar und direkte Forecast.Solar-API.
- Dynamische Schrift, semantische Beschriftungen, helle/dunkle Darstellung, keine visuelle Kompassbedienung erforderlich.

## Auflegen und Grenzen

Rückseite auf die Vorderseite des Moduls, Bildschirm nach außen. Kamerabuckel und Hüllen dürfen das iPhone nicht verkippen; bei Bedarf gleich hohe, nicht magnetische Auflagen verwenden. Nicht auf heißen oder schwer erreichbaren Modulen arbeiten. Das iPhone gegen Abrutschen sichern.

Metall, magnetische Hüllen und Stromleitungen können auch stabile Kompasswerte verfälschen. Die Stabilitätsprüfung ist KEIN Nachweis absoluter Genauigkeit. Bei weniger als 3° Neigung ist der Azimut nicht eindeutig bestimmbar. Hardware-Verifikation an realen Modulen bleibt nach der Simulatorprüfung erforderlich.

GPS ist optional: verweigerte Berechtigung oder fehlender Empfang führen zu ausdrücklich fehlenden GPS-Werten, nicht zu erfundenen Koordinaten. Ohne gültigen geografischen Kompassbezug wird kein direkt kopierbarer HA-Azimut angeboten.

## Bauen und testen

Voraussetzungen: Xcode 26.2 (aktueller Projektstand), iOS-Simulator, XcodeGen.

```sh
xcodegen generate
xcodebuild -project PVKompass.xcodeproj -scheme PVKompass \
  -destination 'platform=iOS Simulator,name=PV Kompass Test' \
  -parallel-testing-enabled NO CODE_SIGNING_ALLOWED=NO test
```

XcodeBuildMCP wurde ebenfalls für Tests und Screenshots verwendet. Details und Befunde unter `docs/TESTING.md`.

## Datenschutz

Messungen werden im Application-Support-Verzeichnis der App als atomar geschriebene JSON-Datei mit iOS-Dateischutz gespeichert. iOS-Gerätesicherungen können diese Datei enthalten. Standort- und Sensordienste laufen nur während einer aktiven Messung. Beim Wechsel in den Hintergrund wird abgebrochen. CSV-Export erfolgt nur auf Nutzeraktion und enthält gegebenenfalls genaue Koordinaten. Keine eigenen Netzwerkübertragungen.

## TestFlight

Bundle-ID: `com.debbrecht.pvkompass`, Apple-Team: `4V346NPC35`.

Signierung und Upload verwenden vorhandene Apple-Zugangsdaten außerhalb des Repositorys. Keine Schlüssel oder Provisioning-Profile einchecken. Es wird nur zu TestFlight hochgeladen, nicht zur öffentlichen App-Store-Veröffentlichung eingereicht. Siehe `docs/RELEASE.md`.
