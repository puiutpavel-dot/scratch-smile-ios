# Scratch & Smile

Joc iOS de lozuri răzuibile cu monede virtuale (SwiftUI, iOS 17+), în 7 limbi. Se construiește gratuit prin GitHub Actions, fără Mac.

## Limbi

Română, engleză, spaniolă, franceză, germană, italiană și portugheză. Aplicația ia singură limba telefonului; pentru orice altă limbă se afișează în engleză.

Toate textele sunt în `tools/l10n.py`, câte un rând pe text, cu cele 7 traduceri. După orice modificare rulează `python3 tools/l10n.py`, care rescrie fișierele din `Sources/*.lproj/`. În cod, textele se cer cu `L("cheie")`.

## Ce e în proiect

- `Sources/` – codul aplicației, traducerile și iconița (provizorie)
- `project.yml` – din el se generează proiectul Xcode la fiecare build (XcodeGen)
- `.github/workflows/ios.yml` – build-ul: `verificare` (compilare) și `testflight`
- `scripts/` – pregătirea build-ului prin App Store Connect API și semnarea în cloud
- `tools/l10n.py` – tabelul de traduceri
- `docs/index.html` – politica de confidențialitate, în engleză și română (pentru GitHub Pages)

## Build

Fila **Actions** → **iOS** → **Run workflow** → alegi acțiunea.

- `verificare` compilează pentru simulator; rulează și singură la fiecare modificare a codului.
- `testflight` are nevoie de secretele `ASC_KEY_ID`, `ASC_ISSUER_ID` și `ASC_PRIVATE_KEY` (aceleași ca la celelalte aplicații). Bundle ID-ul `ro.draghicioiu.scratchsmile` și Game Center se înregistrează singure; aplicația din App Store Connect trebuie creată manual, o singură dată.

## De făcut în App Store Connect

- Creează aplicația „Scratch & Smile” cu Bundle ID-ul `ro.draghicioiu.scratchsmile`.
- La Game Center: un clasament cu ID-ul `scratchsmile.coins` și patru realizări: `scratchsmile.first_jackpot`, `scratchsmile.100_tickets`, `scratchsmile.streak_7`, `scratchsmile.all_messages`.

## Înainte de lansare

- Schimbă `supportEmail` din `Sources/ScratchCard.swift` și emailul din `docs/index.html`.
- Înlocuiește iconița provizorie din `Sources/Assets.xcassets/AppIcon.appiconset/icon.png`.
- Politica de confidențialitate: Settings → Pages → Deploy from branch → `main` / `docs`.
