# La Bédé

**Un journal qui se dessine.** Jot one to three lines about your day; La Bédé
turns it into a **consistent-style three-panel comic strip** — a diary that
draws itself.

A native iOS (universal — iPhone + iPad) app for the Atelier, built on Apple
Intelligence: **Foundation Models** writes the strip, **Image Playground**
(`ImageCreator`) draws it, and **Genmoji** can sign it.

## How it works

1. **Pick a style.** Choose the day's look from a rail of art-style presets (see
   below). Your choice is remembered between launches.
2. **Write a beat.** One to three lines about something that happened.
3. **Foundation Models** (`LanguageModelSession`, on-device, guided generation
   via a `@Generable` script) expands it into **three comic panels** — a title,
   a single recurring character, and a caption + scene per panel — so the three
   panels read as one strip. (The *style* is no longer the model's job; the
   preset owns it, which also makes the three-panel output more reliable.)
4. **Image Playground** (`ImageCreator`) renders each panel. Panels stream in one
   at a time.
5. The result is laid out as a real comic page — ink title banner, bold-bordered
   panels with gutters, halftone shading, numbered tabs, caption boxes — saved
   to the **Recueil** with its date and a style credit.
6. **Reread, share, export.** Each strip renders to a shareable PNG via
   `ImageRenderer` (what you see is what you share). Optionally pick a **Genmoji**
   mascot byline via `imagePlaygroundSheet`.

## Style presets — and how the panels follow the sentence

La Bédé ships eight art-style presets. Three are backed by Apple's built-in
Image Playground styles and always render real art when Apple Intelligence is on:
**Bande dessinée** (`.illustration`), **Dessin animé** (`.animation`), and
**Croquis** (`.sketch`). Five richer looks — **Aquarelle**, **Peinture à
l'huile**, **Pixel art**, **Noir**, **Estampe rétro** — route through the
free-form provider style (`.externalProvider` on iOS 26, `.any` on iOS 27) and
appear in the picker only when a provider is connected. Each preset also carries
its own placeholder palette, so even the no-AI fallback art reflects the choice.

Two deliberate choices make panels actually depict the scene you wrote:

- **Style lives in the `style:` parameter, not the prompt.** For built-in styles
  the renderer passes *no* style words as concepts — only the scene and the
  recurring character — so nothing competes with the sentence.
- **Concepts are clean and discrete.** Scene first, character second, with no
  meta-labels (`Art style:`, `A single comic panel`) that an image generator
  would otherwise try to draw literally.

On iOS 26.4+ the renderer uses `ImageCreator.images(for:style:options:limit:)`
with `ImagePlaygroundOptions`: **personalization disabled** (so it never grafts
your own face onto the avatar) and, on iOS 27+, a crisp **1024²
`sizeSpecification`** for sharper panels.

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
iOS deployment target 26.0, device family iPhone + iPad. 28 unit tests
(deterministic script writer, style-preset catalog, clean concept composition,
device-style resolution + fallback, seeded RNG, model logic, render smoke) — all
green on the Simulator, and the app builds clean for a generic device too.

## Caveats

- **Image generation needs an Apple-Intelligence-eligible device.** On the
  Simulator (no Apple Intelligence) the app shows the graceful state and the
  hand-drawn placeholder panels — fully functional, just not the diffusion art.
- The on-device model occasionally returns fewer than three panels; the strip is
  topped up locally so it's always a full three-panel page.

© 2026 Jacques Gautreau
