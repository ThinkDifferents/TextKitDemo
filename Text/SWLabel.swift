//
//  SWLabel.swift
//  TextKit
//
//  Created by shiwei on 17/5/26.
//  Copyright © 2017年 shiwei. All rights reserved.
//

import UIKit

@objc
public protocol SWLabelDelegate: NSObjectProtocol {
    
    /// 选中连接文本
    @objc optional func labelDidSelectedLinkText(label: SWLabel, text: String)
}

public class SWLabel: UILabel {
    
    public var linkTextColor = UIColor.init(red: 50 / 255.0, green: 155 / 255.0, blue: 250 / 255.0, alpha: 1)
    public var selectedBackgroudColor = UIColor.lightGray
    public weak var delegate: SWLabelDelegate?
    
    // MARK: - 重写属性
    override public var text: String? {
        didSet {
            prepareTextSystem()
        }
    }
    
    override public var attributedText: NSAttributedString? {
        didSet {
            prepareTextSystem()
        }
    }
    
    override public var font: UIFont! {
        didSet {
            prepareTextSystem()
        }
    }
    
    override public var textColor: UIColor! {
        didSet {
            prepareTextSystem()
        }
    }
    
    /// 准备文本系统
    func prepareTextSystem() -> () {
        
        if attributedText == nil {
            return
        }
        
        let attrStringM = addLinkBreak(attributedText!)
        regxLinkRanges(attrStringM)
        addLinkAttribute(attrStringM)
        
        textStorage.setAttributedString(attrStringM)
        
        setNeedsDisplay()
        
    }
    
    private func addLinkAttribute(_ attrStringM: NSMutableAttributedString) {
        if attrStringM.length == 0 {
            return
        }
        
        var range = NSRange(location: 0, length: 0)
        var attributes = attrStringM.attributes(at: 0, effectiveRange: &range)
        
        attributes[NSFontAttributeName] = font!
        attributes[NSForegroundColorAttributeName] = textColor
        attrStringM.addAttributes(attributes, range: range)
        
        attributes[NSForegroundColorAttributeName] = linkTextColor
        
        for r in linkRanges {
            attrStringM.setAttributes(attributes, range: r)
        }
    }
    
    // MARK: - 正则表达式函数
    // 1.正则表达式
    private let pattern = ["[a-zA-Z]*://[a-zA-Z0-9/\\.]*","#.*?#", "@[\\u4e00-\\u9fa5a-zA-Z0-9_-]*"]
    
    private func regxLinkRanges(_ attrString: NSAttributedString) {
        linkRanges.removeAll()
        let regexRange = NSRange(location: 0, length: attrString.string.characters.count)
        
        for pattern in pattern {
            let regex = try! NSRegularExpression(pattern: pattern, options: NSRegularExpression.Options.dotMatchesLineSeparators)
            let results = regex.matches(in: attrString.string, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: regexRange)
            
            for r in results {
                linkRanges.append(r.rangeAt(0))
            }
        }
    }
    
    
    private func addLinkBreak(_ attrString: NSAttributedString) -> NSMutableAttributedString {
        let attrStringM = NSMutableAttributedString(attributedString: attrString)
        
        if attrStringM.length == 0 {
            return attrStringM
        }
        
        var range = NSRange(location: 0, length: 0)
        var attributes = attrStringM.attributes(at: 0, effectiveRange: &range)
        var paragrahStyle = attributes[NSParagraphStyleAttributeName] as? NSMutableParagraphStyle
        
        if paragrahStyle != nil {
            paragrahStyle!.lineBreakMode = NSLineBreakMode.byWordWrapping
        } else {
            paragrahStyle = NSMutableParagraphStyle()
            paragrahStyle!.lineBreakMode = NSLineBreakMode.byWordWrapping
            attributes[NSParagraphStyleAttributeName] = paragrahStyle
            
            attrStringM.setAttributes(attributes, range: range)
        }
        return attrStringM
    }
    
    /// 绘制文本
    override public func drawText(in rect: CGRect) {
        
        let range = glyphsRange()
        let offset = glyphsOffset(range)
        
        layoutManager.drawBackground(forGlyphRange: range, at: offset)
        layoutManager.drawGlyphs(forGlyphRange: range, at: CGPoint.zero)
    }

    private func glyphsRange() -> NSRange {
        return NSRange(location: 0, length: textStorage.length)
    }
    
    private func glyphsOffset(_ range: NSRange) -> CGPoint {
        let rect = layoutManager.boundingRect(forGlyphRange: range, in: textContainer)
        let height = (bounds.height - rect.height) * 0.5
        return CGPoint(x: 0, y: height)
    }
    
    // MARK: - 交互
    override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let location = touches.first?.location(in: self) else {
            return
        }
        selectedRange = linkRangeAtLocation(location)
        modifySelectedAttribute(true)
    }

    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let location = touches.first?.location(in: self) else {
            return
        }
        if let range = linkRangeAtLocation(location) {
            if !(range.location == selectedRange?.location && range.length == selectedRange?.length) {
                modifySelectedAttribute(false)
                selectedRange = range
                modifySelectedAttribute(true)
            }
        } else {
           modifySelectedAttribute(false)
        }
    }
    
    override public func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if selectedRange != nil {
            let text = (textStorage.string as NSString).substring(with: selectedRange!)
            delegate?.labelDidSelectedLinkText?(label: self, text: text)
            
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(0.25 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)) {
                self.modifySelectedAttribute(false)
            }
        }
    }
    
    public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        modifySelectedAttribute(false)
    }
    
    private func modifySelectedAttribute(_ isSet: Bool) {
        if selectedRange == nil {
            return
        }
        var attributes = textStorage.attributes(at: 0, effectiveRange: nil)
        attributes[NSForegroundColorAttributeName] = linkTextColor
        let range = selectedRange!
        
        if isSet {
            attributes[NSBackgroundColorAttributeName] = selectedBackgroudColor
        } else {
            attributes[NSBackgroundColorAttributeName] = UIColor.clear
            selectedRange = nil
        }
        textStorage.addAttributes(attributes, range: range)
        setNeedsDisplay()
    }
    
    private func linkRangeAtLocation(_ location: CGPoint) -> NSRange? {
        if textStorage.length == 0 {
            return nil
        }
        let offset = glyphsOffset(glyphsRange())
        let point = CGPoint(x: offset.x + location.x, y: offset.y + location.y)
        let index = layoutManager.glyphIndex(for: point, in: textContainer)
        
        for r in linkRanges {
            if index >= r.location && index <= r.location + r.length {
                return r
            }
        }
        return nil
    }
    
    // MARK: - 构造函数
    override init(frame: CGRect) {
        super.init(frame: frame)
        prepareLabel()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        prepareLabel()
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        
        // 制定绘制文本的区域
        textContainer.size = bounds.size
    }
    
    private func prepareLabel() {
        textStorage.addLayoutManager(layoutManager)
        layoutManager.addTextContainer(textContainer)
        textContainer.lineFragmentPadding = 0
        isUserInteractionEnabled = true
    }
    
    // MARK: - TextKit 的核心对象
    private lazy var linkRanges = [NSRange]()
    private var selectedRange: NSRange?
    private lazy var textStorage = NSTextStorage()
    private lazy var layoutManager = NSLayoutManager()
    private lazy var textContainer = NSTextContainer()
}
