//
//  CircularButtonWithProgress.swift
//  GalleryMocker
//
//  Created by Nikolay Suvandzhiev on 28/04/2024.
//

import SwiftUI


struct CircularButtonWithProgress: View {
    let image: Image
    let isProgressShown: Bool // TODO: Make enum and the below an associated value
    let progress: Double
    let action: () -> Void

    init(
        image: Image,
        isProgressShown: Bool,
        progress: Double,
        action: @escaping () -> Void
    ) {
        self.image = image
        self.isProgressShown = isProgressShown
        self.progress = progress
        self.action = action
    }

    var body: some View {
        ZStack {
            Button { action() }
            label: { image }

            CircularProgressView(
                progress: progress,
                linePosition: .outside,
                lineWidth: .relative(ratio: 0.15)
            )
            .opacity(isProgressShown ? 1 : 0)
        }
        .fixedSize()
    }
}

#Preview {
    CircularButtonWithProgress(
        image: Image(systemName: "xmark.circle.fill"),
        isProgressShown: true,
        progress: 0.5,
        action: {}
    )
}
