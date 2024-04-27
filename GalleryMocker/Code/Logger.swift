//
//  ActivityIndicator.swift
//  GalleryMocker
//
//  Created by Nikolay Suvandzhiev on 20/04/2024.
//

import Foundation
import OSLog


extension Logger {
    /// Using your bundle identifier is a great way to ensure a unique identifier.
    private static var subsystem = Bundle.main.bundleIdentifier!

    /// All logs related to tracking and analytics.
    static let main = Logger(subsystem: subsystem, category: "main")
}


enum Log {
    static let main = Logger.main
}
