//
//  FilesDownloader.swift
//  GalleryMocker
//
//  Created by Nikolay Suvandzhiev on 20/04/2024.
//

import Foundation


protocol FileDownloadingDelegate: AnyObject {
    func downloadProgressed(_ progress: Double)
    func downloadFinished(localFileURL: URL)
    func downloadFailed(error: Error)
    func downloadCancelled()
}

class FilesDownloader: NSObject {
    private weak var delegate: FileDownloadingDelegate?
    private var task: URLSessionDownloadTask?

    func download(from url: URL, delegate: FileDownloadingDelegate) {
        self.delegate = delegate
        let sessionConfig = URLSessionConfiguration.background(withIdentifier: url.path)
        let session = URLSession(configuration: sessionConfig, delegate: self, delegateQueue: nil)
        let task = session.downloadTask(with: url)
        task.resume()

        self.task = task
    }

    func cancel() {
        task?.cancel()
        delegate?.downloadCancelled()
    }
}

extension FilesDownloader: URLSessionDownloadDelegate {
    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        guard
            let httpResponse = downloadTask.response as? HTTPURLResponse,
            (200...299).contains(httpResponse.statusCode)
        else {
            Log.main.error("downloadTask error")
            return
        }
        delegate?.downloadFinished(localFileURL: location)
    }

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        delegate?.downloadProgressed(Double(totalBytesWritten)/Double(totalBytesExpectedToWrite))
    }

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?
    ) {
        if let error {
            delegate?.downloadFailed(error: error)
        }
    }
}
