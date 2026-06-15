import SwiftUI

// All icons are custom Shapes — NO SF Symbols, NO emoji.

// MARK: - Plane silhouette (top-down)
struct PlaneShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        let cx = rect.minX + w * 0.5
        // nose at top, tail at bottom
        p.move(to: CGPoint(x: cx, y: rect.minY + h * 0.02))
        p.addQuadCurve(to: CGPoint(x: cx + w * 0.10, y: rect.minY + h * 0.34),
                       control: CGPoint(x: cx + w * 0.10, y: rect.minY + h * 0.12))
        // right wing
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + h * 0.56))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + h * 0.66))
        p.addLine(to: CGPoint(x: cx + w * 0.09, y: rect.minY + h * 0.56))
        // body to tail
        p.addLine(to: CGPoint(x: cx + w * 0.08, y: rect.minY + h * 0.82))
        // right tail fin
        p.addLine(to: CGPoint(x: cx + w * 0.22, y: rect.minY + h * 0.95))
        p.addLine(to: CGPoint(x: cx + w * 0.22, y: rect.maxY))
        p.addLine(to: CGPoint(x: cx, y: rect.minY + h * 0.92))
        // mirror left
        p.addLine(to: CGPoint(x: cx - w * 0.22, y: rect.maxY))
        p.addLine(to: CGPoint(x: cx - w * 0.22, y: rect.minY + h * 0.95))
        p.addLine(to: CGPoint(x: cx - w * 0.08, y: rect.minY + h * 0.82))
        p.addLine(to: CGPoint(x: cx - w * 0.09, y: rect.minY + h * 0.56))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY + h * 0.66))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY + h * 0.56))
        p.addLine(to: CGPoint(x: cx - w * 0.10, y: rect.minY + h * 0.34))
        p.addQuadCurve(to: CGPoint(x: cx, y: rect.minY + h * 0.02),
                       control: CGPoint(x: cx - w * 0.10, y: rect.minY + h * 0.12))
        p.closeSubpath()
        return p
    }
}

// MARK: - Runway
struct RunwayShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        // trapezoid runway in perspective
        p.move(to: CGPoint(x: rect.minX + w * 0.38, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.minX + w * 0.62, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        // center dashes
        for i in 0..<4 {
            let t0 = CGFloat(i) / 4.0
            let t1 = t0 + 0.12
            let y0 = rect.minY + h * t0
            let y1 = rect.minY + h * t1
            let hw0 = w * (0.012 + t0 * 0.02)
            let hw1 = w * (0.012 + t1 * 0.02)
            p.move(to: CGPoint(x: rect.midX - hw0, y: y0))
            p.addLine(to: CGPoint(x: rect.midX + hw0, y: y0))
            p.addLine(to: CGPoint(x: rect.midX + hw1, y: y1))
            p.addLine(to: CGPoint(x: rect.midX - hw1, y: y1))
            p.closeSubpath()
        }
        return p
    }
}

// MARK: - Gate / Terminal
struct GateShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        // building
        p.addRect(CGRect(x: rect.minX, y: rect.minY + h * 0.45, width: w, height: h * 0.55))
        // roof arc
        p.move(to: CGPoint(x: rect.minX, y: rect.minY + h * 0.45))
        p.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY + h * 0.45),
                       control: CGPoint(x: rect.midX, y: rect.minY))
        // jet bridge
        p.addRect(CGRect(x: rect.minX + w * 0.78, y: rect.minY + h * 0.6, width: w * 0.22, height: h * 0.14))
        return p
    }
}

// MARK: - Fuel drop
struct FuelDropShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        let cx = rect.midX
        p.move(to: CGPoint(x: cx, y: rect.minY))
        p.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY + h * 0.62),
                       control: CGPoint(x: rect.maxX, y: rect.minY + h * 0.30))
        p.addArc(center: CGPoint(x: cx, y: rect.minY + h * 0.62),
                 radius: w * 0.5, startAngle: .degrees(0), endAngle: .degrees(180), clockwise: false)
        p.addQuadCurve(to: CGPoint(x: cx, y: rect.minY),
                       control: CGPoint(x: rect.minX, y: rect.minY + h * 0.30))
        p.closeSubpath()
        return p
    }
}

