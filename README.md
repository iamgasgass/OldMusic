# OldMusic

> A standalone, modern iOS rebuild of the **iPod** app from **The OldOS Project**, preserving the iOS 6 music player look while running full screen on current iPhones and iPads with iOS 16 or later.

[![iOS](https://img.shields.io/badge/iOS-16.0%2B-0A84FF?logo=apple&logoColor=white)](#requirements)
[![Swift](https://img.shields.io/badge/Swift-SwiftUI-F05138?logo=swift&logoColor=white)](#technology)
[![Build](https://img.shields.io/github/actions/workflow/status/iamgasgass/OldMusic/build.yml?branch=main&label=build)](https://github.com/iamgasgass/OldMusic/actions)
[![License](https://img.shields.io/badge/License-CC%20BY%204.0-lightgrey)](#license-and-attribution)

## Overview

**OldMusic** brings back the iOS 6 iPod app: blue-grey aluminium navigation bar, glossy search field, lettered table headers with the A–Z index, the black glass tab bar, the Now Playing screen with artwork reflection and the flip-over track list, and Cover Flow when the device is turned sideways.

It is not a skin over the Music app. OldMusic is a SwiftUI application that reads the device music library through MediaPlayer and drives the system music player, so everything you already have on your device (synced, purchased or added from Apple Music) can be browsed and played.

## Highlights

- iOS 6 iPod interface rebuilt for a modern full-screen layout: bars extend behind the status bar, notch / Dynamic Island and the home indicator.
- **Light and Dark Mode**: the classic blue-grey skin in Light Mode, an iOS 6 graphite skin in Dark Mode (bars, search, lists, headers, album pages, buttons). Now Playing, the tab bar and Cover Flow keep their original black chrome. The status bar style follows the visible screen.
- Playlists, Artists, Songs, Videos and More (Albums, Audiobooks, Composers, Genres, iTunes U, Podcasts), all navigable with the iOS 6 push / pop slides.
- Search in every list with Artists, Albums and Songs results.
- A–Z index bar using the same sections as the Music app; letters with no entries jump to the next section.
- Tapping a song queues the whole list from that song; Shuffle rows; repeat Off → All → One; shuffle toggle.
- Now Playing: square artwork with reflection, tap for scrubber / repeat / shuffle, double tap or the album button to flip to the album's tracks, volume slider (the system volume HUD is hidden).
- Cover Flow (iCarousel `coverFlow2`) with album flip and track list.
- Library changes are picked up live; loading happens in the background.
- No third-party Swift packages. Unsigned IPA workflow for GitHub Actions.

## Architecture

```text
OldMusic/
├── .github/workflows/build.yml       # XcodeGen + unsigned IPA build
├── project.yml                       # XcodeGen project description
├── OldMusic/
│   ├── OldMusicApp.swift             # App / scene delegate, status-bar aware hosting controller
│   ├── Models/                       # MusicRoute (tabs, pushed screens), MusicSection (A–Z)
│   ├── Store/                        # MusicLibrary, MusicPlayer, MusicNavigator, MusicVolume
│   ├── Views/                        # Root, library shell, lists, search, Now Playing, Cover Flow
│   ├── Support/                      # OldMusicKit (drawing helpers), palette (Light / Dark), slider
│   ├── Vendor/iCarousel/             # Objective-C Cover Flow carousel
│   ├── Assets.xcassets/              # OldOS iPod artwork and app icon (Any / Dark / Tinted)
│   └── Info.plist
├── EXTRACTION.json
├── README.md
└── LICENSE
```

- `MusicLibrary` loads songs, artists, albums, playlists, genres, composers, audiobooks, podcasts, iTunes U and videos on a background queue and reloads on `MPMediaLibraryDidChange`.
- `MusicPlayer` wraps `MPMusicPlayerController.systemMusicPlayer`, publishes the now playing item, state, shuffle and repeat, and queues lists with `MPMusicPlayerMediaItemQueueDescriptor`.
- `MusicNavigator` owns the visible screen (library / Now Playing / Cover Flow), the selected tab and one push stack per tab.
- `OldMusicTheme` holds every colour of both skins and is passed down through the environment.

## Requirements

- macOS with Xcode 16 or later and [XcodeGen](https://github.com/yonaskolb/XcodeGen).
- iPhone or iPad running iOS 16.0 or later (the Simulator has no music library).

## Build Locally

```bash
git clone https://github.com/iamgasgass/OldMusic.git
cd OldMusic
brew install xcodegen
xcodegen generate
open OldMusic.xcodeproj
```

Select your team under **Signing & Capabilities** and run on a device.

## Unsigned IPA via GitHub Actions

`.github/workflows/build.yml` runs on pushes to `main` / `master`, on pull requests and manually (`workflow_dispatch`). It generates the project from `project.yml`, builds with `CODE_SIGNING_ALLOWED=NO`, verifies the bundle and icon, packages `OldMusic-Unsigned.ipa` and uploads it together with the build log. Sign the IPA with AltStore, Sideloadly, Xcode or your own profile before installing.

## Known Limits

- Third-party apps cannot edit library playlists or write ratings: the playlist Edit / Clear / Delete buttons and the star rating are drawn as in OldOS but not saved.
- Videos without an accessible asset URL (DRM) are handed to the system player instead of the in-app player.

## License and Attribution

OldMusic is a standalone rebuild derived from the iPod app in **The OldOS Project** by [@zzanehip](https://github.com/zzanehip), licensed under [Creative Commons Attribution 4.0 International](https://creativecommons.org/licenses/by/4.0/).

```text
OldMusic is based on the iPod implementation from The OldOS Project
by @zzanehip, licensed under CC BY 4.0.
Original project: https://github.com/zzanehip/The-OldOS-Project
```

iCarousel is © Nick Lockwood, zlib license (see `Vendor/iCarousel/iCarousel.h`).

## Disclaimer

OldMusic is an independent, unofficial project. It is not affiliated with, endorsed by, or associated with Apple Inc. iPod and iOS are trademarks of Apple Inc.

---

- Built by [iamgasgass](https://github.com/iamgasgass)
