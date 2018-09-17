//
//  ProgressHUD.swift
//  ProgressHUD, https://github.com/massimobio/ProgressHUD
//
//  Created by Massimo Biolcati on 9/10/18.
//  Copyright © 2018 Massimo. All rights reserved.
//

import AppKit

// ProgressHUD operation mode
enum ProgressHUDMode {
    case indeterminate // Progress is shown using an Spinning Progress Indicator. This is the default.
    case determinate // Progress is shown using a round, pie-chart like, progress view.
    case error // Shows an error icon and the text labels.
    case success // Shows a success icon and the text labels.
    case customView // Shows a custom view and the text labels.
    case text // Shows only the text labels labels.
}

// ProgressHUD theme
enum ProgressHUDStyle {
    case light // light HUD background with dark text and progress indicator
    case dark // dark HUD background with light text and progress indicator
    case custom // uses the ProgressHUDSettings's backgroundColor and tintColor
}

// ProgressHUD mask for the view around of the HUD
enum ProgressHUDMaskType {
    case none // default mask type, allow user interactions while HUD is displayed
    case clear // don't allow user interactions with background objects
    case black // don't allow user interactions with background objects and dim the UI in the back of the HUD (as seen in iOS 7 and above)
    case gradient // don't allow user interactions with background objects and dim the UI with a a-la UIAlertView background gradient (as seen in iOS 6)
    case custom // don't allow user interactions with background objects and dim the UI in the back of the HUD with a custom color (customMaskTypeColor)
}

// ProgressHUD position inside the view
enum ProgressHUDPosition {
    case top
    case center
    case bottom
    case custom
}

// Use this for detailed customization of the ProgressHUD
struct ProgressHUDSettings {
    var mode: ProgressHUDMode = .indeterminate
    var style: ProgressHUDStyle = .light
    var maskType = ProgressHUDMaskType.clear
    var position: ProgressHUDPosition = .bottom
    var titleFont = NSFont.boldSystemFont(ofSize: 18)
    var titleColor = NSColor.black
    var messageFont = NSFont.systemFont(ofSize: 16)
    var messageColor = NSColor.black
    var customView: NSView? // The view to be shown when the HUD is in ProgressHUDModeCustomView.
    var opacity: CGFloat = 0.9 // The opacity of the HUD window.
    var backgroundColor: NSColor = .white // The color of the HUD window.
    var tintColor: NSColor = .black // The color of the text and details.
    var xOffset: CGFloat = 0.0 // The x-axis offset of the HUD relative to the centre of the superview. (ProgressHUDPosition has to be custom)
    var yOffset: CGFloat = 0.0 // The y-axis offset of the HUD relative to the centre of the superview. (ProgressHUDPosition has to be custom)
    var spinsize: CGFloat = 60.0 // The size both horizontally and vertically of the spinner
    var margin: CGFloat = 20.0 // The amount of space between the HUD edge and the HUD elements (labels, indicators or custom views).
    var padding: CGFloat = 4.0 // The amount of space between the HUD elements (labels, indicators or custom views).
    var cornerRadius: CGFloat = 10.0 // The corner radius for th HUD
    var customMaskTypeColor = NSColor.black.withAlphaComponent(0.6) // This color will be used as the view background when maskType is set to .custom.
    var dismissible = true // Allow User to dismiss HUD manually by a tap event
    var removeFromSuperViewOnHide = true // Removes the HUD from its parent view when hidden.
    var square = false // Force the HUD dimensions to be equal if possible.
}

extension NSView {

    func showProgressHUD(title: String,
                         message: String,
                         mode: ProgressHUDMode = .indeterminate,
                         settings: ProgressHUDSettings = ProgressHUDSettings(),
                         duration: TimeInterval = 0) {

        if let hud = ProgressHUD.hud(in: self) {
            hud.hide(false) // remove any hud that may be in the view
        }

        var s = settings
        s.mode = mode
        let hud = ProgressHUD(view: self, settings: s)
        hud.title = title
        hud.message = message
        addSubview(hud)
        hud.show(true)
        if duration > 0 {
            hud.hide(true, afterDelay: duration)
        }
    }

