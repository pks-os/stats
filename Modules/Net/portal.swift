//
//  portal.swift
//  Net
//
//  Created by Serhiy Mytrovtsiy on 18/02/2023
//  Using Swift 5.0
//  Running on macOS 13.2
//
//  Copyright © 2023 Serhiy Mytrovtsiy. All rights reserved.
//

import Cocoa
import Kit

public class Portal: PortalWrapper {
    private var chart: NetworkChartView? = nil
    
    private var publicIPField: NSTextField? = nil
    private var publicIPView: NSView? = nil
    private var localIPField: NSTextField? = nil
    private var localIPView: NSView? = nil
    
    private var base: DataSizeBase {
        DataSizeBase(rawValue: Store.shared.string(key: "\(self.name)_base", defaultValue: "byte")) ?? .byte
    }
    private var reverseOrderState: Bool {
        Store.shared.bool(key: "\(self.name)_reverseOrder", defaultValue: false)
    }
    private var chartScale: Scale {
        Scale.fromString(Store.shared.string(key: "\(self.name)_chartScale", defaultValue: Scale.none.key))
    }
    private var chartFixedScale: Int {
        Store.shared.int(key: "\(self.name)_chartFixedScale", defaultValue: 12)
    }
    private var chartFixedScaleSize: SizeUnit {
        SizeUnit.fromString(Store.shared.string(key: "\(self.name)_chartFixedScaleSize", defaultValue: SizeUnit.MB.key))
    }
    private var publicIPState: Bool {
        Store.shared.bool(key: "\(self.name)_publicIP", defaultValue: true)
    }
    
    private var downloadColor: NSColor {
        let v = SColor.fromString(Store.shared.string(key: "\(self.name)_downloadColor", defaultValue: SColor.secondBlue.key))
        var value = NSColor.systemBlue
        if let color = v.additional as? NSColor {
            value = color
        }
        return value
    }
    private var uploadColor: NSColor {
        let v = SColor.fromString(Store.shared.string(key: "\(self.name)_uploadColor", defaultValue: SColor.secondRed.key))
        var value = NSColor.systemRed
        if let color = v.additional as? NSColor {
            value = color
        }
        return value
    }
    
    private var initialized: Bool = false
    
    public override func load() {
        let view = NSStackView()
        view.orientation = .vertical
        view.distribution = .fill
        view.spacing = Constants.Popup.spacing*2
        view.edgeInsets = NSEdgeInsets(
            top: 0,
            left: Constants.Popup.spacing*2,
            bottom: 0,
            right: Constants.Popup.spacing*2
        )
        
        let container: NSView = NSView(frame: CGRect(x: 0, y: 0, width: self.frame.width - (Constants.Popup.spacing*8), height: 68))
        container.wantsLayer = true
        container.layer?.cornerRadius = 3
        
        let chart = NetworkChartView(
            frame: CGRect(x: 0, y: 0, width: self.frame.width - (Constants.Popup.spacing*8), height: 68),
            num: 120,
            reversedOrder: self.reverseOrderState,
            outColor: self.uploadColor,
            inColor: self.downloadColor,
            scale: self.chartScale,
            fixedScale: Double(self.chartFixedScaleSize.toBytes(self.chartFixedScale))
        )
        chart.base = self.base
        container.addSubview(chart)
        self.chart = chart
        view.addArrangedSubview(container)
        
        let publicIP = portalRow(view, title: "\(localizedString("Public IP")):", value: localizedString("Unknown"), isSelectable: true)
        self.publicIPField = publicIP.1
        self.publicIPView = publicIP.2
        self.publicIPView?.isHidden = !self.publicIPState
        self.publicIPView?.heightAnchor.constraint(equalToConstant: 16).isActive = true
        
        let localIP = portalRow(view, title: "\(localizedString("Local IP")):", value: localizedString("Unknown"), isSelectable: true)
        self.localIPField = localIP.1
        self.localIPView = localIP.2
        self.localIPView?.isHidden = self.publicIPState
        self.localIPView?.heightAnchor.constraint(equalToConstant: 16).isActive = true
        
        self.addArrangedSubview(view)
    }
    
    public func usageCallback(_ value: Network_Usage) {
        DispatchQueue.main.async(execute: {
            if let chart = self.chart {
                if chart.base != self.base {
                    chart.base = self.base
                }
                chart.addValue(upload: Double(value.bandwidth.upload), download: Double(value.bandwidth.download))
                chart.setScale(self.chartScale, Double(self.chartFixedScaleSize.toBytes(self.chartFixedScale)))
                chart.setColors(in: self.downloadColor, out: self.uploadColor)
            }
            
            if self.publicIPState, let view = self.publicIPView, view.isHidden {
                self.publicIPView?.isHidden = false
                self.localIPView?.isHidden = true
            } else if !self.publicIPState, let view = self.publicIPView, !view.isHidden {
                self.publicIPView?.isHidden = true
                self.localIPView?.isHidden = false
            }
            
            if let view = self.publicIPField, view.stringValue != value.raddr.v4 {
                if let addr = value.raddr.v4 {
                    view.stringValue = (value.wifiDetails.countryCode != nil) ? "\(addr) (\(value.wifiDetails.countryCode!))" : addr
                } else {
                    view.stringValue = localizedString("Unknown")
                }
                if let addr = value.raddr.v6 {
                    view.toolTip = "\("\(localizedString("v6")):") \(addr)"
                } else {
                    view.toolTip = "\("\(localizedString("v6")):") \(localizedString("Unknown"))"
                }
            }
            
            if self.localIPField?.stringValue != value.laddr {
                self.localIPField?.stringValue = value.laddr ?? localizedString("Unknown")
            }
        })
    }
}
