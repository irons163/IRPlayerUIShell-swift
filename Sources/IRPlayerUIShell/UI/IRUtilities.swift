//
//  IRUtilities.swift
//  IRPlayerUIShell
//
//  Created by irons on 2025/1/12.
//

import UIKit

// MARK: - Utilities Class
public class IRUtilities {

    /// Returns the custom bundle for IRPlayer resources.
    public static var bundle: Bundle {
        return Bundle.module
    }

    // MARK: - Time Conversion
    /// Converts seconds to a formatted time string (HH:mm:ss or mm:ss).
    static func convertTimeSecond(_ timeSecond: Int) -> String {
        if timeSecond < 60 {
            return String(format: "00:%02d", timeSecond)
        } else if timeSecond < 3600 {
            return String(format: "%02d:%02d", timeSecond / 60, timeSecond % 60)
        } else {
            return String(format: "%02d:%02d:%02d", timeSecond / 3600, (timeSecond % 3600) / 60, timeSecond % 60)
        }
    }

    // MARK: - Create Image with Color
    /// Creates an image of the specified color and size.
    public static func image(withColor color: UIColor, size: CGSize) -> UIImage? {
        guard size.width > 0, size.height > 0 else { return nil }
        let rect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0)
        defer { UIGraphicsEndImageContext() }
        if let context = UIGraphicsGetCurrentContext() {
            context.setFillColor(color.cgColor)
            context.fill(rect)
        }
        return UIGraphicsGetImageFromCurrentImageContext()
    }

    // MARK: - Image from Bundle
    /// Loads an image from the bundle with the specified name.
    public static func image(named name: String) -> UIImage? {
        guard !name.isEmpty else { return nil }
        return UIImage(named: name, in: bundle, with: nil) // Uses standard image loading.
    }
}

// MARK: - Device and Screen Helpers

/// Screen width
let IRPlayer_ScreenWidth: CGFloat = UIScreen.main.bounds.width

/// Screen height
let IRPlayer_ScreenHeight: CGFloat = UIScreen.main.bounds.height
