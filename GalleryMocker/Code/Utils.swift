//
//  ActivityIndicator.swift
//  GalleryMocker
//
//  Created by Nikolay Suvandzhiev on 20/04/2024.
//

import Foundation
import CoreLocation.CLLocation


extension String {
    public static func randomString(length: Int) -> String {
        let charsToChooseFrom : String = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
        let numberOfCharsToChooseFrom = UInt32(charsToChooseFrom.count)

        var randomString = ""

        for _ in 0 ..< length {
            let rand = Int(arc4random_uniform(numberOfCharsToChooseFrom))
            var nextChar = (charsToChooseFrom as NSString).character(at: rand)
            randomString += String(utf16CodeUnits: &nextChar, count: 1)
        }

        return randomString
    }
}


extension ProcessInfo {
    static func isOnPreview() -> Bool {
        // return processInfo.processName == "XCPreviewAgent"
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }
}


let specialRandomLocation = CLLocation(
    coordinate: .init(
        latitude: 3.2170717,
        longitude: -126.9294551
    ),
    altitude: 111111,
    horizontalAccuracy: 111,
    verticalAccuracy: 111,
    course: 111,
    courseAccuracy: 111,
    speed: 111,
    speedAccuracy: 111,
    timestamp: .init(timeIntervalSince1970: 111)
)


extension CLLocation {
    var isTheSpecialOne: Bool {
        coordinate.latitude == specialRandomLocation.coordinate.latitude &&
        coordinate.longitude == specialRandomLocation.coordinate.longitude &&
        altitude == specialRandomLocation.altitude &&
        horizontalAccuracy == specialRandomLocation.horizontalAccuracy &&
        verticalAccuracy == specialRandomLocation.verticalAccuracy &&
        course == specialRandomLocation.course
    }
}


var dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm:ss.SSS"
    return formatter
}()
