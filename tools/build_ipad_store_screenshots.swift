#!/usr/bin/env swift

import AppKit
import Foundation

let canvasWidth = 2752
let canvasHeight = 2064

struct Slide {
    let filename: String
    let eyebrow: String
    let title: String
    let subtitle: String
    let source: String
    let privateNameY: CGFloat?
    let removeSiriOverlay: Bool
}

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data(("error: \(message)\n").utf8))
    exit(1)
}

guard CommandLine.arguments.count == 8 else {
    fail("usage: build_ipad_store_screenshots.swift BACKGROUND OUTPUT_DIR SOURCE1 SOURCE2 SOURCE3 SOURCE4 SOURCE5")
}

let backgroundPath = CommandLine.arguments[1]
let outputDirectory = CommandLine.arguments[2]
let sources = Array(CommandLine.arguments[3...7])

let slides = [
    Slide(
        filename: "01-play-save-grow.jpg",
        eyebrow: "MONEY MUNCHER · VERSION 1.3",
        title: "Play. Save. Grow. Together.",
        subtitle: "Games, quests, and family wins in one playful space.",
        source: sources[0],
        privateNameY: nil,
        removeSiriOverlay: false
    ),
    Slide(
        filename: "02-family-community.jpg",
        eyebrow: "FAMILY COMMUNITY",
        title: "One place for the whole family.",
        subtitle: "Create profiles, set goals, and celebrate progress together.",
        source: sources[1],
        privateNameY: nil,
        removeSiriOverlay: false
    ),
    Slide(
        filename: "03-family-goals.jpg",
        eyebrow: "SHARED GOALS",
        title: "Set goals kids can see.",
        subtitle: "Turn a family wish into visible, motivating progress.",
        source: sources[2],
        privateNameY: 636,
        removeSiriOverlay: false
    ),
    Slide(
        filename: "04-shared-activities.jpg",
        eyebrow: "FAMILY ACTIVITIES",
        title: "Turn teamwork into progress.",
        subtitle: "Create activities and celebrate every contribution.",
        source: sources[3],
        privateNameY: 190,
        removeSiriOverlay: true
    ),
    Slide(
        filename: "05-track-savings.jpg",
        eyebrow: "SAVINGS GOALS",
        title: "Make every dollar feel meaningful.",
        subtitle: "Record savings, spot found money, and keep momentum going.",
        source: sources[4],
        privateNameY: nil,
        removeSiriOverlay: false
    )
]

guard let background = NSImage(contentsOfFile: backgroundPath) else {
    fail("could not load background: \(backgroundPath)")
}

try FileManager.default.createDirectory(
    atPath: outputDirectory,
    withIntermediateDirectories: true
)

func bitmap(width: Int, height: Int) -> NSBitmapImageRep {
    guard let result = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: width,
        pixelsHigh: height,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 32
    ) else {
        fail("could not allocate bitmap")
    }
    result.size = NSSize(width: width, height: height)
    return result
}

func withBitmapContext(_ rep: NSBitmapImageRep, draw: () -> Void) {
    guard let graphics = NSGraphicsContext(bitmapImageRep: rep) else {
        fail("could not create graphics context")
    }
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = graphics
    graphics.imageInterpolation = .high
    draw()
    graphics.flushGraphics()
    NSGraphicsContext.restoreGraphicsState()
}

func drawAspectFill(_ image: NSImage, in destination: NSRect) {
    let sourceSize = image.size
    let scale = max(destination.width / sourceSize.width, destination.height / sourceSize.height)
    let drawSize = NSSize(width: sourceSize.width * scale, height: sourceSize.height * scale)
    let drawRect = NSRect(
        x: destination.midX - drawSize.width / 2,
        y: destination.midY - drawSize.height / 2,
        width: drawSize.width,
        height: drawSize.height
    )
    image.draw(
        in: drawRect,
        from: .zero,
        operation: .sourceOver,
        fraction: 1,
        respectFlipped: false,
        hints: [.interpolation: NSImageInterpolation.high]
    )
}

func drawText(_ text: String, in rect: NSRect, font: NSFont, color: NSColor) {
    let style = NSMutableParagraphStyle()
    style.lineBreakMode = .byTruncatingTail
    style.alignment = .left
    let attributes: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: color,
        .paragraphStyle: style,
        .kern: -0.4
    ]
    NSAttributedString(string: text, attributes: attributes).draw(in: rect)
}

