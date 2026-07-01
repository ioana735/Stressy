# Stressy 🐣

Un *tamagotchi atipic* pentru studenti, construit cu **Flutter + Flame**. Ai grija
de Stressy balansandu-i nevoile (Energie, Focus) cu propriile tale sesiuni reale
de invatat (Pomodoro). Totul ruleaza **local**, fara backend.

## Cum functioneaza
- **Energie** si **Focus** scad in timp (decay bazat pe timp real, chiar si cu app-ul inchis).
- Pornesti o **sesiune de studiu** (25 min) -> Stressy intra in modul "focus".
- La final esti recompensat: **+Knowledge**, focus refacut, confetti 🎉.
- **Knowledge** = progresul tau real (XP), nu scade niciodata -> nivele si outfit-uri.

## Mecanici de retentie
1. 🔥 **Streak zilnic** – zile consecutive cu cel putin o sesiune.
2. 👕 **Outfit-uri** – deblocate prin ore totale de studiu (5h, 20h, 50h, 100h).
3. 🌅 **Bonus zilnic** – prima sesiune a zilei da x1.5 XP.

## Structura
```
lib/
├── main.dart                # entry + ProviderScope
├── models/                  # StressyModel (decay/recompense), Outfit
├── game/                    # Flame: StressyGame + components/
├── logic/                   # StudyTimer (Pomodoro), StreakService
├── data/                    # StorageService, NotificationService
├── state/                   # StressyController (Riverpod StateNotifier)
├── screens/                 # HomeScreen, WardrobeScreen
└── widgets/                 # StatBar, StudyButton
test/                        # teste unitare pentru decay + streak
```

## Rulare
```bash
flutter pub get
flutter run
flutter test
```

## Note
- Stressy e desenat **procedural** (vezi `stressy_component.dart`) ca sa ruleze
  fara asset-uri. Pune sprite sheet-uri in `assets/images/` si comuta pe
  `SpriteAnimationGroup` (instructiuni in comentariile componentei).
- Notificarile programate la ora exacta necesita pachetul `timezone` + `zonedSchedule`.
```
