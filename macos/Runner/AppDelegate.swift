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

  // Called by macOS when the user double-clicks a .tierlist file.
  override func application(_ sender: NSApplication, openFile filename: String) -> Bool {
    guard filename.hasSuffix(".tierlist") else { return false }
    if MainFlutterWindow.dartIsReady, let channel = MainFlutterWindow.fileOpenChannel {
      channel.invokeMethod("openFile", arguments: filename)
    } else {
      pendingFilePath = filename
    }
    return true
  }
}
