//
//  GalleryManager.swift
//  GalleryMocker
//
//  Created by Nikolay Suvandzhiev on 20/04/2024.
//

import UIKit
import Photos


enum GalleryManager {
    private static var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH:mm:ss_SSS"
        return formatter
    }()


    @UserDefault(key: "local_phassets_ids", defaultValue: [])
    static var localIDs: [String]


    // PUBLIC:
    static func writeToGallery(imageURL: URL, addText: Bool, addRandomTint: Bool, creationDate: Date?) async throws {
        if addText || addRandomTint {
            let image = UIImage(data: try Data(contentsOf: imageURL))!
            try await writeToGallery(image: image, addText: addText, addRandomTint: addRandomTint, creationDate: creationDate)
        } else {
            try await writeToGalleryMedia(url: imageURL, type: .photo, creationDate: creationDate)
        }
    }


    static func writeToGallery(videoURL: URL, creationDate: Date?) async throws {
        try await writeToGalleryMedia(url: videoURL, type: .video, creationDate: creationDate)
    }


    static func deleteAllFromGallery() async throws {
        try await deleteAllFromGallery(ids: localIDs)
    }

    static func deleteAllFromGallerySecondaApproach() async throws {
        var assetIDsWithSpecialLocation: [String] = []

        PHAsset.fetchAssets(with: nil)
            .enumerateObjects { asset, _, _ in
                if asset.location?.isTheSpecialOne == true {
                    assetIDsWithSpecialLocation.append(asset.localIdentifier)
                }
            }

        try await deleteAllFromGallery(ids: assetIDsWithSpecialLocation)
        localIDs = []
    }



    // PRIVATE:
    private static func writeToGalleryMedia(url: URL, type: PHAssetResourceType, creationDate: Date?) async throws {
        let dateText = dateFormatter.string(from: .now)
        let randomText = "[\(String.randomString(length: 5))]"
        let name = "gallery_mocker_\(dateText)_\(randomText)"

        // in this round
        var savedAssetIDs: [String] = []
        try PHPhotoLibrary.shared().performChangesAndWait {
            let options = PHAssetResourceCreationOptions()
            options.originalFilename = name
            let creationRequest: PHAssetCreationRequest = PHAssetCreationRequest.forAsset()
            creationRequest.addResource(with: type, fileURL: url, options: options)

            if let savedAssetID = creationRequest.placeholderForCreatedAsset?.localIdentifier {
                localIDs += [savedAssetID]
                savedAssetIDs.append(savedAssetID)
            }
        }

        try setCreationDate(assetIDs: savedAssetIDs, date: creationDate)
    }

    // date nil means 'now'
    private static func setCreationDate(assetIDs: [String], date: Date?) throws {
        let assetsToChangeDateOf = PHAsset.fetchAssets(withLocalIdentifiers: assetIDs, options: nil)
        var assetsJustSaved: [PHAsset] = []
        assetsToChangeDateOf.enumerateObjects { asset, _, _ in assetsJustSaved.append(asset) }
        for assetJustSaved in assetsJustSaved {
            try PHPhotoLibrary.shared().performChangesAndWait {
                let changeRequest: PHAssetChangeRequest = PHAssetChangeRequest.init(for: assetJustSaved)
                changeRequest.creationDate = date ?? .now
                changeRequest.location = specialRandomLocation
                if let changdAssetID = changeRequest.placeholderForCreatedAsset?.localIdentifier {
                    localIDs += [changdAssetID]
                }
            }
        }
    }


    // Note that in this case we don't need to set the creaton date to 'now'.
    private static func writeToGallery(image: UIImage, addText: Bool, addRandomTint: Bool, creationDate: Date?) async throws {
        if !addText && !addRandomTint {
            Log.main.warning("You're using `writeToGallery(image:` but not adding any text or tint. It's better to use the much faster `writeToGallery(imageURL:`")
        }

        let dateText = dateFormatter.string(from: .now)
        let randomText = "[\(String.randomString(length: 5))]"
        let name = "gallery_mocker_\(dateText)_\(randomText))"

        var imageToWrite = image

        if addRandomTint {
            imageToWrite = imageToWrite.withRandomTint()
        }
        if addText {
            imageToWrite = await imageToWrite.withTextOnTop(getFinalString(imageWidth: image.size.width, randomText: randomText))
        }

        // in this round
        var savedAssetIDs: [String] = []
        try PHPhotoLibrary.shared().performChangesAndWait {
            let options = PHAssetResourceCreationOptions()
            options.originalFilename = name
            let creationRequest: PHAssetCreationRequest = PHAssetCreationRequest.forAsset()
            creationRequest.addResource(with: .photo, data: imageToWrite.heicData()!, options: options)

            if let savedAssetID = creationRequest.placeholderForCreatedAsset?.localIdentifier {
                localIDs += [savedAssetID]
                savedAssetIDs.append(savedAssetID)
            }
        }

        try setCreationDate(assetIDs: savedAssetIDs, date: creationDate)
    }


    private static func deleteAllFromGallery(ids: [String]) async throws {
        let localIDsToDelete = ids
        let assets = PHAsset.fetchAssets(withLocalIdentifiers: localIDsToDelete, options: nil)
        try PHPhotoLibrary.shared().performChangesAndWait {
            PHAssetChangeRequest.deleteAssets(assets)
        }
        localIDs = []
    }


    private static func getFinalString(imageWidth: Double, randomText: String) -> NSAttributedString {
        let dateText = dateFormatter.string(from: .now)

        let finalText = randomText + "\n" + dateText

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        paragraphStyle.lineSpacing = 20

        let scale: CGFloat = 0.8

        let attrString = NSMutableAttributedString(string: finalText, attributes: [
            NSAttributedString.Key.font: UIFont(name: "Menlo", size: imageWidth * 0.05095541401 * scale)!,
            NSAttributedString.Key.foregroundColor: UIColor.white,
            NSAttributedString.Key.backgroundColor: UIColor.black.withAlphaComponent(0.5),
            NSAttributedString.Key.paragraphStyle: paragraphStyle
        ])

        attrString.addAttributes(
            [NSAttributedString.Key.font: UIFont(name: "Menlo", size: imageWidth * 0.16761649346 * scale)!],
            range: .init(location: 0, length: randomText.count)
        )

        return attrString
    }
}
