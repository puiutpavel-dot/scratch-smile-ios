# Lozuri

Joc iOS de lozuri răzuibile cu monede virtuale (SwiftUI, iOS 17+). Se construiește gratuit prin GitHub Actions, fără Mac.

## Ce e în proiect

- `Sources/` – codul aplicației și iconița (provizorie)
- `project.yml` – din el se generează proiectul Xcode la fiecare build (XcodeGen)
- `.github/workflows/ios.yml` – build-ul: `verificare` (compilare) și `testflight`
- `scripts/` – pregătirea build-ului prin App Store Connect API și semnarea în cloud
- `docs/index.html` – politica de confidențialitate (pentru GitHub Pages)

## Build

Fila **Actions** → **iOS** → **Run workflow** → alegi acțiunea.

- `verificare` compilează pentru simulator; rulează și singură la fiecare modificare a codului.
- `testflight` are nevoie de secretele `ASC_KEY_ID`, `ASC_ISSUER_ID` și `ASC_PRIVATE_KEY` (aceleași ca la celelalte aplicații). Bundle ID-ul `ro.draghicioiu.lozuri` și Game Center se înregistrează singure; aplicația din App Store Connect trebuie creată manual, o singură dată.

## De făcut în App Store Connect

- Creează aplicația cu Bundle ID-ul `ro.draghicioiu.lozuri`.
- La Game Center: un clasament cu ID-ul `lozuri.monede` și patru realizări: `lozuri.primul_jackpot`, `lozuri.100_lozuri`, `lozuri.serie_7`, `lozuri.toate_mesajele`.

## Politica de confidențialitate

Completează emailul în `docs/index.html`, apoi Settings → Pages → Deploy from branch → `main` / `docs`.
