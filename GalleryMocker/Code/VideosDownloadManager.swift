//
//  VideosDownloadManager.swift
//  GalleryMocker
//
//  Created by Nikolay Suvandzhiev on 20/04/2024.
//

import Foundation


final class VideosDownloadManager: ObservableObject {
    static let sharedInstance = VideosDownloadManager()

    enum Status: Equatable {
        case notDownloaded
        case inProgress(progress: Double)
        case downloaded

        var isDownloaded: Bool {
            if case .downloaded = self { true } else { false }
        }

        var isInProgress: Bool {
            if case .inProgress = self { true } else { false }
        }

        var progress: Double? {
            if case let .inProgress(progress) = self { progress } else { nil }
        }
    }

    private lazy var downloader = FilesDownloader()

    @Published
    private var currentDownload: SampleVideoType?

    var status: [SampleVideoType: Status] = Dictionary(uniqueKeysWithValues: SampleVideoType.allCases.map { ($0, .notDownloaded) })

    func downloadVideo(_ video: SampleVideoType) {
        currentDownload = video
        downloader.download(from: video.webURL, delegate: self)
    }

    func cancel() {
        downloader.cancel()
    }

    private init() {
        SampleVideoType.allCases.forEach { videoType in
            status[videoType] = FileManager.default.fileExists(atPath: videoType.localURL.path) ? .downloaded : .notDownloaded
        }
        self.objectWillChange.send()
    }

    func deleteDownloads() {
        SampleVideoType.allCases.forEach { videoType in
            try! FileManager.default.removeItem(at: videoType.localURL)
            status[videoType] = .notDownloaded
        }
        self.objectWillChange.send()
    }
}


extension VideosDownloadManager: FileDownloadingDelegate {
    func downloadProgressed(_ progress: Double) {
        DispatchQueue.main.async {
            self.status[self.currentDownload!] = .inProgress(progress: progress)
            self.objectWillChange.send()
        }
    }

    func downloadFinished(localFileURL: URL) {
        let destinationURL = currentDownload!.localURL

        if FileManager.default.fileExists(atPath: destinationURL.path) {
            _ = try! FileManager.default.replaceItemAt(destinationURL, withItemAt: localFileURL)
        } else {
            try! FileManager.default.moveItem(at: localFileURL, to: destinationURL)
        }

        DispatchQueue.main.async {
            self.status[self.currentDownload!] = .downloaded
            self.objectWillChange.send()
        }
    }

    func downloadCancelled() {
        DispatchQueue.main.async {
            self.status[self.currentDownload!] = .notDownloaded
            self.objectWillChange.send()
        }
    }

    func downloadFailed(error: Error) {
        // TODO: Handle the error
    }
}
