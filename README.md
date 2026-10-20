# OldMusic

L'app **iPod di iOS 6** estratta da [The OldOS Project](https://github.com/zzanehip/The-OldOS-Project) (di Zane Kleinberg) e trasformata in un'app standalone, a schermo intero, per iPhone e iPad recenti.

- **Nome:** OldMusic
- **Bundle ID:** `com.iamgasgass.oldmusic`
- **iOS minimo:** 16.0 (iPhone + iPad, solo verticale; Cover Flow ruotando il dispositivo)
- **Progetto:** generato con [XcodeGen](https://github.com/yonaskolb/XcodeGen) da `project.yml`
- **CI:** `.github/workflows/build.yml` → produce `OldMusic.ipa` (non firmato) come artifact

## Cosa c'è dentro (dal progetto originale)

Tutte le viste dell'app iPod di OldOS, con gli stessi nomi, gradienti e misure:

| Area | Viste originali |
| --- | --- |
| Shell | `iPod`, `iPodTabView`, `TabButton`, `ipod_title_bar`, `status_bar_in_app`, `status_bar` |
| Playlists | `ipod_playlists`, `SkeuomorphicList_Playlists`, `ipod_playlists_desination` (Edit/Clear/Delete, Shuffle) |
| Artists | `ipod_artists`, `SkeuomorphicList_Artists`, `artists_destination`, `albums_destination` |
| Songs | `ipod_songs`, `SkeuomorphicList_Songs`, `shuffle`, indice verticale `VerticalIndex` |
| Videos | `ipod_videos` ("No Videos" + `Arrow`) |
| More | `ipod_more` (Albums, Audiobooks, Composers, Genres, iTunes U, Podcasts) |
| Now Playing | `iPodNowPlaying`, `now_playing_title_bar`, `now_playing_timing_controls` (scrubber, repeat, shuffle), `now_playing_tracks` (flip con lista tracce + stelle), `now_playing_footer` (prev/play/next + volume) |
| Cover Flow | `CoverFlowView`, `CoverFlow_Sub` (iCarousel `coverFlow2`), `coverflow_selected_item` (flip con tracce) |
| Ricerca | `ipod_search` con la **tastiera iOS 6 di OldOS** (`OldOSKeyboard/`, copiata integralmente) |
| Comuni | `CustomSlider`, `VolumeObserver`, ombre interne, bordi, `alpha_list_header`, `generic_text_list_header` |

Asset: `iPod Icons`, `UIKit`, `UIKit Text Interaction` (tastiera) e i pulsanti condivisi copiati dall'asset catalog originale; icona dell'app = icona iPod di OldOS.

## Bug dell'originale corretti

1. **Riproduzione bloccata senza Apple Music**: ogni tap passava da `SKCloudServiceController` e suonava solo con abbonamento (`musicCatalogPlayback`). Ora la libreria locale suona sempre.
2. **Notifiche del player mai attivate** (`beginGeneratingPlaybackNotifications` mancante): play/pausa, titolo, copertina e brano evidenziato non si aggiornavano.
3. **Coda di un solo brano**: toccando un brano si accodava solo quello (avanti/indietro non funzionavano). Ora viene accodata la lista intera (Songs, album, playlist, risultati di ricerca, More…) partendo dal brano scelto, come su iOS 6. Shuffle usa la modalità shuffle del player.
4. **Tracce dell'album in Now Playing ordinate per titolo** → ora per disco/numero traccia.
5. **`removeDuplicates` per titolo** eliminava tracce diverse con lo stesso nome → ora per `persistentID`.
6. **Durata album errata** ("N Songs, X Mins." usava la durata di un solo brano) → somma reale; anno con fallback su `releaseDate`.
7. **Artisti nei risultati di ricerca non cliccabili** → aprono l'artista; aggiunta la sezione **Albums** nei risultati (come iOS 6).
8. **Indici A–Z sbagliati** (minuscole, accenti, "The …" finivano in "#") → sezioni prese da `MPMediaQuery.itemSections/collectionSections`, le stesse dell'app Musica. Tap su una lettera vuota → sezione successiva.
9. **Songs escludeva i brani iCloud** mentre Artists no → libreria coerente; ricarica automatica quando la libreria cambia (`MPMediaLibraryDidChange`), caricamento in background.
10. **Stato SwiftUI modificato da thread in background** (timer di Now Playing, callback del player) → tutto sul main thread.
11. **Scrubber**: la posizione veniva impostata da un thread in background a ogni movimento e "saltava indietro" → seek unico sul main thread al rilascio.
12. **Volume**: `MPVolumeView` creato e buttato a ogni movimento → un'unica `MPVolumeView` nascosta nella finestra (sopprime anche l'HUD moderno).
13. **Repeat** partiva da "Repeat One" con modalità `.default`; **Shuffle** risultava acceso con `.default` → ciclo corretto Off → All → One.
14. **Network monitor**: creava un nuovo `NWPathMonitor` ogni secondo senza mai fermarlo (leak) → un solo monitor condiviso.
15. **Cover Flow**: crash possibili con libreria vuota / `currentItemView!`; orientamento non aggiornato passando da landscape sinistro a destro; carousel non ricaricato se la libreria finiva di caricare dopo; tap sulle tracce suonava un solo brano. Le immagini `CoverFlowPlayIndicator`/`CoverFlowInfoIcon` non esistevano nell'asset catalog → disegnate (il pulsante play/pausa funziona).
16. Pulsante **Now Playing** e icona "in riproduzione" nelle liste non reattivi → osservano il player.
17. **More** e **Videos** erano solo grafici → ora navigabili (Albums, Generi → album, Compositori, Audiolibri, Podcast, iTunes U) e i video della libreria (se presenti) vengono elencati e riprodotti.

