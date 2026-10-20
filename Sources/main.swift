import SwiftUI
import UIKit
import Foundation

struct Metric: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    let symbol: String
}

struct ContentView: View {
    @State private var metrics: [Metric] = []
    @State private var tick = 0

    let timer = Timer.publish(every: 2.0, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("设备")) {
                    row("设备型号", UIDevice.current.model + " (" + hardware() + ")")
                    row("系统", UIDevice.current.systemName + " " + UIDevice.current.systemVersion)
                    row("屏幕", String(format: "%.0f × %.0f pt",
                        UIScreen.main.bounds.width, UIScreen.main.bounds.height))
                    row("标识符", UIDevice.current.identifierForVendor?.uuidString ?? "-")
                }
                Section(header: Text("实时")) {
                    ForEach(metrics) { m in
                        HStack {
                            Image(systemName: m.symbol)
                                .frame(width: 24)
                                .foregroundColor(.accentColor)
                            Text(m.title)
                            Spacer()
                            Text(m.value).foregroundColor(.secondary).monospacedDigit()
                        }
                    }
                }
                Section(header: Text("构建信息")) {
                    row("编译时间", "\(BuildInfo.compiledAt)")
                    row("运行环境", "swiftc on GitHub Actions")
                    row("签名状态", "未签名（由设备端侧载工具签名）")
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("PhoneFacts")
        }
        .onAppear(perform: refresh)
        .onReceive(timer) { _ in refresh() }
    }

    func row(_ t: String, _ v: String) -> some View {
        HStack {
            Text(t)
            Spacer()
            Text(v).foregroundColor(.secondary).lineLimit(1).truncationMode(.middle)
        }
    }

    func refresh() {
        UIDevice.current.isBatteryMonitoringEnabled = true
        let lvl = UIDevice.current.batteryLevel
        var batt = lvl < 0 ? "未知" : String(format: "%.0f%%", lvl * 100)
        switch UIDevice.current.batteryState {
        case .charging: batt += " ⚡︎"
        case .full: batt += " 满"
        default: break
        }

        let mem = ProcessInfo.processInfo
        let phys = Double(mem.physicalMemory) / 1_073_741_824.0

        let up = mem.systemUptime
        let h = Int(up) / 3600, m = (Int(up) % 3600) / 60

        metrics = [
            Metric(title: "电量", value: batt, symbol: "battery.100"),
            Metric(title: "物理内存", value: String(format: "%.1f GB", phys), symbol: "memorychip"),
            Metric(title: "已运行", value: "\(h)h \(m)m", symbol: "clock"),
            Metric(title: "磁盘可用", value: freeDisk(), symbol: "internaldrive"),
            Metric(title: "活跃处理器", value: "\(mem.activeProcessorCount)", symbol: "cpu"),
        ]
        tick += 1
    }

    func freeDisk() -> String {
        let u = URL(fileURLWithPath: NSHomeDirectory())
        if let v = try? u.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey]),
           let b = v.volumeAvailableCapacityForImportantUsage {
            return String(format: "%.1f GB", Double(b) / 1_073_741_824.0)
        }
        return "-"
    }

    func hardware() -> String {
        var sysinfo = utsname()
        uname(&sysinfo)
        return withUnsafeBytes(of: &sysinfo.machine) { raw -> String in
            let bytes = raw.bindMemory(to: CChar.self)
            return bytes.baseAddress.map { String(cString: $0) } ?? "?"
        }
    }
}

enum BuildInfo {
    static var compiledAt: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm"
        return f.string(from: Date())
    }
}

@main
struct PhoneFactsApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