// MARK: - Control tower
struct TowerShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        let cx = rect.midX
        // base
        p.addRect(CGRect(x: cx - w * 0.10, y: rect.minY + h * 0.30, width: w * 0.20, height: h * 0.70))
        // cabin (trapezoid)
        p.move(to: CGPoint(x: cx - w * 0.24, y: rect.minY + h * 0.30))
        p.addLine(to: CGPoint(x: cx + w * 0.24, y: rect.minY + h * 0.30))
        p.addLine(to: CGPoint(x: cx + w * 0.18, y: rect.minY + h * 0.12))
        p.addLine(to: CGPoint(x: cx - w * 0.18, y: rect.minY + h * 0.12))
        p.closeSubpath()
        // antenna
        p.addRect(CGRect(x: cx - w * 0.015, y: rect.minY, width: w * 0.03, height: h * 0.12))
        return p
    }
}

// MARK: - Gauge
struct GaugeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let r = min(rect.width, rect.height) * 0.5
        let c = CGPoint(x: rect.midX, y: rect.midY + r * 0.25)
        p.addArc(center: c, radius: r * 0.9, startAngle: .degrees(150), endAngle: .degrees(30), clockwise: false)
        // needle
        let ang = Angle.degrees(150 + 0.62 * 240).radians
        p.move(to: c)
        p.addLine(to: CGPoint(x: c.x + cos(ang) * r * 0.8, y: c.y + sin(ang) * r * 0.8))
        return p
    }
}

// MARK: - Simple line-style tab/util icons
struct GridIcon: Shape {  // facilities
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height, g: CGFloat = w * 0.12
        let cw = (w - g) / 2, ch = (h - g) / 2
        for ix in 0..<2 { for iy in 0..<2 {
            p.addRoundedRect(in: CGRect(x: rect.minX + CGFloat(ix)*(cw+g),
                                        y: rect.minY + CGFloat(iy)*(ch+g),
                                        width: cw, height: ch),
                             cornerSize: CGSize(width: w*0.06, height: w*0.06))
        }}
        return p
    }
}

struct RouteIcon: Shape {  // routes (nodes + line)
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let a = CGPoint(x: rect.minX + rect.width*0.15, y: rect.maxY - rect.height*0.15)
        let b = CGPoint(x: rect.maxX - rect.width*0.15, y: rect.minY + rect.height*0.15)
        p.move(to: a); p.addLine(to: b)
        p.addEllipse(in: CGRect(x: a.x - 4, y: a.y - 4, width: 8, height: 8))
        p.addEllipse(in: CGRect(x: b.x - 4, y: b.y - 4, width: 8, height: 8))
        return p
    }
}

struct CoinIcon: Shape {  // finance
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let r = min(rect.width, rect.height) * 0.46
        p.addEllipse(in: CGRect(x: rect.midX - r, y: rect.midY - r, width: r*2, height: r*2))
        p.move(to: CGPoint(x: rect.midX, y: rect.midY - r*0.55))
        p.addLine(to: CGPoint(x: rect.midX, y: rect.midY + r*0.55))
        return p
    }
}

struct PeopleIcon: Shape {  // staff
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        let r = w * 0.16
        p.addEllipse(in: CGRect(x: rect.midX - r, y: rect.minY + h*0.06, width: r*2, height: r*2))
        p.move(to: CGPoint(x: rect.midX - w*0.26, y: rect.maxY))
        p.addQuadCurve(to: CGPoint(x: rect.midX + w*0.26, y: rect.maxY),
                       control: CGPoint(x: rect.midX, y: rect.minY + h*0.36))
        return p
    }
}

