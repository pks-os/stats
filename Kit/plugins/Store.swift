//
//  store.swift
//  Kit
//
//  Created by Serhiy Mytrovtsiy on 10/04/2020.
//  Using Swift 5.0.
//  Running on macOS 10.15.
//
//  Copyright © 2020 Serhiy Mytrovtsiy. All rights reserved.
//

import Cocoa

public class Store {
    public static let shared = Store()
    private let defaults = UserDefaults.standard
    
    public init() {}
    
    public func exist(key: String) -> Bool {
        return self.defaults.object(forKey: key) == nil ? false : true
    }
    
    public func remove(_ key: String) {
        self.defaults.removeObject(forKey: key)
    }
    
    public func bool(key: String, defaultValue value: Bool) -> Bool {
        return !self.exist(key: key) ? value : defaults.bool(forKey: key)
    }
    
    public func string(key: String, defaultValue value: String) -> String {
        return (!self.exist(key: key) ? value : defaults.string(forKey: key))!
    }
    
    public func int(key: String, defaultValue value: Int) -> Int {
        return (!self.exist(key: key) ? value : defaults.integer(forKey: key))
    }
    
    public func array(key: String, defaultValue value: [Any]) -> [Any] {
        return (!self.exist(key: key) ? value : defaults.array(forKey: key)!)
    }
    
    public func data(key: String) -> Data? {
        return defaults.data(forKey: key)
    }
    
    public func set(key: String, value: Bool) {
        self.defaults.set(value, forKey: key)
    }
    
    public func set(key: String, value: String) {
        self.defaults.set(value, forKey: key)
    }
    
    public func set(key: String, value: Int) {
        self.defaults.set(value, forKey: key)
    }
    
    public func set(key: String, value: Data) {
        self.defaults.set(value, forKey: key)
    }
    
    public func set(key: String, value: [Any]) {
        self.defaults.set(value, forKey: key)
    }
    
    public func reset() {
        self.defaults.dictionaryRepresentation().keys.forEach { key in
            self.defaults.removeObject(forKey: key)
        }
    }
    
    public func export(to url: URL) {
        guard let id = Bundle.main.bundleIdentifier,
              let dicitionary = self.defaults.persistentDomain(forName: id) else { return }
        NSDictionary(dictionary: dicitionary).write(to: url, atomically: true)
    }
    
    public func `import`(from url: URL) {
        guard let id = Bundle.main.bundleIdentifier, let dict = NSDictionary(contentsOf: url) as? [String: Any] else { return }
        self.defaults.setPersistentDomain(dict, forName: id)
        restartApp(self)
    }
}
