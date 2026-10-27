# Messverfahren und Datenvertrag

## Geometrie

Alle Eingangsvektoren liegen im selben gerätefesten Core-Motion-Koordinatensystem. Geräte-Z zeigt aus dem Bildschirm. Für ein auf der Modulvorderseite mit der Rückseite aufgelegtes iPhone ist Z die nach außen gerichtete Modulnormale.

1. `up = -normalize(gravity)`.
2. `north = normalize(field - up * dot(field, up))` entfernt die magnetische Inklination.
3. `east = normalize(cross(north, up))`.
4. Neigung `acos(dot(Z, up))` gegenüber der Waagerechten.
5. Magnetischer Modulazimut `atan2(dot(Z,east), dot(Z,north))`.
6. Geografische Deklination = `CLHeading.trueHeading - CLHeading.magneticHeading`; geografischer Azimut = magnetischer Azimut + Deklination, auf 0...360 normalisiert.

Die Differenz der beiden CLHeading-Werte ist von der eingestellten Handy-Oberkantenrichtung unabhängig. Eulerwinkel, Displayrotation oder die Richtung der Handyoberkante werden nicht als Modulazimut verwendet. Die orthonormale Basis aus Schwerkraft und kalibriertem Magnetfeld vermeidet uneindeutige Eulerwinkel bei senkrechten Modulen.

## Qualitätsprüfung

20 Sensorwerte/Sekunde, rollendes Fünf-Sekunden-Fenster. Mindestens 60 Werte und vier Sekunden Fensterdauer, Neigungsschwankung höchstens 1,5°, Richtungsschwankung höchstens 6°. Winkel werden zirkulär gemittelt (359° und 1° ergeben Nord, nicht Süd). Beschleunigung/Rotationsrate, Core-Motion-Kalibrierstatus und Feldstärke außerhalb 20...80 µT verhindern einen erfolgreichen Abschluss. Mindest-Gesamtdauer sechs Sekunden; magnetischer Fallback frühestens nach 18 Sekunden. Abbruch bei 40 Sekunden ohne stabile Messung. Ungültige Rückseitenlage wird zurückgewiesen. Bei unter 3° Neigung bleibt Azimut leer.

Nordbezugwechsel setzt das Messfenster zurück; magnetische und geografische Winkel werden nicht gemischt. Geografische Korrektur benötigt einen frischen Standort (höchstens 60 Sekunden), frische Kompassdaten (höchstens fünf Sekunden), gültigen trueHeading und gemeldete Kompassgenauigkeit höchstens 20°. Keine Garantie absoluter Genauigkeit: plausible konstante magnetische Ablenkung ist nicht sicher erkennbar.

## HA und CSV

HA Forecast.Solar: Nord 0°, Ost 90°, Süd 180°, West 270°.
Direkte Forecast.Solar-API: aspect = HA-Azimut minus 180° (Nord −180°, Ost −90°, Süd 0°, West 90°).
Andere Integrationen vorher prüfen; keine allgemeine HA-Konvention behaupten.

CSV: UTF-8 mit BOM, Komma-Trenner, CRLF, englische Dezimalpunkte, doppelte Anführungszeichen mit RFC-4180-Quoting. Nutzername wird gegen Tabellenformeln abgesichert; numerische Negativwerte bleiben unverändert. UTC-Zeitstempel plus ursprüngliche IANA-Zeitzone; GPS mit Genauigkeit und Zeitstempel. Fehlende Daten bleiben leer, nicht Null. HA-Felder bleiben bei magnetischen Messungen, undefiniertem Azimut oder Simulator-Demos leer.

## Quellen

- https://developer.apple.com/documentation/coremotion/getting-processed-device-motion-data
- https://developer.apple.com/documentation/coremotion/cmcalibratedmagneticfield
- https://developer.apple.com/documentation/corelocation/clheading
- https://www.home-assistant.io/integrations/forecast_solar/
