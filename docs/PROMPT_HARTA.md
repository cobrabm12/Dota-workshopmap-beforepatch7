# Prompt pentru Claude Code pe PC-ul de gaming (CachyOS, Steam + Dota 2 instalate)

Copiază tot textul de mai jos într-o sesiune Claude Code deschisă în folderul în care ai clonat acest repo.

---

Lucrez la proiectul din acest repo (addon Dota 2 „Dota 6.88 Classic”). Vreau să recuperăm harta 6.88 din clientul
Dota 2 de pe 7 decembrie 2016 (build 1805, ultimul înainte de 7.00) și să o decompilăm într-un `.vmap` pentru Hammer.
Citește mai întâi `docs/HARTA.md` și `tools/map_files_688.py`. Sistemul este CachyOS (Arch), am Steam și Dota 2 instalate.

Reguli:
* NU îmi cere parola de Steam și nu o pune în comenzi sau fișiere. Când DepotDownloader cere parola sau codul Steam Guard,
  oprește-te și lasă-mă pe mine să le tastez în terminal (rulează comanda în foreground, ca să pot interacționa).
* Nu șterge și nu modifica nimic în instalarea Steam/Dota 2. Tot ce descarci pune în `~/dota688_depot/`.
* Confirmă cu mine înainte de a porni descărcări mai mari de 1 GB (spune-mi cât va fi).

Pașii:

1. **Unelte**: instalează `dotnet-runtime` (sau `dotnet-sdk`) din pacman dacă lipsește; descarcă ultimul release
   DepotDownloader pentru linux-x64 de pe https://github.com/SteamRE/DepotDownloader/releases și ultimul
   Source2Viewer-CLI pentru linux-x64 de pe https://github.com/ValveResourceFormat/ValveResourceFormat/releases, în `~/dota688_tools/`.
   Verifică fiecare cu `--help`.

2. **Manifestul din 7 decembrie 2016**: eu îți dau ID-ul depotului și ID-ul manifestului de pe
   https://steamdb.info/app/570/depots/ (depotul „Dota 2 Content”, pagina Manifests, intrarea din 7 dec 2016, înainte de
   cea din 12 dec 2016 care este 7.00). Dacă nu ți le-am dat încă, întreabă-mă. Apoi verifică fără descărcare, cu
   `-manifest-only`, că manifestul conține `game/dota/pak01_dir.vpk` și că listarea include fișierele hărții
   (compară cu `reference/6.88f/maps_dota_manifest.txt`; `maps/dota.vmap_c` trebuie să fie în pak01 la acea dată).
   Dacă depotul nu conține pak01, încearcă și celelalte depoturi de conținut ale app-ului 570 (373301–373306), tot cu `-manifest-only`.

3. **Descărcare**: `DepotDownloader -app 570 -depot <depot> -manifest <manifest> -username <contul meu> -remember-password
   -filelist pak01.txt -dir ~/dota688_depot`, unde `pak01.txt` conține linia `regex:game/dota/pak01_.*\.vpk`.
   Spune-mi dimensiunea totală înainte. Nu rula nimic cu `sudo`.

4. **Decompilare**: cu Source2Viewer-CLI, din `~/dota688_depot/game/dota/pak01_dir.vpk`, exportă/decompilează
   `maps/dota.vmap_c` (încearcă `-d` cu `-f maps/dota.vmap_c` și, dacă există, opțiunea de export vmap; citește `--help`
   și https://s2v.app/ValveResourceFormat/guides/exporting-maps.html). Pune rezultatul în
   `content/dota_addons/dota_688/maps/` din repo, ca `dota_688.vmap` cu folderul `maps/dota_688/` lângă (redenumește din `dota`).
   Dacă CLI-ul nu poate scrie `.vmap` (doar GUI-ul Windows poate), extrage cel puțin fișierele brute ale hărții (lista din
   `build/map_files_688.txt`, generată de `python3 tools/map_files_688.py`) în `~/dota688_depot/map_raw/` și spune-mi,
   ca să fac exportul în GUI-ul Source 2 Viewer pe Windows.

5. **Analiză**: dacă ai obținut `.vmap`, fă un raport în `docs/HARTA_ENTITATI.md`: ce entități conține
   (spawner-e de creepi și neutrali, Roshan, shop-uri, rune, turnuri, barăci, fântâni, efigii), cu pozițiile lor,
   și ce modele/materiale referite nu mai există în clientul Dota 2 curent (caută în VPK-urile din instalarea actuală a
   Dota 2, doar citire). Nu modifica `.vmap`-ul.

6. La final: `git add` pentru fișierele mici (raport, eventual `.vmap` dacă are sub 50 MB; folderul `maps/dota_688/` cu
   fișiere binare mari NU se comite – pune-l în `.gitignore`) și spune-mi ce ai comis. Nu face push fără să mă întrebi.

---

## Ce rămâne după acest prompt

* Hammer rulează doar pe Windows (Dota 2 Workshop Tools). Pe Linux poți încerca Workshop Tools prin Proton, dar nu este
  fiabil. Deschide `dota_688.vmap` în Hammer pe Windows, verifică entitățile după `docs/HARTA.md`, înlocuiește
  modelele lipsă și compilează; rezultatul este `game/dota_addons/dota_688/maps/dota_688.vpk`.
* Dacă Source2Viewer-CLI nu scrie `.vmap` pe Linux, fă exportul din GUI-ul Source 2 Viewer pe Windows (click dreapta pe
  `maps/dota.vmap_c` → Decompile & Export → vmap).
