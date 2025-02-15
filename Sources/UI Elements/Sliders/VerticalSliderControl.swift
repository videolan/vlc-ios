/*****************************************************************************
 * VerticalSliderControl.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2025 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Craig Reyenga <craig.reyenga # gmail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

/// A `UISlider` workalike that is vertical instead of horizontal.
///
/// Not all of the functionality of the former is available here. The API is
/// also not exactly the same for the functionality that _is_ present here.
class VerticalSliderControl: UIControl {
    private static let defaultMaximumTrackLayerColor = UIColor(white: 1, alpha: 0.5)
    private static let defaultMinimumTrackLayerColor = UIColor.white
    private static let defaultAnimationDuration: TimeInterval = 0.1
    private static let defaultImageInsets = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
    private static let defaultIntrinsicSize = CGSize(width: defaultThumbSideLength, height: 200)
    private static let defaultThumbSideLength = CGFloat(31) // UISlider has a private default height of 31 pixels
    private static let thumbTolerance = CGFloat(10)
    private static let defaultTrackWidth: CGFloat = 8
    private static let accessibilityIncrement: Float = 0.1 // consider making this configurable via a setter

    private(set) var value: Float = 0 {
        didSet {
            setNeedsLayout()
            updateSublayers()
        }
    }

    func setValue(_ value: Float, animated: Bool) {
        if animated {
            UIView.animate(withDuration: animationDuration) {
                self.value = value
            }
        } else {
            self.value = value
        }
    }

    private func updateValueAndNotify(_ value: Float) {
        self.value = value
        sendActions(for: .valueChanged)
    }

    /// the value range of the slider
    var range: ClosedRange<Float> = 0...1

    /// the minimum value of the slider's range
    var minimumValue: Float {
        range.lowerBound
    }

    /// the maximum value of the slider's range
    var maximumValue: Float {
        range.upperBound
    }

    /// A representation of the current value normalized to the range
    /// [0...1].
    var percentage: Float {
        let dist = range.upperBound - range.lowerBound
        let adjustedValue = value - range.lowerBound
        return (adjustedValue / dist)
    }

    var animationDuration: TimeInterval = defaultAnimationDuration {
        willSet {
            precondition(newValue > 0, "Animation duration must be greater than zero.")
        }
    }

    /// nil - default thumb (31 pixel white circle)
    ///
    /// non-empty UIImage - custom thumb
    ///
    /// empty UIImage() - no thumb at all
    var thumbImage: UIImage? {
        get {
            thumbImageView.image
        }
        set {
            if let newValue = newValue {
                thumbImageView.image = newValue
            } else {
                thumbImageView.image = .circle(diameter: Self.defaultThumbSideLength,
                                               color: .white)
            }
        }
    }

    /// an image to show on the minimum of the slider, i.e. the bottom
    var minimumValueImage: UIImage? {
        didSet {
            minimumValueImageView.image = minimumValueImage
        }
    }

    var minimumValueInsets: UIEdgeInsets = defaultImageInsets {
        didSet {
            setNeedsUpdateConstraints()
        }
    }

    var minimumTrackLayerColor: CGColor? {
        get {
            minimumTrackLayer.backgroundColor
        }
        set {
            minimumTrackLayer.backgroundColor = newValue
        }
    }

    /// an image to show on the maximum of the slider, i.e. the top
    var maximumValueImage: UIImage? {
        didSet {
            maximumValueImageView.image = maximumValueImage
        }
    }

    var maximumValueInsets: UIEdgeInsets = defaultImageInsets {
        didSet {
            setNeedsUpdateConstraints()
        }
    }

    var maximumTrackLayerColor: CGColor? {
        get {
            maximumTrackLayer.backgroundColor
        }
        set {
            maximumTrackLayer.backgroundColor = newValue
        }
    }

    private lazy var minimumValueImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private lazy var maximumValueImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private lazy var thumbImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init() {
        super.init(frame: .zero)

        setup()
    }

    private lazy var panGestureRecognizer: UIPanGestureRecognizer = {
        let gestureRecognizer = UIPanGestureRecognizer(target: self,
                                                       action: #selector(handlePanGestureRecognizer(sender:)))
        return gestureRecognizer
    }()

    private var maxImageSpace: CGFloat {
        maximumValueImageView.intrinsicContentSize.height + maximumValueInsets.top + maximumValueInsets.bottom
    }

    private var minImageSpace: CGFloat {
        minimumValueImageView.intrinsicContentSize.height + minimumValueInsets.top + minimumValueInsets.bottom
    }

    private var trackLayerHeight: CGFloat {
        bounds.height - (maxImageSpace + minImageSpace)
    }

    /// relative to the top of the track, not the top of the view
    private var trackThresholdY: CGFloat {
        let v = lerp(from: trackLayerHeight - thumbHeight / 2,
                     to: thumbHeight / 2,
                     t: CGFloat(percentage))

        // The native control has special logic where if there is no visible
        // thumb, the track snaps at the extremes.

        if thumbImage?.size.isEmpty ?? false {
            if percentage <= 0 {
                return trackLayerHeight

            } else if percentage >= 1 {
                return 0

            }
        }

        return v
    }

    private var thumbHeight: CGFloat {
        thumbImageView.image?.size.height ?? Self.defaultThumbSideLength
    }

    private var thumbWidth: CGFloat {
        thumbImageView.image?.size.width ?? Self.defaultThumbSideLength
    }

    /// relative to the top of the track, not the top of the view
    private var thumbY: CGFloat {
        return lerp(from: trackLayerHeight - thumbHeight,
                    to: 0,
                    t: CGFloat(percentage))
    }

    private var thumbRect: CGRect {
        return CGRect(x: (bounds.width - thumbWidth) / 2,
                      y: maxImageSpace + thumbY,
                      width: min(bounds.width, max(trackWidth, thumbWidth)),
                      height: thumbHeight)
    }

    private var panInfo: PanInfo?
    private var isPanning: Bool {
        panInfo != nil
    }

    private var maxTopConstraint: NSLayoutConstraint!
    private var maxLeadingConstraint: NSLayoutConstraint!
    private var maxTrailingConstraint: NSLayoutConstraint!

    private var minBottomConstraint: NSLayoutConstraint!
    private var minLeadingConstraint: NSLayoutConstraint!
    private var minTrailingConstraint: NSLayoutConstraint!

    private func setup() {
        // - gestures
        addGestureRecognizer(panGestureRecognizer)

        // - subviews

        layer.addSublayer(trackLayer)
        trackLayer.addSublayer(minimumTrackLayer)
        trackLayer.addSublayer(maximumTrackLayer)

        addSubview(minimumValueImageView)
        minimumValueImageView.translatesAutoresizingMaskIntoConstraints = false

        maxTopConstraint = maximumValueImageView.topAnchor.constraint(equalTo: topAnchor)
        maxLeadingConstraint = maximumValueImageView.leadingAnchor.constraint(equalTo: leadingAnchor)
        maxTrailingConstraint = maximumValueImageView.trailingAnchor.constraint(equalTo: trailingAnchor)

        addSubview(maximumValueImageView)
        maximumValueImageView.translatesAutoresizingMaskIntoConstraints = false

        minBottomConstraint = minimumValueImageView.bottomAnchor.constraint(equalTo: bottomAnchor)
        minLeadingConstraint = minimumValueImageView.leadingAnchor.constraint(equalTo: leadingAnchor)
        minTrailingConstraint = minimumValueImageView.trailingAnchor.constraint(equalTo: trailingAnchor)

        NSLayoutConstraint.activate([
            maxTopConstraint,
            maxLeadingConstraint,
            maxTrailingConstraint,

            minBottomConstraint,
            minLeadingConstraint,
            minTrailingConstraint
        ])

        addSubview(thumbImageView) // laid out manually elsewhere

        // - accessibility
        isAccessibilityElement = true
        // the owner can and should customize accessibilityLabel
        accessibilityLabel = NSLocalizedString("VERTICAL_SLIDER_CONTROL_ACCESSIBILITY_LABEL", comment: "")

        // We avoid using `adjustable` here. We have our own increment and
        // decrement actions; we don't need the system to add its own.
        accessibilityTraits = []

        let increment = UIAccessibilityCustomAction
            .create(name: NSLocalizedString("VERTICAL_SLIDER_CONTROL_INCREMENT_ACTION", comment: ""),
                    image: .with(systemName: "arrow.up"),
                    target: self,
                    selector: #selector(handleAccessibilityIncrement))

        let decrement = UIAccessibilityCustomAction
            .create(name: NSLocalizedString("VERTICAL_SLIDER_CONTROL_DECREMENT_ACTION", comment: ""),
                    image: .with(systemName: "arrow.down"),
                    target: self,
                    selector: #selector(handleAccessibilityDecrement))

        accessibilityCustomActions = [increment, decrement]
    }

    private let trackLayer: CALayer = {
        let layer = CALayer()
        layer.masksToBounds = true
        layer.backgroundColor = UIColor.clear.cgColor
        return layer
    }()

    private let minimumTrackLayer: CALayer = {
        let layer = CALayer()
        layer.masksToBounds = true
        layer.backgroundColor = defaultMinimumTrackLayerColor.cgColor
        return layer
    }()

    private let maximumTrackLayer: CALayer = {
        let layer = CALayer()
        layer.masksToBounds = true
        layer.backgroundColor = defaultMaximumTrackLayerColor.cgColor
        return layer
    }()

    var trackWidth: CGFloat = defaultTrackWidth {
        didSet {
            setNeedsLayout()
        }
    }

    override var intrinsicContentSize: CGSize {
        let w = max(
            Self.defaultIntrinsicSize.width,
            trackWidth,
            maximumValueImageView.intrinsicContentSize.width + maximumValueInsets.left + maximumValueInsets.right,
            minimumValueImageView.intrinsicContentSize.width + minimumValueInsets.left + minimumValueInsets.right
        )

        return CGSize(width: w, height: Self.defaultIntrinsicSize.height)
    }

    override func updateConstraints() {
        maxTopConstraint.constant = maximumValueInsets.top
        maxLeadingConstraint.constant = maximumValueInsets.left
        maxTrailingConstraint.constant = -maximumValueInsets.right

        minBottomConstraint.constant = -minimumValueInsets.bottom
        minLeadingConstraint.constant = minimumValueInsets.left
        minTrailingConstraint.constant = -minimumValueInsets.right

        super.updateConstraints()
    }

    private func updateSublayers() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)

        let trackLayerFrame = CGRect(x: (bounds.width - trackWidth) / 2,
                                     y: maxImageSpace,
                                     width: trackWidth,
                                     height: trackLayerHeight)

        trackLayer.frame = trackLayerFrame
        trackLayer.cornerRadius = trackWidth / 2

        let maximumTrackLayerFrame = CGRect(
            origin: .zero,
            size: CGSize(width: trackWidth, height: trackThresholdY)
        )
        maximumTrackLayer.frame = maximumTrackLayerFrame

        let minimumTrackLayerFrame = CGRect(
            origin: CGPoint(x: 0, y: trackThresholdY),
            size: CGSize(width: trackWidth, height: trackLayerHeight - trackThresholdY)
        )
        minimumTrackLayer.frame = minimumTrackLayerFrame

        CATransaction.commit()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        thumbImageView.frame = thumbRect

        updateSublayers()
    }

    @objc private func handlePanGestureRecognizer(sender: UIPanGestureRecognizer) {
        let y = sender.location(in: self).y

        let radius = max(Self.defaultThumbSideLength, thumbHeight) / 2 + Self.thumbTolerance
        let minY = maxImageSpace + trackThresholdY - radius
        let maxY = maxImageSpace + trackThresholdY + radius

        switch sender.state {
        case .began:
            guard (minY...maxY).contains(y) else {
                sender.state = .cancelled
                return
            }

            panInfo = PanInfo(y: y, percentage: percentage)

        case .changed:
            guard isPanning else {
                sender.state = .cancelled
                return
            }

            handlePan(y: y)

        case .ended:
            guard isPanning else {
                sender.state = .cancelled
                return
            }

            self.panInfo = nil
            handlePan(y: y)

        case .possible, .cancelled, .failed:
            panInfo = nil

        @unknown default:
            break
        }
    }

    private func handlePan(y: CGFloat) {
        guard let panInfo = panInfo else {
            return
        }

        let dy = y - panInfo.y
        let addPercent = -dy / trackLayerHeight
        let newPercent = min(max(0, CGFloat(panInfo.percentage) + addPercent), 1)
        let newValue = range.lowerBound + Float(newPercent) * (range.upperBound - range.lowerBound)

        updateValueAndNotify(newValue)
    }

    @objc private func handleAccessibilityIncrement() -> Bool {
        let newPct = min(1, percentage + Self.accessibilityIncrement)
        let newVal = lerp(from: range.lowerBound, to: range.upperBound, t: newPct)
        setValue(newVal, animated: true)
        return true
    }

    @objc private func handleAccessibilityDecrement() -> Bool {
        let newPct = max(0, percentage - Self.accessibilityIncrement)
        let newVal = lerp(from: range.lowerBound, to: range.upperBound, t: newPct)
        setValue(newVal, animated: true)
        return true
    }
}

// MARK: - DemoViewController
/// Demonstrates the use of the vertical slider control.
/// A native slider is also displayed; adjusting one should adjust the other
/// automatically.
///
/// Requires iOS 13
@available(iOS 13.0, *)
class VerticalSliderControl_DemoViewController: UIViewController {
    private let slider: VerticalSliderControl = {
        let slider = VerticalSliderControl()
        slider.translatesAutoresizingMaskIntoConstraints = false
        return slider
    }()

    private let sdkSlider: UISlider = {
        let slider = UISlider()
        slider.translatesAutoresizingMaskIntoConstraints = false
        return slider
    }()

    private let label: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground

        slider.backgroundColor = .systemBlue
        slider.maximumValueImage = UIImage(systemName: "arrow.up.circle")?
            .withTintColor(.black, renderingMode: .alwaysOriginal)
        slider.minimumValueImage = UIImage(systemName: "arrow.down.circle")?
            .withTintColor(.black, renderingMode: .alwaysOriginal)
        slider.minimumValueInsets = UIEdgeInsets(top: 7, left: 2, bottom: 7, right: 2)
        slider.maximumValueInsets = UIEdgeInsets(top: 7, left: 2, bottom: 7, right: 2)

        slider.thumbImage = UIImage(systemName: "circle.fill")?
            .withTintColor(.black.withAlphaComponent(0.3), renderingMode: .alwaysOriginal)

        sdkSlider.backgroundColor = .systemGreen
        sdkSlider.maximumValueImage = UIImage(systemName: "arrow.up.circle")
        sdkSlider.minimumValueImage = UIImage(systemName: "arrow.down.circle")
        let thumb = UIImage(systemName: "circle.fill")?
            .withTintColor(.black.withAlphaComponent(0.3), renderingMode: .alwaysOriginal)
        sdkSlider.setThumbImage(thumb, for: [])

        view.addSubview(slider)
        view.addSubview(sdkSlider)
        view.addSubview(label)
        NSLayoutConstraint.activate([
            slider.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            slider.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            sdkSlider.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            sdkSlider.widthAnchor.constraint(equalToConstant: 200),
            sdkSlider.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -40),

            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.topAnchor.constraint(equalTo: slider.bottomAnchor, constant: 20)

        ])

        slider.addTarget(self, action: #selector(sliderDidChange), for: .valueChanged)
        sdkSlider.addTarget(self, action: #selector(sdkSliderDidChange), for: .valueChanged)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        sdkSlider.value = 0.375
        sdkSlider.sendActions(for: .valueChanged)
    }

    @objc func sliderDidChange() {
        let value = slider.value
        sdkSlider.value = value
        updateLabel()
    }

    @objc func sdkSliderDidChange() {
        let value = sdkSlider.value
        slider.setValue(value, animated: false)
        updateLabel()
    }

    func updateLabel() {
        label.text = String(format: "%.3f", slider.value)
    }
}

fileprivate struct PanInfo: Equatable {
    let y: CGFloat
    let percentage: Float
}

fileprivate func lerp<T: FloatingPoint>(from a: T, to b: T, t: T) -> T {
    return a + (b - a) * t
}

fileprivate extension CGSize {
    var isEmpty: Bool {
        width.isNaN || height.isNaN || width == 0 || height == 0
    }
}

fileprivate extension UIImage {
    class func circle(diameter: CGFloat, color: UIColor) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(CGSize(width: diameter, height: diameter), false, 0)
        guard let ctx = UIGraphicsGetCurrentContext() else { return nil }
        ctx.saveGState()

        let rect = CGRect(x: 0, y: 0, width: diameter, height: diameter)
        ctx.setFillColor(color.cgColor)
        ctx.fillEllipse(in: rect)

        ctx.restoreGState()
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return img
    }
}
