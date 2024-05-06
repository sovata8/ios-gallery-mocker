//
//  CircularProgressView.swift
//  GalleryMocker
//
//  Created by Nikolay Suvandzhiev on 24/04/2024.
//

import SwiftUI

struct CircularProgressView: View {
    enum LinePosition: CaseIterable {
        case inside
        case middle
        case outside
    }

    enum LineWidth {
        case absolute(width: Double)
        /// How much of the width of the whole view is the line width.
        /// Sensible max value is `0.4`.
        case relative(ratio: Double)
    }

    private let progress: Double
    private let linePosition: LinePosition
    private let lineWidth: LineWidth

    init(
        progress: Double,
        linePosition: LinePosition = .outside,
        lineWidth: LineWidth = .relative(ratio: 0.2)
    ) {
        self.progress = progress
        self.linePosition = linePosition
        self.lineWidth = lineWidth
    }

    var body: some View {
        GeometryReader { proxy in
            let lineWidthValue = switch lineWidth {
            case .absolute(let width): width
            case .relative(let ratio): proxy.size.width * ratio
            }

            ZStack {
                Circle()
                    .stroke(lineWidth: lineWidthValue)
                    .opacity(0.5)
                    .foregroundColor(.blue) // TODO: Get default tint and apply

                Circle()
                    .trim(from: 0, to: min(progress, 1))
                    .stroke(
                        style: StrokeStyle(
                            lineWidth: lineWidthValue,
                            lineCap: .round,
                            lineJoin: .round
                        )
                    )
                    .foregroundColor(.blue)
                    .opacity(1)
                    .rotationEffect(Angle(degrees: 270))
                    .animation(.linear, value: progress)
            }
            .modify {
                switch linePosition {
                case .inside:
                    $0
                    .frameSquare(size: proxy.size.width - lineWidthValue)
                    .offset(x: lineWidthValue/2, y: lineWidthValue/2)
                case .middle:
                    $0
                case .outside:
                    $0
                    .frameSquare(size: proxy.size.width + lineWidthValue)
                    .offset(x: -lineWidthValue/2, y: -lineWidthValue/2)
                }
            }
        }
    }
}


#Preview {
    Grid(horizontalSpacing: 40, verticalSpacing: 40) {
        ForEach([0, 0.01, 0.25, 0.5, 0.75, 0.99, 1], id: \.self) { progress in
            GridRow {
                ForEach(CircularProgressView.LinePosition.allCases, id: \.self) { linePosition in
                    ZStack {
                        CircularProgressView(
                            progress: progress,
                            linePosition: linePosition,
                            lineWidth: .absolute(width: 5)
                        )
                        .frameSquare(size: 44)
                        .opacity(0.5)

                        Circle()
                            .fill(.red.opacity(0.5))
                            .frameSquare(size: 44)
                    }
                }
            }
        }
    }
    .preferredColorScheme(.dark)
}
