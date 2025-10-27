//
//  IRNetworkSpeedMonitor.swift
//  IRPlayerUIShell
//
//  Created by irons on 2025/1/12.
//

import Foundation
import UIKit

// MARK: - Notification Keys
extension Notification.Name {
    static let IRDownloadNetworkSpeedNotification = Notification.Name("IRDownloadNetworkSpeedNotificationKey")
    static let IRUploadNetworkSpeedNotification = Notification.Name("IRUploadNetworkSpeedNotificationKey")
    static let IRNetworkSpeedNotification = Notification.Name("IRNetworkSpeedNotificationKey")
}

// MARK: - Network Speed Monitor
class IRNetworkSpeedMonitor {

    // MARK: - Properties
    private(set) var downloadNetworkSpeed: String = ""
    private(set) var uploadNetworkSpeed: String = ""

    private var timer: Timer?
    private var iBytes: UInt64 = 0
    private var oBytes: UInt64 = 0

    // MARK: - Public Methods

    /// Start monitoring network speed.
    func startNetworkSpeedMonitor() {
        guard timer == nil else { return }
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(checkNetworkSpeed), userInfo: nil, repeats: true)
        RunLoop.current.add(timer!, forMode: .common)
        timer?.fire()
    }

    /// Stop monitoring network speed.
    func stopNetworkSpeedMonitor() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Private Methods

    @objc private func checkNetworkSpeed() {
        var iBytes: UInt64 = 0
        var oBytes: UInt64 = 0

        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return }

        var ptr = ifaddr
        while let interface = ptr?.pointee {
            if interface.ifa_addr.pointee.sa_family == UInt8(AF_LINK),
               let data = unsafeBitCast(interface.ifa_data, to: UnsafePointer<if_data>?.self) {

                if let name = String(validatingUTF8: interface.ifa_name),
                   !name.hasPrefix("lo") { // Exclude loopback
                    iBytes += UInt64(data.pointee.ifi_ibytes)
                    oBytes += UInt64(data.pointee.ifi_obytes)
                }
            }
            ptr = interface.ifa_next
        }

        freeifaddrs(ifaddr)

        if self.iBytes != 0 {
            let downloadSpeed = (iBytes >= self.iBytes) ? (iBytes - self.iBytes) : 0
            downloadNetworkSpeed = "\(formatBytes(bytes: downloadSpeed))/s"
            NotificationCenter.default.post(name: .IRDownloadNetworkSpeedNotification, object: nil, userInfo: ["speed": downloadNetworkSpeed])
            print("Download Network Speed: \(downloadNetworkSpeed)")
        }

        if self.oBytes != 0 {
            let uploadSpeed = (oBytes >= self.oBytes) ? (oBytes - self.oBytes) : 0
            uploadNetworkSpeed = "\(formatBytes(bytes: uploadSpeed))/s"
            NotificationCenter.default.post(name: .IRUploadNetworkSpeedNotification, object: nil, userInfo: ["speed": uploadNetworkSpeed])
            print("Upload Network Speed: \(uploadNetworkSpeed)")
        }

        self.iBytes = iBytes
        self.oBytes = oBytes
    }

    private func formatBytes(bytes: UInt64) -> String {
        if bytes < 1024 {
            return "\(bytes)B"
        } else if bytes < 1024 * 1024 {
            return String(format: "%.0fKB", Double(bytes) / 1024)
        } else if bytes < 1024 * 1024 * 1024 {
            return String(format: "%.1fMB", Double(bytes) / (1024 * 1024))
        } else {
            return String(format: "%.1fGB", Double(bytes) / (1024 * 1024 * 1024))
        }
    }
}
