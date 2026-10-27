import AppKit
let size = NSSize(width:1024,height:1024)
let image = NSImage(size:size)
image.lockFocus()
NSColor(calibratedRed:0.055,green:0.12,blue:0.20,alpha:1).setFill()
NSBezierPath(rect:NSRect(origin:.zero,size:size)).fill()
let sun = NSBezierPath(ovalIn:NSRect(x:590,y:580,width:210,height:210))
NSColor(calibratedRed:1,green:0.72,blue:0.28,alpha:1).setFill();sun.fill()
let rays = NSBezierPath();rays.lineWidth=15;rays.lineCapStyle = .round
for i in 0..<8 {
 let a = Double(i)*Double.pi/4
 rays.move(to:NSPoint(x:695+cos(a)*135,y:685+sin(a)*135))
 rays.line(to:NSPoint(x:695+cos(a)*170,y:685+sin(a)*170))
}
rays.stroke()
NSColor(calibratedRed:0.23,green:0.62,blue:0.79,alpha:1).setFill()
let panel = NSBezierPath(roundedRect:NSRect(x:190,y:245,width:600,height:360),xRadius:32,yRadius:32);panel.fill()
NSColor(calibratedRed:0.73,green:0.9,blue:0.97,alpha:1).setStroke()
let grid=NSBezierPath();grid.lineWidth=9
for x in [340,490,640] {grid.move(to:NSPoint(x:x,y:245));grid.line(to:NSPoint(x:x,y:605))}
for y in [365,485] {grid.move(to:NSPoint(x:190,y:y));grid.line(to:NSPoint(x:790,y:y))}
grid.stroke()
let stand=NSBezierPath();stand.lineWidth=24;stand.lineCapStyle = .round
stand.move(to:NSPoint(x:490,y:245));stand.line(to:NSPoint(x:490,y:185));stand.move(to:NSPoint(x:370,y:185));stand.line(to:NSPoint(x:610,y:185));stand.stroke()
image.unlockFocus()
let bitmap=NSBitmapImageRep(bitmapDataPlanes:nil,pixelsWide:1024,pixelsHigh:1024,bitsPerSample:8,samplesPerPixel:3,hasAlpha:false,isPlanar:false,colorSpaceName:.deviceRGB,bytesPerRow:0,bitsPerPixel:0)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current=NSGraphicsContext(bitmapImageRep:bitmap)
image.draw(in:NSRect(origin:.zero,size:size))
NSGraphicsContext.restoreGraphicsState()
try bitmap.representation(using:.png,properties:[:])!.write(to:URL(fileURLWithPath:CommandLine.arguments[1]))