## Schermo intero

- Status bar di sistema nascosta: viene disegnata quella di iOS 6 subito sotto la notch / Dynamic Island, e l'area sopra viene riempita con lo stesso colore.
- La barra dei tab resta sopra l'indicatore Home; il fondo è nero come su iOS 6.
- **Now Playing** come su iPhone 5 con iOS 6: copertina quadrata in alto e riflesso nello spazio restante sopra i controlli; il retro (lista tracce) occupa tutta l'altezza.
- iPad: `UIRequiresFullScreen`, interfaccia verticale; Cover Flow si attiva ruotando il dispositivo (come l'originale).

## Build

### GitHub Actions
Fai push della repo su GitHub: il workflow **Build OldMusic** (`.github/workflows/build.yml`) gira su `macos-15` con l'ultimo Xcode stabile, installa XcodeGen, genera `OldMusic.xcodeproj` da `project.yml`, compila per `iphoneos` senza firma e carica `OldMusic.ipa` come artifact (da firmare/installare con AltStore, Sideloadly, TrollStore, ecc.). Si può avviare anche a mano (*workflow_dispatch*).

### In locale
```bash
brew install xcodegen
xcodegen generate
open OldMusic.xcodeproj
```
Imposta il tuo Team in *Signing & Capabilities* e avvia su un dispositivo reale (il simulatore non ha una libreria musicale).

## Dipendenze (Swift Package Manager)
- [PureSwiftUITools 2.0.2](https://github.com/CodeSlicing/pure-swift-ui-tools) (+ PureSwiftUI) — stesse versioni dell'originale
- [SwiftUI-Introspect 0.1.4](https://github.com/siteline/SwiftUI-Introspect) — usata dalla tastiera OldOS
- iCarousel / FXImageView / ReflectionView (Objective-C, incluse in `OldMusic/Carousel`)

## Licenza
Il codice proviene da The OldOS Project — Creative Commons Attribution 4.0 (CC BY 4.0), © Zane Kleinberg. Tutte le modifiche di OldMusic sono segnate nel codice con `OldMusic fix`.
