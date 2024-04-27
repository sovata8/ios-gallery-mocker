//
//  CircularProgressView.swift
//  GalleryMocker
//
//  Created by Nikolay Suvandzhiev on 24/04/2024.
//

import SwiftUI

private let width: Double = 2


struct CircularProgressView: View {
    let progress: Double


    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: width)
                .opacity(0.1)
                .foregroundColor(.blue)

            Circle()
                .trim(from: 0, to: min(progress, 1))
                .stroke(style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
                .foregroundColor(.blue)
                .rotationEffect(Angle(degrees: 270))
                .animation(.linear, value: progress)
        }
    }
}

