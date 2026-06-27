import SwiftUI

/// A hand-drawn-feeling procedural comic panel, used when Image Playground isn't
/// available so a strip is *always* something to look at. Fully deterministic
/// from the panel's `seed`, so a given strip looks the same every time it opens.
///
/// It draws a little stick-ish character (the recurring avatar) in a tinted scene
/// with halftone shading, a sun/cloud or starburst prop, and a horizon — enough
/// comic personality to demo the whole app with no model on device.
struct PlaceholderPanel: View {
    let seed: Int
    let tint: Color

    var body: some View {
        Canvas { ctx, size in
            var rng = SeededGenerator(seed: UInt64(truncatingIfNeeded: seed) ^ 0x9E3779B9)
            let w = size.width, h = size.height

            // Sky / ground split
            let horizon = h * (0.62 + rng.unit() * 0.12)
            ctx.fill(Path(CGRect(x: 0, y: 0, width: w, height: horizon)),
                     with: .color(tint))
            ctx.fill(Path(CGRect(x: 0, y: horizon, width: w, height: h - horizon)),
                     with: .color(tint.opacity(0.55)))

            // Halftone shading in the sky
            drawHalftone(ctx: ctx, rect: CGRect(x: 0, y: 0, width: w, height: horizon),
                         spacing: 14, radius: 1.8, color: Theme.ink.opacity(0.10))

            // A prop in the upper area: sun or starburst, chosen by seed
            let propX = w * (0.18 + rng.unit() * 0.5)
            let propY = horizon * (0.25 + rng.unit() * 0.3)
            if rng.unit() < 0.5 {
                drawSun(ctx: ctx, center: CGPoint(x: propX, y: propY),
                        radius: min(w, h) * 0.09)
            } else {
                drawBurst(ctx: ctx, center: CGPoint(x: propX, y: propY),
                          radius: min(w, h) * 0.11, points: 9)
            }

            // The recurring character, planted on the horizon
            let charX = w * (0.42 + rng.unit() * 0.16)
            drawCharacter(ctx: ctx,
                          base: CGPoint(x: charX, y: horizon),
                          scale: min(w, h) * 0.34,
                          rng: &rng)

            // Ground line
            var ground = Path()
            ground.move(to: CGPoint(x: 0, y: horizon))
            ground.addLine(to: CGPoint(x: w, y: horizon))
            ctx.stroke(ground, with: .color(Theme.ink), lineWidth: 3)
        }
        .background(tint)
        .drawingGroup()
    }

    // MARK: Drawing helpers

    private func drawHalftone(ctx: GraphicsContext, rect: CGRect,
                              spacing: CGFloat, radius: CGFloat, color: Color) {
        var y = rect.minY + spacing
        var row = 0
        while y < rect.maxY {
            let off: CGFloat = (row % 2 == 0) ? 0 : spacing / 2
            var x = rect.minX + off
            while x < rect.maxX {
                let dot = Path(ellipseIn: CGRect(x: x - radius, y: y - radius,
                                                 width: radius * 2, height: radius * 2))
                ctx.fill(dot, with: .color(color))
                x += spacing
            }
            y += spacing
            row += 1
        }
    }

