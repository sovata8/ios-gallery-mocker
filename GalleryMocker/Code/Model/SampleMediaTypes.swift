//
//  SampleMediaTypes.swift
//  GalleryMocker
//
//  Created by Nikolay Suvandzhiev on 28/04/2024.
//

import Foundation


enum SampleImageType: String, CaseIterable, Identifiable {
    var id: Self { self }

    case mountains
    case deers
    case forest
    case trees

    var isLarge: Bool {
        switch self {
        case .mountains, .deers: false
        case .forest, .trees: true
        }
    }
}


enum SampleVideoType: String, CaseIterable, Identifiable {
    var id: Self { self }

    case london
    case new_york

    var webURL: URL {
        switch self {
        case .london:
            URL(string: "https://videos.pexels.com/video-files/13986779/13986779-uhd_2160_3840_60fps.mp4")!
        case .new_york:
            URL(string: "https://videos.pexels.com/video-files/5796436/5796436-uhd_3840_2160_30fps.mp4")!
        }
    }

    var sizeMB: Int {
        switch self {
        case .london: 97
        case .new_york: 193
        }
    }

    var localURL: URL {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsURL.appendingPathComponent(webURL.lastPathComponent)
    }
}
