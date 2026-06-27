import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    let registrar = flutterViewController.registrar(forPlugin: "TierlistClipboardPlugin")
    let channel = FlutterMethodChannel(
      name: "tierlist/clipboard",
      binaryMessenger: registrar.messenger
    )
    channel.setMethodCallHandler { call, result in
      guard call.method == "getImage" else {
        result(FlutterMethodNotImplemented)
        return
      }
      let pb = NSPasteboard.general
      // Chrome "Copy Image" writes raw public.png bytes — check this first
      if let pngData = pb.data(forType: .png) {
        result(FlutterStandardTypedData(bytes: pngData))
        return
      }
      // TIFF (macOS screenshots, Finder) — convert to PNG
      if let tiffData = pb.data(forType: .tiff),
         let rep = NSBitmapImageRep(data: tiffData),
         let pngData = rep.representation(using: .png, properties: [:]) {
        result(FlutterStandardTypedData(bytes: pngData))
        return
      }
      // Generic NSImage fallback
      if let image = pb.readObjects(forClasses: [NSImage.self], options: nil)?.first as? NSImage,
         let tiff = image.tiffRepresentation,
         let rep = NSBitmapImageRep(data: tiff),
         let pngData = rep.representation(using: .png, properties: [:]) {
        result(FlutterStandardTypedData(bytes: pngData))
        return
      }
      result(nil)
    }

    super.awakeFromNib()
  }
}
