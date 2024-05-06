//
//  SwiftUIHelpers.swift
//  GalleryMocker
//
//  Created by Nikolay Suvandzhiev on 28/04/2024.
//

import SwiftUI

struct FrameSquareModifier: ViewModifier {
    private let size: Double

    init(size: Double) {
        self.size = size
    }

    func body(content: Content) -> some View {
        content
            .frame(width: size, height: size)
    }
}

extension View {
    /// - `size` refers to the sides of the square.
    @ViewBuilder
    func frameSquare(size: Double) -> some View {
        modifier(FrameSquareModifier(size: size))
    }
}

public extension View {
    /// Syntax convenience to allow conditional modifiers via a closure.
    ///
    /// Example usage:
    /// ```
    /// Text("My text")
    ///    .modify {
    ///        if #available(iOS 17.0, *) {
    ///            $0.fontDesign(.monospaced)
    ///        }
    ///    }
    /// ```
    @ViewBuilder
    func modify(@ViewBuilder _ transform: (Self) -> (some View)?) -> some View {
        if let view = transform(self), !(view is EmptyView) {
            view
        } else {
            self
        }
    }
}
