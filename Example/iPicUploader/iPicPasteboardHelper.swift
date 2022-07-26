//
//  iPicPasteboardHelper.swift
//  iPic
//
//  Created by Jason Zheng on 8/19/16.
//  Copyright © 2016 Jason Zheng. All rights reserved.
//

import Cocoa

internal typealias iPicPasteboardHandler = ((NSPasteboard) -> Void)

public let iPicPasteboardName = "net.toolinbox.ipic.pasteboard"
public let PasteboardTypeiPicImage = "net.toolinbox.ipic.pasteboard.iPicImage"
public let PasteboardTypeiPicUploadResult = "net.toolinbox.ipic.pasteboard.iPicUploadResult"
public let PasteboardTypeiPicUploaderVersion = "net.toolinbox.ipic.pasteboard.iPicUploaderVersion"
public let PasteboardTypeiPicUploaderVersionResult = "net.toolinbox.ipic.pasteboard.iPicUploaderVersionResult"
public let PasteboardTypeImageHostList = "net.toolinbox.ipic.pasteboard.PasteboardTypeImageHostList"
public let PasteboardTypeImageHostListResult = "net.toolinbox.ipic.pasteboard.PasteboardTypeImageHostListResult"

internal let iPicPasteboard = iPicPasteboardHelper.sharedInstance

internal class iPicPasteboardHelper {
  // Singleton
  internal static let sharedInstance = iPicPasteboardHelper()
  private init() {}
  
  private let pasteboard = NSPasteboard(name: NSPasteboard.Name(rawValue: iPicPasteboardName))
  
  private weak var pasteboardObservingTimer: Timer?
  private var pasteboardObservingTimerInterval: TimeInterval = 0.75
  private var pasteboardChangedCount = 0
  
  internal var handler: iPicPasteboardHandler?
  
  // MARK: Internal Method
  
  internal func startObserving() {
    guard pasteboardObservingTimer == nil else {
      return
    }
    
    pasteboardObservingTimer = Timer.scheduledTimer(
      timeInterval: pasteboardObservingTimerInterval,
      target: self,
      selector: #selector(iPicPasteboardHelper.observePasteboard),
      userInfo: nil,
      repeats: true)
    pasteboardObservingTimer?.tolerance = pasteboardObservingTimerInterval * 0.3    
    pasteboardObservingTimer?.fire()
  }
  
  internal func stopObserving() {
    pasteboardObservingTimer?.invalidate()
    pasteboardObservingTimer = nil
  }
  
  @discardableResult internal func writeiPicImage(_ image: iPicImage) -> Bool {
    clearPasteboardContents()
    
    let pasteboardItem = parseiPicImageToPasteboardItem(image)
    return pasteboard.writeObjects([pasteboardItem])
  }
  
  @discardableResult internal func writeiPicUploaderVersionRequest() -> Bool {
    return writeString("", type: PasteboardTypeiPicUploaderVersion)
  }
  
  @discardableResult internal func writeImageHostListRequest() -> Bool {
    return writeString("", type: PasteboardTypeImageHostList)
  }
  
  internal func parseUploadResult(_ pasteboard: NSPasteboard) -> iPicUploadResult? {
    if let type = pasteboard.availableType(from: [NSPasteboard.PasteboardType(rawValue: PasteboardTypeiPicUploadResult)]) {
      if let data = pasteboard.data(forType: type) {
        NSKeyedUnarchiver.setClass(iPicUploadResult.self, forClassName: iPicUploadResult.sharedClassName)
        return NSKeyedUnarchiver.unarchiveObject(with: data) as? iPicUploadResult
      }
    }
    
    return nil
  }
  
  internal func parseiPicUploaderVersionResult(_ pasteboard: NSPasteboard) -> Int? {
    if let versionString = pasteboard.string(forType: NSPasteboard.PasteboardType(rawValue: PasteboardTypeiPicUploaderVersionResult)) {
      return Int(versionString)
    }
    
    return nil
  }
  
  internal func parseImageHostListResult(_ pasteboard: NSPasteboard) -> [iPicImageHost] {
    var imageHostList = [iPicImageHost]()
    
    if let type = pasteboard.availableType(from: [NSPasteboard.PasteboardType(rawValue: PasteboardTypeImageHostListResult)]) {
      if let data = pasteboard.data(forType: type) {
        NSKeyedUnarchiver.setClass(iPicImageHost.self, forClassName: iPicImageHost.sharedClassName)
        
        if let list = NSKeyedUnarchiver.unarchiveObject(with: data) as? [iPicImageHost] {
          imageHostList = list
        }
      }
    }
    
    return imageHostList
  }
  
  // MARK: Helper
  
  @objc private func observePasteboard() {
    let count = pasteboard.changeCount
    if pasteboardChangedCount < count {
      pasteboardChangedCount = count
      
      handler?(pasteboard)
    }
  }
  
  private func parseiPicImageToPasteboardItem(_ image: iPicImage) -> NSPasteboardItem {
    let pasteboardItem = NSPasteboardItem()
    
    NSKeyedArchiver.setClassName(iPicImage.sharedClassName, for: iPicImage.self)
    let data = NSKeyedArchiver.archivedData(withRootObject: image)
    pasteboardItem.setData(data, forType: NSPasteboard.PasteboardType(rawValue: PasteboardTypeiPicImage))
    
    return pasteboardItem
  }
  
  private func writeString(_ str: String, type: String) -> Bool {
    clearPasteboardContents()
    
    let pasteboardItem = NSPasteboardItem()
    pasteboardItem.setString(str, forType: NSPasteboard.PasteboardType(rawValue: type))
    
    return pasteboard.writeObjects([pasteboardItem])
  }
  
  private func clearPasteboardContents() {
    pasteboard.clearContents()
  }
}
