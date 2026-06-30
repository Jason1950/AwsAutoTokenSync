import Cocoa

// 取得執行檔所在的 Bundle 資源路徑或是動態取得當前路徑
func getScriptDirectory() -> String {
    // 優先嘗試從 Bundle 的路徑推導
    let bundlePath = Bundle.main.bundlePath
    let appURL = URL(fileURLWithPath: bundlePath)
    
    // 如果是在開發階段直接執行，或是有其他路徑需求
    // 這裡我們預設腳本與 .app 放在同一個專案資料夾下的相對位置
    // 因此推導 .app 所在的資料夾 (例如 ~/Applications/ 或是原始目錄)
    // 為了確保腳本能被找到，我們在安裝時會將腳本一併複製到資源檔中，或是讀取家目錄配置
    
    // 假設我們在 install-native-menubar.sh 將腳本放在 App 的 Resources 目錄下：
    if let resourcesPath = Bundle.main.resourcePath {
        return resourcesPath
    }
    
    return "."
}

let scriptDir = getScriptDirectory()
let launcher = "\(scriptDir)/menubar/run-in-terminal.sh"

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem.button {
            if let image = NSImage(systemSymbolName: "cloud.fill", accessibilityDescription: "AWS") {
                let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .medium)
                button.image = image.withSymbolConfiguration(config)
                button.image?.isTemplate = true
            } else {
                button.title = "AWS"
            }
            button.toolTip = "AWS Credentials"
        }

        let menu = NSMenu()
        menu.addItem(makeItem("Demo Gen", action: #selector(runDemoGen)))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(makeItem("Quit", action: #selector(quitApp)))

        statusItem.menu = menu
    }

    func makeItem(_ title: String, action: Selector) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        return item
    }

    func runScript(_ name: String) {
        let path = "\(scriptDir)/\(name)"
        DispatchQueue.global(qos: .userInitiated).async {
            let proc = Process()
            proc.executableURL = URL(fileURLWithPath: launcher)
            proc.arguments = [path]
            do {
                try proc.run()
            } catch {
                NSLog("Failed to launch script: \(error)")
            }
        }
    }

    @objc func runDemoGen() { runScript("aws-auto-gen.sh") }
    @objc func quitApp() { NSApplication.shared.terminate(nil) }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