    func setProgressHUDProgress(_ progress: Double) {
        DispatchQueue.main.async {
            if let hud = ProgressHUD.hud(in: self) {
                hud.progress = progress
            }
        }
    }

    func hideProgressHUD(afterDelay delay: TimeInterval = 0) {
        DispatchQueue.main.async {
            if let hud = ProgressHUD.hud(in: self) {
                hud.hide(true, afterDelay: delay)
            }
        }
    }
}

typealias ProgressHUDCompletionBlock = () -> Void

private class ProgressHUD: NSView {

    private var settings = ProgressHUDSettings()

    /// A block that gets called after the HUD is completely hidden.
    var completionBlock: ProgressHUDCompletionBlock?

    /// An optional short message to be displayed below the activity indicator. The HUD is automatically resized to fit the entire text.
    /// If the text is too long it will get clipped by displaying "..." at the end. If left unchanged or set to @"", then no message is displayed.
    var title = "" {
        didSet {
            titleLabel.string = title
            titleLabel.sizeToFit()
            needsLayout = true
            needsDisplay = true
        }
    }

    /// An optional details message displayed below the labelText message. This message is displayed only if the labelText
    /// property is also set and is different from an empty string (@""). The details text can span multiple lines.
    var message = "" {
        didSet {
            messageLabel.string = message
            messageLabel.sizeToFit()
            needsLayout = true
            needsDisplay = true
        }
    }

    /// The progress of the progress indicator, from 0.0 to 1.0
    var progress: Double = 0.0 {
        didSet {
            needsLayout = true
            needsDisplay = true
        }
    }

    // MARK: - Private Properties

    private var indicator: NSView?
    private var progressIndicator: ProgressIndicatorLayer!
    private var size = CGSize.zero
    private var useAnimation = true
    private let titleLabel = NSText(frame: .zero)
    private let messageLabel = NSText(frame: .zero)
    private var isFinished = false
    private var rotationTransform: CGAffineTransform = .identity
    private var xOffset: CGFloat {
        switch settings.position {
        case .top, .center, .bottom: return 0
        case .custom: return settings.xOffset
        }
    }

    private var yOffset: CGFloat {
        switch settings.position {
        case .top: return -bounds.size.height / 5
        case .center: return 0
        case .bottom: return bounds.size.height / 5
        case .custom: return settings.yOffset
        }
    }

    private var backgroundColor: NSColor {
        switch settings.style {
        case .light: return .white
        case .dark: return .black
        case .custom: return settings.backgroundColor
        }
    }

    private var tintColor: NSColor {
        switch settings.style {
        case .light: return .black
        case .dark: return .init(white: 0.95, alpha: 1)
        case .custom: return settings.tintColor
        }
    }

    // MARK: - Class methods

    // Finds the top-most HUD subview and returns it.
    class func hud(in view: NSView) -> ProgressHUD? {
        for subview in view.subviews where subview is ProgressHUD {
            return subview as? ProgressHUD
        }
        return nil
    }

    // MARK: - Lifecycle

    // A convenience constructor that initializes the HUD with the view's bounds.
    convenience init(view: NSView, settings: ProgressHUDSettings = ProgressHUDSettings()) {
        var bounds = view.frame
        bounds.origin.x = 0.0
        bounds.origin.y = 0.0
        self.init(frame: bounds)
        self.settings = settings
        progressIndicator = ProgressIndicatorLayer(size: settings.spinsize, color: tintColor)
        setupLabels()
        updateIndicators()
    }

    override init(frame: NSRect) {
        super.init(frame: frame)
        autoresizingMask = [.maxXMargin, .minXMargin, .maxYMargin, .minYMargin]
        layer?.isOpaque = false
        layer?.backgroundColor = NSColor.clear.cgColor
        alphaValue = 0.0
    }

