# Publicare Stressy pe App Store 📱

## Stare curentă (pregătit deja) ✅
- ✅ Platforma iOS în proiect
- ✅ Iconița aplicației (generată pe toate dimensiunile)
- ✅ Nume afișat: **Stressy**
- ✅ Bundle ID: `com.ioana735.stressy`
- ✅ macOS 26.5.2 (compatibil cu Xcode)

## Ce mai trebuie (pașii tăi)

### 1. Instalează Xcode
App Store → caută **Xcode** → Install (~7-12 GB). Deschide-l o dată după instalare.

### 2. Configurează Xcode pentru Flutter (comenzi)
```bash
sudo xcodebuild -license accept
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
flutter doctor
```

### 3. Testează pe iPhone-ul tău (cont Apple gratuit)
- Conectează iPhone cu cablu → „Trust"
- iPhone: Settings → Privacy & Security → **Developer Mode → ON** (repornire)
- Deschide `ios/Runner.xcworkspace` în Xcode → tab **Signing & Capabilities**
  → Team: **Add Account** (Apple ID gratuit) → alege team-ul
- Din terminal:
```bash
cd /Users/HP/Documents/stressy/Stressy
flutter run --release
```
(app valabil 7 zile per instalare cu cont gratuit)

### 4. Pentru App Store (cont plătit)
1. **Apple Developer Program**: developer.apple.com → înscriere **99$/an**
2. **App Store Connect** (appstoreconnect.apple.com):
   - „+" → New App → nume „Stressy", bundle id `com.ioana735.stressy`, limbă, categorie (Education/Productivity)
3. Construiește arhiva:
```bash
flutter build ipa
```
4. Upload build:
   - Deschide `build/ios/archive/Runner.xcarchive` în Xcode → **Distribute App** → App Store Connect
   - SAU folosește aplicația **Transporter** (din App Store) cu fișierul `.ipa`
5. În App Store Connect completează:
   - **Capturi de ecran** (obligatoriu: iPhone 6.7")
   - **Descriere**, cuvinte cheie, **politică de confidențialitate** (URL)
   - Preț (gratis)
6. **Submit for Review** → Apple verifică (1-3 zile) → publicat 🎉

## Note
- Politica de confidențialitate: fiindcă datele sunt **doar locale** (fără cont/cloud),
  e simplă — „nu colectăm date". Pot genera un text.
- Apple cere capturi de ecran; le putem face din simulator sau de pe telefon.
- Bundle id-ul trebuie să fie **unic global** — dacă `com.ioana735.stressy` e luat,
  îl schimbăm.
