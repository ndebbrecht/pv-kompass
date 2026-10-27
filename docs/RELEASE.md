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