    required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLabels() {
        titleLabel.isEditable = false
        titleLabel.isSelectable = false
        titleLabel.alignment = .center
        titleLabel.layer?.isOpaque = false
        titleLabel.backgroundColor = .clear
        titleLabel.textColor = tintColor
        titleLabel.font = settings.titleFont
        titleLabel.string = title
        titleLabel.sizeToFit()
        addSubview(titleLabel)

        messageLabel.font = settings.messageFont
        messageLabel.isEditable = false
        messageLabel.isSelectable = false
        messageLabel.alignment = .center
        messageLabel.layer?.isOpaque = false
        messageLabel.backgroundColor = .clear
        messageLabel.textColor = tintColor
        messageLabel.font = settings.messageFont
        messageLabel.string = message
        messageLabel.sizeToFit()
        addSubview(messageLabel)
    }

    // MARK: - Show & Hide

    func show(_ animated: Bool) {
        useAnimation = animated
        needsDisplay = true
        show(usingAnimation: useAnimation)
    }

    func hide(_ animated: Bool) {
        useAnimation = animated
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        hide(usingAnimation: useAnimation)
    }

    func hide(_ animated: Bool, afterDelay delay: TimeInterval) {
        perform(#selector(hideDelayed(_:)), with: animated ? 1 : 0, afterDelay: delay)
    }

    private func hide(usingAnimation animated: Bool) {
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        // Fade out
        if animated {
            NSAnimationContext.beginGrouping()
            NSAnimationContext.current.duration = 0.20
            NSAnimationContext.current.completionHandler = {
                self.done()
            }
            animator().alphaValue = 0
            NSAnimationContext.endGrouping()
        } else {
            alphaValue = 0.0
            done()
        }
    }

    private func show(usingAnimation animated: Bool) {
        // Fade in
        isHidden = false
        if animated {
            NSAnimationContext.beginGrouping()
            NSAnimationContext.current.duration = 0.20
            animator().alphaValue = 1.0
            NSAnimationContext.endGrouping()
        } else {
            alphaValue = 1.0
        }
    }

    private func done() {
        isFinished = true
        alphaValue = 0.0
        isHidden = true
        if settings.removeFromSuperViewOnHide {
            removeFromSuperview()
        }
        completionBlock?()
        completionBlock = nil
        indicator = nil
    }

    override func mouseDown(with theEvent: NSEvent) {
        if settings.maskType == .none {
            super.mouseDown(with: theEvent)
        }
        if settings.dismissible {
            performSelector(onMainThread: #selector(cleanUp), with: nil, waitUntilDone: true)
        }
    }

    private func updateIndicators() {
        let isActivityIndicator = indicator?.layer is ProgressIndicatorLayer

        if settings.mode == .indeterminate && !isActivityIndicator {

            indicator?.removeFromSuperview()
            let view = NSView(frame: NSRect(x: 0, y: 0, width: settings.spinsize, height: settings.spinsize))
            view.wantsLayer = true
            progressIndicator.startProgressAnimation()
            view.layer?.addSublayer(progressIndicator)
            indicator = view
            addSubview(indicator!)

        } else if settings.mode == .determinate || settings.mode == .text {

            indicator?.removeFromSuperview()
            indicator = nil

        } else if settings.mode == .customView, let view = settings.customView, view != indicator {

            indicator?.removeFromSuperview()
            indicator = view
            addSubview(indicator!)

        }
    }

    @objc private func cleanUp() {
        hide(useAnimation)
    }

    @objc private func hideDelayed(_ animated: NSNumber?) {
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        hide((animated != 0))
    }

    // MARK: - Internal show & hide operations

    func animationFinished(_ animationID: String?, finished: Bool, context: UnsafeMutableRawPointer?) {
        done()
    }

    // MARK: - Layout

    func layoutSubviews() {

        // Entirely cover the parent view
        frame = superview?.bounds ?? .zero

        // Determine the total width and height needed
        let maxWidth = bounds.size.width - settings.margin * 4
        var totalSize = CGSize.zero
        var indicatorF = indicator?.bounds ?? .zero
        if settings.mode == .determinate {
            indicatorF.size.height = settings.spinsize
        }
        indicatorF.size.width = min(indicatorF.size.width, maxWidth)
        totalSize.width = max(totalSize.width, indicatorF.size.width)
        totalSize.height += indicatorF.size.height
        if indicatorF.size.height > 0.0 {
            totalSize.height += settings.padding
        }

        var labelSize: CGSize = titleLabel.string.count > 0 ? titleLabel.string.size(withAttributes: [NSAttributedString.Key.font: titleLabel.font!]) : CGSize.zero
        if labelSize.width > 0.0 {
            labelSize.width += 10.0
        }
        labelSize.width = min(labelSize.width, maxWidth)
        totalSize.width = max(totalSize.width, labelSize.width)
        totalSize.height += labelSize.height
        if labelSize.height > 0.0 && indicatorF.size.height > 0.0 {
            totalSize.height += settings.padding
        }
        var detailsLabelSize: CGSize = messageLabel.string.count > 0 ? messageLabel.string.size(withAttributes: [NSAttributedString.Key.font: messageLabel.font!]) : CGSize.zero
        if detailsLabelSize.width > 0.0 {
            detailsLabelSize.width += 10.0
        }
        detailsLabelSize.width = min(detailsLabelSize.width, maxWidth)
        totalSize.width = max(totalSize.width, detailsLabelSize.width)
        totalSize.height += detailsLabelSize.height
        if detailsLabelSize.height > 0.0 && (indicatorF.size.height > 0.0 || labelSize.height > 0.0) {
            totalSize.height += settings.padding
        }
        totalSize.width += settings.margin * 2
        totalSize.height += settings.margin * 2

        // Position elements
        var yPos = round((bounds.size.height - totalSize.height) / 2) + settings.margin - yOffset
        if labelSize.height > 0.0 && indicatorF.size.height > 0.0 {
            yPos += settings.padding + labelSize.height
        }
        if detailsLabelSize.height > 0.0 && (indicatorF.size.height > 0.0 || labelSize.height > 0.0) {
            yPos += settings.padding + detailsLabelSize.height
        }
        let xPos = xOffset
        indicatorF.origin.y = yPos
        indicatorF.origin.x = round((bounds.size.width - indicatorF.size.width) / 2) + xPos
        indicator?.frame = indicatorF

        if labelSize.height > 0.0 && indicatorF.size.height > 0.0 {
            yPos -= settings.padding + labelSize.height
        }
        if indicatorF.size.height > 0.0 {
            yPos -= settings.padding
        }
        var labelF = CGRect.zero
        labelF.origin.y = yPos
        labelF.origin.x = round((bounds.size.width - labelSize.width) / 2) + xPos
        labelF.size = labelSize
        titleLabel.frame = labelF

        if detailsLabelSize.height > 0.0 && (indicatorF.size.height > 0.0 || labelSize.height > 0.0) {
            yPos -= settings.padding + detailsLabelSize.height
        }
        var detailsLabelF = CGRect.zero
        detailsLabelF.origin.y = yPos
        detailsLabelF.origin.x = round((bounds.size.width - detailsLabelSize.width) / 2) + xPos
        detailsLabelF.size = detailsLabelSize
        messageLabel.frame = detailsLabelF

        // Enforce square rules
        if settings.square {
            let maximum = max(totalSize.width, totalSize.height)
            if maximum <= bounds.size.width - settings.margin * 2 {
                totalSize.width = maximum
            }
            if maximum <= bounds.size.height - settings.margin * 2 {
                totalSize.height = maximum
            }
        }
        size = totalSize
    }

    // MARK: - Background Drawing

    override func draw(_ rect: NSRect) {
        layoutSubviews()
        NSGraphicsContext.saveGraphicsState()
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        if settings.maskType == .gradient {
            // Gradient colours
            let gradLocationsNum: size_t = 2
            let gradLocations: [CGFloat] = [0.0, 1.0]
            let gradColors: [CGFloat] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.75]
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let gradient = CGGradient(colorSpace: colorSpace, colorComponents: gradColors, locations: gradLocations, count: gradLocationsNum)!
            // Gradient center
            let gradCenter = CGPoint(x: bounds.size.width / 2, y: bounds.size.height / 2)
            // Gradient radius
            let gradRadius = min(bounds.size.width, bounds.size.height)
            // Gradient draw
            context.drawRadialGradient(gradient, startCenter: gradCenter, startRadius: 0, endCenter: gradCenter, endRadius: gradRadius, options: CGGradientDrawingOptions.drawsAfterEndLocation)
        } else if settings.maskType == .black {
            context.setFillColor(NSColor.black.withAlphaComponent(0.6).cgColor)
            rect.fill()
        } else if settings.maskType == .custom {
            context.setFillColor(settings.customMaskTypeColor.cgColor)
            rect.fill()
        }

        // Set background rect color
        context.setFillColor(backgroundColor.withAlphaComponent(settings.opacity).cgColor)

        // Center HUD
        let allRect = bounds

        // Draw rounded HUD backgroud rect
        let boxRect = CGRect(x: round((allRect.size.width - size.width) / 2) + xOffset,
                             y: round((allRect.size.height - size.height) / 2) - yOffset,
                             width: size.width, height: size.height)
        let radius = settings.cornerRadius
        context.beginPath()
        context.move(to: CGPoint(x: boxRect.minX + radius, y: boxRect.minY))
        context.addArc(center: CGPoint(x: boxRect.maxX - radius, y: boxRect.minY + radius), radius: radius, startAngle: .pi * 3 / 2, endAngle: 0, clockwise: false)
        context.addArc(center: CGPoint(x: boxRect.maxX - radius, y: boxRect.maxY - radius), radius: radius, startAngle: 0, endAngle: .pi / 2, clockwise: false)
        context.addArc(center: CGPoint(x: boxRect.minX + radius, y: boxRect.maxY - radius), radius: radius, startAngle: .pi / 2, endAngle: .pi, clockwise: false)
        context.addArc(center: CGPoint(x: boxRect.minX + radius, y: boxRect.minY + radius), radius: radius, startAngle: .pi, endAngle: .pi * 3 / 2, clockwise: false)
        context.closePath()
        context.fillPath()

        if settings.mode == .determinate {
            // Draw progress
            let lineWidth: CGFloat = 5.0
            let processBackgroundPath = NSBezierPath()
            processBackgroundPath.lineWidth = lineWidth
            processBackgroundPath.lineCapStyle = .round

            let center = CGPoint(x: boxRect.origin.x + boxRect.size.width / 2, y: boxRect.origin.y + boxRect.size.height - settings.spinsize * 0.9)
            let radius = settings.spinsize / 2
            let startAngle: CGFloat = 90
            var endAngle = startAngle - 360 * CGFloat(progress)
            processBackgroundPath.appendArc(withCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
            context.setStrokeColor(tintColor.cgColor)
            processBackgroundPath.stroke()
            let processPath = NSBezierPath()
            processPath.lineCapStyle = .round
            processPath.lineWidth = lineWidth
            endAngle = startAngle - .pi * 2
            processPath.appendArc(withCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
            context.setFillColor(tintColor.cgColor)
            processPath.stroke()
        }

        NSGraphicsContext.restoreGraphicsState()
    }

}

private class ProgressIndicatorLayer: CALayer {

    private(set) var isRunning = false

    private var color: NSColor

    private var finBoundsForCurrentBounds: CGRect {
        let size: CGSize = bounds.size
        let minSide: CGFloat = size.width > size.height ? size.height : size.width
        let width: CGFloat = minSide * 0.095
        let height: CGFloat = minSide * 0.30
        return CGRect(x: 0, y: 0, width: width, height: height)
    }

    private var finAnchorPointForCurrentBounds: CGPoint {
        let size: CGSize = bounds.size
        let minSide: CGFloat = size.width > size.height ? size.height : size.width
        let height: CGFloat = minSide * 0.30
        return CGPoint(x: 0.5, y: -0.9 * (minSide - height) / minSide)
    }

    private var animationTimer: Timer?
    private var fposition = 0
    private var fadeDownOpacity: CGFloat = 0.0
    private var numFins = 12
    private var finLayers = [CALayer]()

    init(size: CGFloat, color: NSColor) {
        self.color = color
        super.init()
        bounds = CGRect(x: -(size / 2), y: -(size / 2), width: size, height: size)
        createFinLayers()
        if isRunning {
            setupAnimTimer()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        stopProgressAnimation()
        removeFinLayers()
    }

    func toggleProgressAnimation() {
        if isRunning {
            stopProgressAnimation()
        } else {
            startProgressAnimation()
        }
    }

    func startProgressAnimation() {
        isHidden = false
        isRunning = true
        fposition = numFins - 1
        setNeedsDisplay()
        setupAnimTimer()
    }

    func stopProgressAnimation() {
        isRunning = false
        disposeAnimTimer()
        setNeedsDisplay()
    }

    // Animation
    @objc private func advancePosition() {
        fposition += 1
        if fposition >= numFins {
            fposition = 0
        }
        let fin = finLayers[fposition]
        // Set the next fin to full opacity, but do it immediately, without any animation
        CATransaction.begin()
        CATransaction.setValue(true, forKey: kCATransactionDisableActions)
        fin.opacity = 1.0
        CATransaction.commit()
        // Tell that fin to animate its opacity to transparent.
        fin.opacity = Float(fadeDownOpacity)
        setNeedsDisplay()
    }

    private func removeFinLayers() {
        for finLayer in finLayers {
            finLayer.removeFromSuperlayer()
        }
    }

    private func createFinLayers() {
        removeFinLayers()
        // Create new fin layers
        let finBounds: CGRect = finBoundsForCurrentBounds
        let finAnchorPoint: CGPoint = finAnchorPointForCurrentBounds
        let finPosition = CGPoint(x: bounds.size.width / 2, y: bounds.size.height / 2)
        let finCornerRadius: CGFloat = finBounds.size.width / 2
        for i in 0..<numFins {
            let newFin = CALayer()
            newFin.bounds = finBounds
            newFin.anchorPoint = finAnchorPoint
            newFin.position = finPosition
            newFin.transform = CATransform3DMakeRotation(CGFloat(i) * (-6.282185 / CGFloat(numFins)), 0.0, 0.0, 1.0)
            newFin.cornerRadius = finCornerRadius
            newFin.backgroundColor = color.cgColor
            // Set the fin's initial opacity
            CATransaction.begin()
            CATransaction.setValue(true, forKey: kCATransactionDisableActions)
            newFin.opacity = Float(fadeDownOpacity)
            CATransaction.commit()
            // set the fin's fade-out time (for when it's animating)
            let anim = CABasicAnimation()
            anim.duration = 0.7
            let actions = ["opacity": anim]
            newFin.actions = actions
            addSublayer(newFin)
            finLayers.append(newFin)
        }
    }

    private func setupAnimTimer() {
        // Just to be safe kill any existing timer.
        disposeAnimTimer()
        // Why animate if not visible?  viewDidMoveToWindow will re-call this method when needed.
        animationTimer = Timer(timeInterval: TimeInterval(0.05), target: self, selector: #selector(ProgressIndicatorLayer.advancePosition), userInfo: nil, repeats: true)
        animationTimer?.fireDate = Date()
        if let aTimer = animationTimer {
            RunLoop.current.add(aTimer, forMode: .common)
        }
        if let aTimer = animationTimer {
            RunLoop.current.add(aTimer, forMode: .default)
        }
        if let aTimer = animationTimer {
            RunLoop.current.add(aTimer, forMode: .eventTracking)
        }
    }

    private func disposeAnimTimer() {
        animationTimer?.invalidate()
        animationTimer = nil
    }

    override var bounds: CGRect {
        get {
            return super.bounds
        }
        set(newBounds) {
            super.bounds = newBounds

            // Resize the fins
            let finBounds: CGRect = finBoundsForCurrentBounds
            let finAnchorPoint: CGPoint = finAnchorPointForCurrentBounds
            let finPosition = CGPoint(x: bounds.size.width / 2, y: bounds.size.height / 2)
            let finCornerRadius: CGFloat = finBounds.size.width / 2

            // do the resizing all at once, immediately
            CATransaction.begin()
            CATransaction.setValue(true, forKey: kCATransactionDisableActions)
            for fin in finLayers {
                fin.bounds = finBounds
                fin.anchorPoint = finAnchorPoint
                fin.position = finPosition
                fin.cornerRadius = finCornerRadius
            }
            CATransaction.commit()
        }
    }

}