struct FlaskIcon: Shape {  // research
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        p.move(to: CGPoint(x: rect.midX - w*0.12, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.midX - w*0.12, y: rect.minY + h*0.34))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.midX + w*0.12, y: rect.minY + h*0.34))
        p.addLine(to: CGPoint(x: rect.midX + w*0.12, y: rect.minY))
        p.move(to: CGPoint(x: rect.midX - w*0.20, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.midX + w*0.20, y: rect.minY))
        return p
    }
}

struct BellIcon: Shape {  // events / news
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        p.move(to: CGPoint(x: rect.minX + w*0.18, y: rect.minY + h*0.72))
        p.addCurve(to: CGPoint(x: rect.maxX - w*0.18, y: rect.minY + h*0.72),
                   control1: CGPoint(x: rect.minX + w*0.18, y: rect.minY + h*0.28),
                   control2: CGPoint(x: rect.maxX - w*0.18, y: rect.minY + h*0.28))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + h*0.82))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY + h*0.82))
        p.closeSubpath()
        p.addEllipse(in: CGRect(x: rect.midX - w*0.06, y: rect.maxY - h*0.14, width: w*0.12, height: h*0.14))
        return p
    }
}

struct MenuDotsIcon: Shape {  // more
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let r = rect.width * 0.10
        for i in 0..<3 {
            let x = rect.minX + rect.width * (0.22 + CGFloat(i) * 0.28)
            p.addEllipse(in: CGRect(x: x - r, y: rect.midY - r, width: r*2, height: r*2))
        }
        return p
    }
}

struct TrophyIcon: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        p.addRoundedRect(in: CGRect(x: rect.minX + w*0.22, y: rect.minY, width: w*0.56, height: h*0.42),
                         cornerSize: CGSize(width: w*0.1, height: w*0.1))
        p.move(to: CGPoint(x: rect.minX + w*0.22, y: rect.minY + h*0.06))
        p.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.minY + h*0.30),
                       control: CGPoint(x: rect.minX, y: rect.minY + h*0.06))
        p.move(to: CGPoint(x: rect.maxX - w*0.22, y: rect.minY + h*0.06))
        p.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY + h*0.30),
                       control: CGPoint(x: rect.maxX, y: rect.minY + h*0.06))
        p.addRect(CGRect(x: rect.midX - w*0.05, y: rect.minY + h*0.42, width: w*0.10, height: h*0.30))
        p.addRect(CGRect(x: rect.midX - w*0.22, y: rect.maxY - h*0.16, width: w*0.44, height: h*0.16))
        return p
    }
}

struct ChartIcon: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        for i in 0..<3 {
            let bh = h * [0.4, 0.7, 1.0][i]
            let x = rect.minX + CGFloat(i) * w * 0.36
            p.addRect(CGRect(x: x, y: rect.maxY - bh, width: w*0.24, height: bh))
        }
        return p
    }
}

struct CheckIcon: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX + rect.width*0.18, y: rect.minY + rect.height*0.52))
        p.addLine(to: CGPoint(x: rect.minX + rect.width*0.42, y: rect.maxY - rect.height*0.18))
        p.addLine(to: CGPoint(x: rect.maxX - rect.width*0.14, y: rect.minY + rect.height*0.18))
        return p
    }
}

struct ChevronIcon: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX + rect.width*0.35, y: rect.minY + rect.height*0.2))
        p.addLine(to: CGPoint(x: rect.maxX - rect.width*0.35, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.minX + rect.width*0.35, y: rect.maxY - rect.height*0.2))
        return p
    }
}

// MARK: - Icon rendering helpers
struct FilledIcon<S: Shape>: View {
    let shape: S
    var color: Color
    var size: CGFloat
    var body: some View {
        shape.fill(color).frame(width: size, height: size)
    }
}

struct StrokedIcon<S: Shape>: View {
    let shape: S
    var color: Color
    var size: CGFloat
    var line: CGFloat = 2
    var body: some View {
        shape.stroke(color, style: StrokeStyle(lineWidth: line, lineCap: .round, lineJoin: .round))
            .frame(width: size, height: size)
    }
}
