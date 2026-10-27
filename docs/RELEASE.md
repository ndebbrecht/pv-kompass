# TestFlight-Release

Ziel: private TestFlight-Nutzung durch Niklas; keine öffentliche App-Store-Veröffentlichung.

## Stand 27.10.2026

- Xcode 26.2, bestehendes Apple-Distribution-Zertifikat und bestehender ASC-API-Schlüssel vorhanden.
- Schlüssel aus vorhandener Reverse-Snake-GitLab-Konfiguration privat bereitgestellt; nicht im Repository.
- Zu Beginn gab die Apple-API für Apps, Zertifikate und Bundle-IDs HTTP 403 `FORBIDDEN.REQUIRED_AGREEMENTS_MISSING_OR_EXPIRED` zurück. Der Accountinhaber musste die ausstehenden Vereinbarungen unter App Store Connect → Business bzw. developer.apple.com/account bestätigen. Diese rechtliche Zustimmung übernimmt die App-/Build-Automation nicht.
- Danach Bundle-ID registrieren, neues App-Store-Provisioning-Profil mit dem vorhandenen Zertifikat erstellen; kein Zertifikat widerrufen oder unnötig neu anlegen.
- Neues App-Record für „PV Kompass“, Sprache Deutsch, Plattform iOS, Bundle-ID com.debbrecht.pvkompass in App Store Connect anlegen. Die öffentliche ASC-API unterstützt laut Apple keine App-Neuanlage; dafür Website verwenden.
- Release archivieren, als app-store-connect exportieren und per Transporter/Fastlane hochladen.
- Verarbeitung und Export-Compliance prüfen, internen Tester Niklas bzw. interne Gruppe hinzufügen, Build tatsächlich als installierbar prüfen. Ein erfolgreicher Upload allein gilt nicht als fertige Bereitstellung.

## Zugangsdaten

Lokale Freigabe-/Schlüsseldateien befinden sich ausschließlich außerhalb des Repositories unter Alfreds privaten Release-Arbeitsdateien. GitLab-CI verwendet File-Variablen für P8-Inhalt und maskierte Variablen, keine Schlüssel im YAML.

## Archiv/Export

Nach Erstellung des App-Store-Profils mit Namen `PV Kompass App Store`:

```sh
xcodegen generate
xcodebuild -project PVKompass.xcodeproj -scheme PVKompass -configuration Release \
  -destination 'generic/platform=iOS' -archivePath build/PVKompass.xcarchive \
  CODE_SIGN_STYLE=Manual CODE_SIGN_IDENTITY='Apple Distribution' \
  PROVISIONING_PROFILE_SPECIFIER='PV Kompass App Store' archive
xcodebuild -exportArchive -archivePath build/PVKompass.xcarchive \
  -exportPath build/export -exportOptionsPlist scripts/ExportOptions.plist
fastlane pilot upload --ipa build/export/PVKompass.ipa --api_key_path "$ASC_API_KEY_JSON"
```

Simulator-Demomodus ist nur unter `targetEnvironment(simulator)` und explizitem Launchargument aktiv. Er ist auf physischen Geräten nicht verfügbar.

Update: Developer-Lizenzannahme durch Apple-Mail um 12:12 Uhr bestätigt; API-Zugang nach Verzögerung freigegeben. Bundle-ID und App-Store-Profil mit vorhandener Identität erfolgreich erstellt. App-Neuanlage per API nachweislich nicht erlaubt (CREATE→403); Niklas um einmalige Anlage auf der Website gebeten.

## Upload am 27.10.2026, 13:13 Uhr

Niklas hat den ASC-App-Eintrag angelegt: App-ID `6827541265`, Bundle-ID wie geplant, Sprache de-DE. Die signierte IPA wurde um 13:13:32 erfolgreich von App Store Connect angenommen. Version 1.0.0, Build 1. Apple-Verarbeitung und installierbarer TestFlight-Zugang sind noch zu prüfen.

Interne Gruppe „Niklas – intern“ angelegt (`cc22a1b4-18b5-4c4b-bd1f-a47bb41741d1`), nur Niklas zugeordnet. BetaTester-IDs sind hier app-spezifisch: Wiederverwenden der KnowDown-ID ergab 409; POST betaTesters mit derselben E-Mail und neuer Gruppenrelation erzeugte den passenden PV-Kompass-Tester `958e0f11-b470-42ab-8055-e017776f80d1`. Andere Apps/Tester unverändert.

## TestFlight verfügbar

