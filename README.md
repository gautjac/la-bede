# La Bédé

**Un journal qui se dessine.** Jot one to three lines about your day; La Bédé
turns it into a **consistent-style three-panel comic strip** — a diary that
draws itself.

A native iOS (universal — iPhone + iPad) app for the Atelier, built on Apple
Intelligence: **Foundation Models** writes the strip, **Image Playground**
(`ImageCreator`) draws it, and **Genmoji** can sign it.

## How it works

1. **Write a beat.** One to three lines about something that happened.
2. **Foundation Models** (`LanguageModelSession`, on-device, guided generation
   via a `@Generable` script) expands it into **three comic panels** — a title,
   a single recurring character, one shared art style, and a caption + scene per
   panel — so the three panels read as one strip.
3. **Image Playground** (`ImageCreator.images(for:style:limit:)`) renders each
   panel, fusing the panel's scene with the shared character + style anchors so
   the protagonist stays consistent across panels. Panels stream in one at a
   time.
4. The result is laid out as a real comic page — ink title banner, bold-bordered
   panels with gutters, halftone shading, numbered tabs, caption boxes — saved
   to the **Recueil** with its date.
5. **Reread, share, export.** Each strip renders to a shareable PNG via
   `ImageRenderer` (what you see is what you share). Optionally pick a **Genmoji**
   mascot byline via `imagePlaygroundSheet`.

## Graceful when AI is unavailable

Apple Intelligence and Image Playground need an eligible device and may be
unavailable (Simulator, non-AI hardware). La Bédé checks
`SystemLanguageModel.default.availability` and `ImagePlaygroundViewController.isAvailable`,
shows a friendly banner ("La Bédé adore Apple Intelligence" + the precise
reason), and **still produces a full strip**: a deterministic local script
writer plus a hand-drawn procedural **placeholder panel** style (Canvas, seeded
PRNG) means the app is always demoable and never crashes.

## Design identity

Loud bande-dessinée energy: bold ink borders, Ben-Day halftone dots, sticker
drop-shadows, pop primaries (hot red / burst yellow / sky blue), a heavy rounded
display face for hand-lettered titles. French-first.

## Build

```sh
cd ~/Claude/apps/la-bede
xcodegen generate
xcodebuild -project LaBede.xcodeproj -scheme LaBede \
  -destination 'generic/platform=iOS Simulator' build CODE_SIGNING_ALLOWED=NO
```

Module/scheme `LaBede`, display name **La Bédé**, bundle `com.jac.LaBede`,
iOS deployment target 26.0, device family iPhone + iPad. 15 unit tests
(deterministic script writer, prompt composition, seeded RNG, model logic,
render smoke) — all green on the Simulator.

## Caveats

- **Image generation needs an Apple-Intelligence-eligible device.** On the
  Simulator (no Apple Intelligence) the app shows the graceful state and the
  hand-drawn placeholder panels — fully functional, just not the diffusion art.
- The on-device model occasionally returns fewer than three panels; the strip is
  topped up locally so it's always a full three-panel page.

© 2026 Jacques Gautreau