func sanitizedImage(at path: String, privateNameY: CGFloat?, removeSiriOverlay: Bool) -> NSImage {
    guard let source = NSImage(contentsOfFile: path) else {
        fail("could not load screenshot: \(path)")
    }

    let rep = bitmap(width: 2266, height: 1488)
    withBitmapContext(rep) {
        source.draw(
            in: NSRect(x: 0, y: 0, width: 2266, height: 1488),
            from: .zero,
            operation: .copy,
            fraction: 1,
            respectFlipped: false,
            hints: [.interpolation: NSImageInterpolation.high]
        )

        if let y = privateNameY {
            // Replace the throwaway test profile name with a neutral store-safe label.
            NSColor.white.setFill()
            NSBezierPath(rect: NSRect(x: 730, y: 1488 - y - 54, width: 360, height: 54)).fill()
            drawText(
                "Kid profile",
                in: NSRect(x: 744, y: 1488 - y - 50, width: 320, height: 48),
                font: .systemFont(ofSize: 31, weight: .semibold),
                color: NSColor(calibratedRed: 0.18, green: 0.09, blue: 0.35, alpha: 1)
            )
        }

        if removeSiriOverlay {
            // Remove the transient Siri orb captured during the real-device test.
            NSColor(calibratedRed: 0.31, green: 0.18, blue: 0.64, alpha: 1).setFill()
            NSBezierPath(ovalIn: NSRect(x: 1930, y: 1488 - 1448, width: 315, height: 315)).fill()
        }
    }

    let image = NSImage(size: NSSize(width: 2266, height: 1488))
    image.addRepresentation(rep)
    return image
}

func render(_ slide: Slide) {
    let rep = bitmap(width: canvasWidth, height: canvasHeight)
    withBitmapContext(rep) {
        let canvas = NSRect(x: 0, y: 0, width: canvasWidth, height: canvasHeight)
        drawAspectFill(background, in: canvas)

        // A quiet dark wash improves copy contrast while preserving the generated texture.
        NSColor(calibratedWhite: 0.02, alpha: 0.20).setFill()
        NSBezierPath(rect: canvas).fill()

        let pillRect = NSRect(x: 160, y: 1958, width: 600, height: 52)
        NSColor(calibratedRed: 1.0, green: 0.76, blue: 0.27, alpha: 1).setFill()
        NSBezierPath(roundedRect: pillRect, xRadius: 26, yRadius: 26).fill()
        drawText(
            slide.eyebrow,
            in: NSRect(x: 190, y: 1962, width: 540, height: 38),
            font: .systemFont(ofSize: 27, weight: .bold),
            color: NSColor(calibratedRed: 0.08, green: 0.18, blue: 0.16, alpha: 1)
        )

        let rounded = NSFont(name: "Arial Rounded MT Bold", size: 76)
            ?? .systemFont(ofSize: 76, weight: .heavy)
        drawText(
            slide.title,
            in: NSRect(x: 160, y: 1843, width: 2430, height: 96),
            font: rounded,
            color: .white
        )
        drawText(
            slide.subtitle,
            in: NSRect(x: 164, y: 1778, width: 2420, height: 55),
            font: .systemFont(ofSize: 37, weight: .medium),
            color: NSColor(calibratedWhite: 1, alpha: 0.88)
        )

        let outerRect = NSRect(x: 145, y: 13, width: 2462, height: 1630)
        let innerRect = NSRect(x: 161, y: 29, width: 2430, height: 1598)

        NSGraphicsContext.saveGraphicsState()
        let shadow = NSShadow()
        shadow.shadowColor = NSColor(calibratedWhite: 0, alpha: 0.42)
        shadow.shadowBlurRadius = 54
        shadow.shadowOffset = NSSize(width: 0, height: -20)
        shadow.set()
        NSColor(calibratedWhite: 1, alpha: 0.96).setFill()
        NSBezierPath(roundedRect: outerRect, xRadius: 60, yRadius: 60).fill()
        NSGraphicsContext.restoreGraphicsState()

        NSGraphicsContext.saveGraphicsState()
        NSBezierPath(roundedRect: innerRect, xRadius: 48, yRadius: 48).addClip()
        let screenshot = sanitizedImage(
            at: slide.source,
            privateNameY: slide.privateNameY,
            removeSiriOverlay: slide.removeSiriOverlay
        )

        // Crop only the TestFlight/status-bar strip and tiny home-indicator edge.
        let sourceCrop = NSRect(x: 51, y: 20, width: 2164, height: 1420)
        screenshot.draw(
            in: innerRect,
            from: sourceCrop,
            operation: .copy,
            fraction: 1,
            respectFlipped: false,
            hints: [.interpolation: NSImageInterpolation.high]
        )
        NSGraphicsContext.restoreGraphicsState()
    }

    guard let jpeg = rep.representation(using: .jpeg, properties: [.compressionFactor: 0.98]) else {
        fail("could not encode \(slide.filename)")
    }
    let output = URL(fileURLWithPath: outputDirectory).appendingPathComponent(slide.filename)
    do {
        try jpeg.write(to: output, options: .atomic)
        print(output.path)
    } catch {
        fail("could not write \(output.path): \(error)")
    }
}

slides.forEach(render)