    private func drawSun(ctx: GraphicsContext, center: CGPoint, radius: CGFloat) {
        let disc = Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius,
                                          width: radius * 2, height: radius * 2))
        ctx.fill(disc, with: .color(Theme.popYellow))
        ctx.stroke(disc, with: .color(Theme.ink), lineWidth: 3)
        for i in 0..<8 {
            let a = CGFloat(i) * .pi / 4
            var ray = Path()
            ray.move(to: CGPoint(x: center.x + cos(a) * radius * 1.25,
                                 y: center.y + sin(a) * radius * 1.25))
            ray.addLine(to: CGPoint(x: center.x + cos(a) * radius * 1.7,
                                    y: center.y + sin(a) * radius * 1.7))
            ctx.stroke(ray, with: .color(Theme.ink), lineWidth: 3)
        }
    }

    private func drawBurst(ctx: GraphicsContext, center: CGPoint, radius: CGFloat, points: Int) {
        var path = Path()
        for k in 0..<(points * 2) {
            let ang = CGFloat(k) * .pi / CGFloat(points) - .pi / 2
            let r = (k % 2 == 0) ? radius : radius * 0.5
            let p = CGPoint(x: center.x + cos(ang) * r, y: center.y + sin(ang) * r)
            if k == 0 { path.move(to: p) } else { path.addLine(to: p) }
        }
        path.closeSubpath()
        ctx.fill(path, with: .color(Theme.pop))
        ctx.stroke(path, with: .color(Theme.ink), lineWidth: 3)
    }

    private func drawCharacter(ctx: GraphicsContext, base: CGPoint,
                               scale: CGFloat, rng: inout SeededGenerator) {
        let headR = scale * 0.22
        let bodyTop = base.y - scale * 0.55
        let headC = CGPoint(x: base.x, y: bodyTop - headR)

        // Body (striped sweater — the avatar's defining trait)
        let bodyRect = CGRect(x: base.x - scale * 0.20, y: bodyTop,
                              width: scale * 0.40, height: scale * 0.42)
        let body = Path(roundedRect: bodyRect, cornerRadius: scale * 0.10)
        ctx.fill(body, with: .color(Theme.pop))
        // stripes — drawn into a clipped copy so the main context stays unclipped
        var striped = ctx
        striped.clip(to: body)
        var sy = bodyRect.minY + scale * 0.06
        while sy < bodyRect.maxY {
            var stripe = Path()
            stripe.move(to: CGPoint(x: bodyRect.minX, y: sy))
            stripe.addLine(to: CGPoint(x: bodyRect.maxX, y: sy))
            striped.stroke(stripe, with: .color(Theme.cream), lineWidth: scale * 0.05)
            sy += scale * 0.12
        }
        ctx.stroke(body, with: .color(Theme.ink), lineWidth: 3)

        // Legs
        for dx in [-scale * 0.08, scale * 0.08] {
            var leg = Path()
            leg.move(to: CGPoint(x: base.x + dx, y: bodyRect.maxY))
            leg.addLine(to: CGPoint(x: base.x + dx, y: base.y))
            ctx.stroke(leg, with: .color(Theme.ink), lineWidth: 4)
        }

        // Head
        let head = Path(ellipseIn: CGRect(x: headC.x - headR, y: headC.y - headR,
                                          width: headR * 2, height: headR * 2))
        ctx.fill(head, with: .color(Color(red: 1.0, green: 0.88, blue: 0.74)))
        ctx.stroke(head, with: .color(Theme.ink), lineWidth: 3)

        // Big curious eyes
        let eyeR = headR * 0.26
        for dx in [-headR * 0.38, headR * 0.38] {
            let eye = Path(ellipseIn: CGRect(x: headC.x + dx - eyeR, y: headC.y - eyeR * 0.6,
                                             width: eyeR * 2, height: eyeR * 2))
            ctx.fill(eye, with: .color(.white))
            ctx.stroke(eye, with: .color(Theme.ink), lineWidth: 2)
            let pupil = Path(ellipseIn: CGRect(x: headC.x + dx - eyeR * 0.4,
                                               y: headC.y - eyeR * 0.6 + eyeR * 0.45,
                                               width: eyeR * 0.8, height: eyeR * 0.8))
            ctx.fill(pupil, with: .color(Theme.ink))
        }

        // Smile
        var smile = Path()
        let sm = CGPoint(x: headC.x, y: headC.y + headR * 0.45)
        smile.move(to: CGPoint(x: sm.x - headR * 0.35, y: sm.y))
        smile.addQuadCurve(to: CGPoint(x: sm.x + headR * 0.35, y: sm.y),
                           control: CGPoint(x: sm.x, y: sm.y + headR * 0.4))
        ctx.stroke(smile, with: .color(Theme.ink), lineWidth: 2.5)
    }
}

/// A tiny deterministic PRNG (SplitMix64) so placeholder art is stable per seed.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { self.state = seed == 0 ? 0xDEADBEEF : seed }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }

    /// A double in [0, 1).
    mutating func unit() -> CGFloat {
        CGFloat(next() >> 11) * (1.0 / 9007199254740992.0)
    }
}
