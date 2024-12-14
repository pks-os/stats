//
//  main.swift
//  GPU
//
//  Created by Serhiy Mytrovtsiy on 17/08/2020.
//  Using Swift 5.0.
//  Running on macOS 10.15.
//
//  Copyright © 2020 Serhiy Mytrovtsiy. All rights reserved.
//

import Cocoa
import Kit
import WidgetKit

public typealias GPU_type = String
public enum GPU_types: GPU_type {
    case unknown = ""
    
    case integrated = "i"
    case external = "e"
    case discrete = "d"
}

public struct GPU_Info: Codable {
    public let id: String
    public let type: GPU_type
    
    public let IOClass: String
    public var vendor: String? = nil
    public let model: String
    public var cores: Int? = nil
    
    public var state: Bool = true
    
    public var fanSpeed: Int? = nil
    public var coreClock: Int? = nil
    public var memoryClock: Int? = nil
    public var temperature: Double? = nil
    public var utilization: Double? = nil
    public var renderUtilization: Double? = nil
    public var tilerUtilization: Double? = nil
    
    init(id: String, type: GPU_type, IOClass: String, vendor: String? = nil, model: String, cores: Int?, utilization: Double? = nil, render: Double? = nil, tiler: Double? = nil) {
        self.id = id
        self.type = type
        self.IOClass = IOClass
        self.vendor = vendor
        self.model = model
        self.cores = cores
        self.utilization = utilization
        self.renderUtilization = render
        self.tilerUtilization = tiler
    }
}

public struct GPUs: Codable {
    public var list: [GPU_Info] = []
    
    internal func active() -> [GPU_Info] {
        return self.list.filter{ $0.state && $0.utilization != nil }.sorted{ $0.utilization ?? 0 > $1.utilization ?? 0 }
    }
}

public class GPU: Module {
    private let popupView: Popup
    private let settingsView: Settings
    private let portalView: Portal
    private let notificationsView: Notifications
    
    private var infoReader: InfoReader? = nil
    
    private var selectedGPU: String = ""
    private var notificationLevelState: Bool = false
    private var notificationID: String? = nil
    
    private var showType: Bool {
        get {
            return Store.shared.bool(key: "\(self.config.name)_showType", defaultValue: false)
        }
    }
    
    public init() {
        self.popupView = Popup()
        self.settingsView = Settings(.GPU)
        self.portalView = Portal(.GPU)
        self.notificationsView = Notifications(.GPU)
        
        super.init(
            moduleType: .GPU,
            popup: self.popupView,
            settings: self.settingsView,
            portal: self.portalView,
            notifications: self.notificationsView
        )
        guard self.available else { return }
        
        self.infoReader = InfoReader(.GPU) { [weak self] value in
            self?.infoCallback(value)
        }
        self.selectedGPU = Store.shared.string(key: "\(self.config.name)_gpu", defaultValue: self.selectedGPU)
        
        self.settingsView.selectedGPUHandler = { [weak self] value in
            self?.selectedGPU = value
            self?.infoReader?.read()
        }
        self.settingsView.setInterval = { [weak self] value in
            self?.infoReader?.setInterval(value)
        }
        self.settingsView.callback = { [weak self] in
            self?.infoReader?.read()
        }
        
        self.setReaders([self.infoReader])
    }
    
    private func infoCallback(_ raw: GPUs?) {
        guard raw != nil && !raw!.list.isEmpty, let value = raw, self.enabled else { return }
        
        DispatchQueue.main.async(execute: {
            self.popupView.infoCallback(value)
        })
        self.settingsView.setList(value)
        
        let activeGPUs = value.active()
        guard let activeGPU = activeGPUs.first(where: { $0.state }) ?? activeGPUs.first else {
            return
        }
        let selectedGPU: GPU_Info = activeGPUs.first{ $0.model == self.selectedGPU } ?? activeGPU
        guard let utilization = selectedGPU.utilization else {
            return
        }
        
        self.portalView.callback(selectedGPU)
        self.notificationsView.usageCallback(utilization)
        
        self.menuBar.widgets.filter{ $0.isActive }.forEach { (w: SWidget) in
            switch w.item {
            case let widget as Mini:
                widget.setValue(utilization)
                widget.setTitle(self.showType ? "\(selectedGPU.type)GPU" : nil)
            case let widget as LineChart: widget.setValue(utilization)
            case let widget as BarChart: widget.setValue([[ColorValue(utilization)]])
            case let widget as Tachometer:
                widget.setValue([
                    circle_segment(value: utilization, color: NSColor.systemBlue)
                ])
            default: break
            }
        }
        
        if #available(macOS 11.0, *) {
            guard let blobData = try? JSONEncoder().encode(selectedGPU) else { return }
            self.userDefaults?.set(blobData, forKey: "GPU@InfoReader")
            WidgetCenter.shared.reloadTimelines(ofKind: GPU_entry.kind)
        }
    }
}
