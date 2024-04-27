//
//  ActivityIndicator.swift
//  GalleryMocker
//
//  Created by Nikolay Suvandzhiev on 20/04/2024.
//

import Foundation


@propertyWrapper
struct UserDefault<Value> {
    let key: String
    let defaultValue: Value
    var container: UserDefaults = .standard

    var wrappedValue: Value {
        get { container.object(forKey: key) as? Value ?? defaultValue }
        set { container.set(newValue, forKey: key); container.synchronize() }
    }
}
