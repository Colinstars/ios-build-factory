import Foundation

/// 异步地理位置探测服务
actor GeoIPService {
    static let shared = GeoIPService()

    private var cache: [String: String] = [:]

    /// 根据主机 IP 或域名异步解析所在城市与地区
    func fetchRegion(for host: String) async -> String? {
        let trimmed = host.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        // 本地/私有 IP 识别
        if trimmed == "127.0.0.1" || trimmed == "localhost" || trimmed.hasPrefix("192.168.") || trimmed.hasPrefix("10.") || trimmed.hasPrefix("172.") {
            return "Local"
        }

        if let cached = cache[trimmed] {
            return cached
        }

        // 尝试主备 GeoIP 节点
        let endpoints = [
            "https://ipwho.is/\(trimmed)",
            "http://ip-api.com/json/\(trimmed)?fields=status,city,country"
        ]

        for ep in endpoints {
            guard let url = URL(string: ep) else { continue }
            do {
                var request = URLRequest(url: url)
                request.timeoutInterval = 4.0
                request.setValue("ServerLens/1.0", forHTTPHeaderField: "User-Agent")

                let (data, response) = try await URLSession.shared.data(for: request)
                guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { continue }

                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    // ipwho.is 格式
                    if let city = json["city"] as? String, !city.isEmpty {
                        let region = city
                        self.cache[trimmed] = region
                        return region
                    }
                    // ip-api 格式
                    if let status = json["status"] as? String, status == "success",
                       let city = json["city"] as? String, !city.isEmpty {
                        let region = city
                        self.cache[trimmed] = region
                        return region
                    }
                }
            } catch {
                continue
            }
        }

        return nil
    }
}
