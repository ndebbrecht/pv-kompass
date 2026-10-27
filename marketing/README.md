# PV Kompass – Veröffentlichung vorbereiten

Stand: 27.10.2026. Die Materialien sind vorbereitet. Es wurde nichts in App Store Connect hochgeladen, kein neuer TestFlight-Build erstellt und keine öffentliche Veröffentlichung oder Review ausgelöst.

## Enthalten

- `icon/pv-kompass-1024.png`: fertiges App-Icon, 1024 × 1024 Pixel, PNG ohne Alphakanal. Im Xcode-Asset `AppIcon.png` eingebunden.
- `icon/pv-kompass-generated-master.png`: unverändertes Original aus der integrierten Bildgenerierung. Der genaue Prompt steht in `icon/GENERATION.md`.
- `app-store/de-DE/screenshots/medium/`: fünf fertige deutsche Store-Bilder, 1206 × 2622 Pixel.
- `app-store/de-DE/screenshots/large/`: dieselben fünf Motive, 1320 × 2868 Pixel.
- `app-store/de-DE/index.html`: semantische, VoiceOver-lesbare Übersicht mit allen Bildbeschreibungen und Downloadlinks.
- `app-store/de-DE/BILDBESCHREIBUNGEN.txt`: alle Inhalte als einfacher Text.
- `app-store/de-DE/preview.jpg`: gemeinsame visuelle Vorschau beider Bildsätze.
- `app-store/de-DE/raw/`: unkomprimierte native Screenshots aus iPhone 17 Pro und iPhone 17 Pro Max, iOS 26.2.
- `app-store/de-DE/manifest.json` und `validation.json`: Motivbeschreibungen und technische Prüfungen.

Die fünf Motive zeigen Messstart, abgeschlossenes Ergebnis, benannten Verlauf, natives CSV-Teilen und Messanleitung. Alle Messdaten sind ausdrücklich gekennzeichnete Beispieldaten. Die Beispielskoordinaten sind generische Berliner Stadtkoordinaten, keine privaten Standortdaten. Die App-Oberflächen wurden nicht nachgezeichnet oder per KI verändert. Für das Icon wurde das integrierte Bildgenerierungswerkzeug verwendet; die Store-Layouts wurden deterministisch aus echten App-Screenshots zusammengesetzt.

## Aufnahme und Export

Die App wurde mit Xcode-MCP gebaut und auf zwei Simulatoren bedient. MCP-Screenshots wurden für Vorschau und Kontrolle verwendet. Da diese MCP-Version Vorschauen auf 800 Pixel Höhe reduziert, wurden zusätzlich dieselben unveränderten Ansichten mit `xcrun simctl io <UUID> screenshot --type=png <Datei>` verlustfrei in nativer Auflösung exportiert. Keine Hochskalierung der MCP-Vorschaubilder.

Aufnahme: heller Modus, deutsche App-/Systemtexte, 09:41-Statusleiste, isolierte Simulator-Beispieldaten. Es wurden keine echten Sensordaten erfunden oder Beispieldaten auf ein physisches iPhone übertragen. Der bisherige TestFlight-Build 3 bleibt unverändert. Das neue Icon wird erst mit einem neuen App-Build auch auf dem iPhone installiert; hierfür muss die Buildnummer erhöht werden.

Die Marketing-Layouts lassen sich neu rendern:

```sh
node marketing/scripts/render-screenshots.cjs
```

Das Skript nutzt lokal `playwright-core` und Chrome im Headless-Modus. Auf anderen Rechnern lassen sich Modul- und Browserpfad über `PLAYWRIGHT_CORE_PATH` und `CHROME_PATH` setzen. `large`, `medium` oder `preview` als Argument rendert nur den jeweiligen Teil. Alle Headless-Browser werden anschließend geschlossen.

## Apple-Formate

Prüfquelle: https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications

Nach der am 27.10.2026 abgerufenen Spezifikation ist ein Bild für iPhone mit Dynamic Island, mittlere Anzeige, erforderlich; 1206 × 2622 Pixel ist akzeptiert. 1320 × 2868 Pixel ist das zusätzlich vorbereitete Format für große Anzeigen. Die fertigen JPG-Dateien enthalten keine Transparenz. iPad-Material ist nicht erforderlich, weil die App nur iPhone unterstützt.

Die Formatprüfung ersetzt keine App-Store-Review und keine physische Sensor- oder VoiceOver-Prüfung. Die Bilder machen keine garantierten Genauigkeitsversprechen.
