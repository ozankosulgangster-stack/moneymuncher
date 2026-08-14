#!/usr/bin/env swift

import AppKit
import Foundation

let canvasWidth = 1320
let canvasHeight = 2868
let sourceWidth = 1170
let sourceHeight = 2532

struct Slide {
    let filename: String
    let eyebrow: String
    let title: String
    let subtitle: String
    let source: String
    let removeTestFlight: Bool
    let sanitizeProfileNames: Bool
}

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data(("error: \(message)\n").utf8))
    exit(1)
}

guard CommandLine.arguments.count == 6 else {
    fail("usage: build_iphone_store_screenshots.swift BACKGROUND OUTPUT_DIR HOME COMMUNITY GOAL")
}

let backgroundPath = CommandLine.arguments[1]
let outputDirectory = CommandLine.arguments[2]

let slides = [
    Slide(
        filename: "01-play-save-grow.jpg",
        eyebrow: "MONEY MUNCHER · VERSION 1.3",
        title: "Play. Save.\nGrow together.",
        subtitle: "Games, quests, and family wins in one playful place.",
        source: CommandLine.arguments[3],
        removeTestFlight: true,
        sanitizeProfileNames: false
    ),
    Slide(
        filename: "02-family-community.jpg",
        eyebrow: "FAMILY COMMUNITY",
        title: "Build money habits\ntogether.",
        subtitle: "Profiles and shared goals make progress visible.",
        source: CommandLine.arguments[4],
        removeTestFlight: false,
        sanitizeProfileNames: false
    ),
    Slide(
        filename: "03-savings-goal.jpg",
        eyebrow: "SAVINGS GOALS",
        title: "Make every dollar\nfeel meaningful.",
        subtitle: "Track progress without linking a bank account.",
        source: CommandLine.arguments[5],
        removeTestFlight: false,
        sanitizeProfileNames: false
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

func topRect(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat, canvas: CGFloat = CGFloat(canvasHeight)) -> NSRect {
    NSRect(x: x, y: canvas - y - height, width: width, height: height)
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

func drawText(
    _ text: String,
    in rect: NSRect,
    font: NSFont,
    color: NSColor,
    lineSpacing: CGFloat = 0
) {
    let style = NSMutableParagraphStyle()
    style.lineBreakMode = .byWordWrapping
    style.alignment = .left
    style.lineSpacing = lineSpacing
    let attributes: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: color,
        .paragraphStyle: style,
        .kern: -0.35
    ]
    NSAttributedString(string: text, attributes: attributes).draw(in: rect)
}

func normalizedScreenshot(_ slide: Slide) -> NSImage {
    guard let source = NSImage(contentsOfFile: slide.source) else {
        fail("could not load screenshot: \(slide.source)")
    }

    let rep = bitmap(width: sourceWidth, height: sourceHeight)
    withBitmapContext(rep) {
        NSColor.black.setFill()
        NSBezierPath(rect: NSRect(x: 0, y: 0, width: sourceWidth, height: sourceHeight)).fill()
        source.draw(
            in: NSRect(x: 0, y: 0, width: sourceWidth, height: sourceHeight),
            from: .zero,
            operation: .sourceOver,
            fraction: 1,
            respectFlipped: false,
            hints: [.interpolation: NSImageInterpolation.high]
        )

        if slide.removeTestFlight {
            NSColor(calibratedRed: 0.0, green: 0.055, blue: 0.046, alpha: 1).setFill()
            NSBezierPath(rect: topRect(x: 0, y: 66, width: 270, height: 82, canvas: CGFloat(sourceHeight))).fill()
        }

        if slide.sanitizeProfileNames {
            NSGraphicsContext.current?.flushGraphics()
            let firstCard = rep.colorAt(x: 700, y: sourceHeight - 1365)
                ?? NSColor(srgbRed: 0.16, green: 0.16, blue: 0.17, alpha: 1)
            let secondCard = rep.colorAt(x: 700, y: sourceHeight - 1633)
                ?? firstCard
            let textColor = NSColor(calibratedRed: 0.95, green: 0.92, blue: 1.0, alpha: 1)
            let nameFont = NSFont.systemFont(ofSize: 48, weight: .medium)

            firstCard.setFill()
            NSBezierPath(rect: topRect(x: 275, y: 1330, width: 350, height: 68, canvas: CGFloat(sourceHeight))).fill()
            drawText("Alex", in: topRect(x: 288, y: 1333, width: 300, height: 62, canvas: CGFloat(sourceHeight)), font: nameFont, color: textColor)

            secondCard.setFill()
            NSBezierPath(rect: topRect(x: 275, y: 1598, width: 350, height: 68, canvas: CGFloat(sourceHeight))).fill()
            drawText("Sam", in: topRect(x: 288, y: 1601, width: 300, height: 62, canvas: CGFloat(sourceHeight)), font: nameFont, color: textColor)
        }
    }

    let image = NSImage(size: NSSize(width: sourceWidth, height: sourceHeight))
    image.addRepresentation(rep)
    return image
}

func render(_ slide: Slide) {
    let rep = bitmap(width: canvasWidth, height: canvasHeight)
    withBitmapContext(rep) {
        let canvas = NSRect(x: 0, y: 0, width: canvasWidth, height: canvasHeight)
        drawAspectFill(background, in: canvas)

        NSColor(calibratedWhite: 0.02, alpha: 0.23).setFill()
        NSBezierPath(rect: canvas).fill()

        let pillRect = topRect(x: 70, y: 48, width: 620, height: 54)
        NSColor(calibratedRed: 1.0, green: 0.76, blue: 0.27, alpha: 1).setFill()
        NSBezierPath(roundedRect: pillRect, xRadius: 27, yRadius: 27).fill()
        drawText(
            slide.eyebrow,
            in: topRect(x: 98, y: 57, width: 565, height: 40),
            font: .systemFont(ofSize: 26, weight: .bold),
            color: NSColor(calibratedRed: 0.08, green: 0.18, blue: 0.16, alpha: 1)
        )

        let rounded = NSFont(name: "Arial Rounded MT Bold", size: 69)
            ?? .systemFont(ofSize: 69, weight: .heavy)
        drawText(
            slide.title,
            in: topRect(x: 70, y: 118, width: 1180, height: 174),
            font: rounded,
            color: .white,
            lineSpacing: -5
        )
        drawText(
            slide.subtitle,
            in: topRect(x: 74, y: 305, width: 1170, height: 70),
            font: .systemFont(ofSize: 31, weight: .medium),
            color: NSColor(calibratedWhite: 1, alpha: 0.90)
        )

        let outerRect = topRect(x: 82, y: 412, width: 1156, height: 2450)
        let innerRect = topRect(x: 100, y: 430, width: 1120, height: 2424)

        NSGraphicsContext.saveGraphicsState()
        let shadow = NSShadow()
        shadow.shadowColor = NSColor(calibratedWhite: 0, alpha: 0.48)
        shadow.shadowBlurRadius = 46
        shadow.shadowOffset = NSSize(width: 0, height: -18)
        shadow.set()
        NSColor(calibratedWhite: 1, alpha: 0.97).setFill()
        NSBezierPath(roundedRect: outerRect, xRadius: 72, yRadius: 72).fill()
        NSGraphicsContext.restoreGraphicsState()

        NSGraphicsContext.saveGraphicsState()
        NSBezierPath(roundedRect: innerRect, xRadius: 55, yRadius: 55).addClip()
        let screenshot = normalizedScreenshot(slide)
        screenshot.draw(
            in: innerRect,
            from: NSRect(x: 0, y: 0, width: sourceWidth, height: sourceHeight),
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
