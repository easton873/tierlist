import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {

  // Holds a path delivered before the Flutter channel was ready.
  var pendingFilePath: String?

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  private func deliver(_ filename: String) {
    if MainFlutterWindow.dartIsReady, let channel = MainFlutterWindow.fileOpenChannel {
      channel.invokeMethod("openFile", arguments: filename)
    } else {
      pendingFilePath = filename
    }
  }

  // Newer macOS/Flutter route Finder opens here; FlutterAppDelegate implements it,
  // so macOS never falls back to openFile unless we override this too.
  override func application(_ application: NSApplication, open urls: [URL]) {
    for url in urls where url.isFileURL && url.pathExtension == "tierlist" {
      deliver(url.path)
    }
  }

  // Legacy path, kept as a fallback.
  override func application(_ sender: NSApplication, openFile filename: String) -> Bool {
    guard filename.hasSuffix(".tierlist") else { return false }
    deliver(filename)
    return true
  }
}