Apple-Verarbeitung abgeschlossen. Build `520c48af-36a8-4c3c-ad01-c21598ebf9f5` (1.0.0 / 1) hat `processingState=VALID`, `usesNonExemptEncryption=false` und `internalBuildState=IN_BETA_TESTING`. Interne Gruppe enthält diesen Build und Niklas. Testerstatus von Apple: `INSTALLED` (dies ist Apples API-Status, kein unabhängiger Nachweis eines physischen Tests). Deutsche Testhinweise gespeichert. Keine externe Beta-Review oder öffentliche Veröffentlichung ausgelöst.

Installation: TestFlight auf Niklas’ iPhone öffnen, PV Kompass auswählen und installieren. Voraussetzung iOS 17 oder neuer. 18/18 Simulator-Tests via Xcode-MCP bestanden; echte Sensorqualität und VoiceOver-Bedienung durch Niklas bleiben reale Gerätetests.

## Build 2 – Rückmeldungen vom ersten Gerätetest

- Unbestimmbare Ausrichtung wird direkt im Ergebnis und im Detail erklärt; bei unter 3° Neigung zeigt die Flächennormale nahezu nach oben, eine Himmelsrichtung wäre irreführend. Auch die HA-Erklärung enthält diesen Grund.
- Vorbereitung wartet auf die Entscheidung im Standortdialog und eine aktive App. Messzeit und Sensordatensammlung beginnen erst danach. Standortverweigerung erlaubt weiterhin eine ausdrücklich markierte Messung ohne GPS. Inaktive Systemdialoge brechen die Messung nicht mehr ab; echter Hintergrundbetrieb dagegen schon.
- VoiceOver erhält nach dem Start eine explizite, verzögerte und eingereihte Startansage, zusätzlich zu haptischem Feedback. Abschlussansage nennt bei fehlender Ausrichtung den Grund.
- CSV-Teilen liegt oben rechts in der Titelleiste, sowohl auf dem Messscreen nach Abschluss als auch im Messdetail. Kein Scrollen bis ans Listenende erforderlich.

Der Standort-Warteablauf wird zusätzlich mit einem expliziten Simulator-Fixture geprüft. Dieses Fixture ist nicht auf physischen Geräten verfügbar. Den realen iOS-Freigabedialog und gesprochene VoiceOver-Ansagen muss Niklas weiterhin am Gerät gegenprüfen.

Build 2 ist verarbeitet und für Niklas in der internen TestFlight-Gruppe verfügbar. Build-ID `bdbecea1-1a16-4da3-a329-cf9280ae3843`, `VALID`, `IN_BETA_TESTING`, Export-Compliance unverändert `usesNonExemptEncryption=false`. Gruppen-Zuordnung nach Verarbeitung separat geprüft; deutsche Releasehinweise gespeichert.

## Build 3 – Messverlauf

- Teilen-Button oben rechts im Messverlauf exportiert alle aktuell gespeicherten Messungen als eine CSV mit nur einer Kopfzeile. Reihenfolge entspricht der Liste (neueste zuerst); vorhandene GPS-Daten und alle bisherigen Spalten bleiben enthalten. Bei leerem Verlauf ist der Button deaktiviert.
- „Alle Messungen löschen“ steht in einem eigenen Abschnitt unter sämtlichen Messungen. Eine Bestätigung nennt die Anzahl und weist auf Unwiderruflichkeit hin.
- Einzelne Messungen lassen sich per Wischgeste oder benannter VoiceOver-Aktion löschen, jeweils nach Bestätigung. Full-Swipe-Löschen ist deaktiviert.
- Löschungen werden atomar gespeichert; bei Schreibfehlern bleibt der sichtbare Verlauf unverändert. Gelöschte aktuelle Ergebnisse werden auch vom Messscreen entfernt. Bereits exportierte Dateien werden nicht gelöscht.

Build 3 signiert und erfolgreich zu Apple hochgeladen. Finales Archiv: `build/PVKompass-Build3-Final.xcarchive`, IPA: `build/release-build3/PVKompass.ipa`. Signatur, iPhone-Gerätefamilie, Bundle und Buildnummer 3 geprüft. Apple-Verarbeitung steht zum Uploadzeitpunkt noch aus.

Apple-Verarbeitung von Build 3 abgeschlossen: `VALID` und `IN_BETA_TESTING`. Build-ID `6990fc60-ba32-477c-b794-4e650fe2830e`. Build und Niklas sind in der internen Gruppe verifiziert; deutsche TestFlight-Hinweise aktualisiert. Version 1.0.0 (3) kann über TestFlight installiert werden.
