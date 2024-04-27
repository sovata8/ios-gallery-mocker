//
//  ActivityIndicator.swift
//  GalleryMocker
//
//  Created by Nikolay Suvandzhiev on 20/04/2024.
//

import UIKit


extension UIImage {
    func withTextOnTop(_ text: NSAttributedString) async -> UIImage {
        await withCheckedContinuation { coninuation in
            DispatchQueue.global(qos: .background).async {
                let image = self
                UIGraphicsBeginImageContextWithOptions(image.size, true, 0)
                let rectImage = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
                let rectText = CGRect(x: 0, y: image.size.height/2, width: image.size.width, height: image.size.height)
                image.draw(in: rectImage)
                // TODO: Figure out how to fix this warning
                text.draw(in: rectText)
                let imageWithText = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                coninuation.resume(returning: imageWithText!)
            }
        }
    }
}



