import Foundation
import UIKit
import Display
import AsyncDisplayKit
import ComponentFlow
import SwiftSignalKit
import AnimationUI

public final class MultilineText: Component {
    public let text: String
    public let font: UIFont
    public let color: UIColor

    public init(
        text: String,
        font: UIFont,
        color: UIColor
    ) {
        self.text = text
        self.font = font
        self.color = color
    }

    public static func ==(lhs: MultilineText, rhs: MultilineText) -> Bool {
        if lhs.text != rhs.text {
            return false
        }
        if lhs.font != rhs.font {
            return false
        }
        if lhs.color != rhs.color {
            return false
        }
        return true
    }

    public final class View: UIView {
        private let text: ImmediateTextNode

        init() {
            self.text = ImmediateTextNode()
            self.text.maximumNumberOfLines = 0

            super.init(frame: CGRect())

            self.addSubnode(self.text)
        }

        required init?(coder aDecoder: NSCoder) {
            preconditionFailure()
        }

        func update(component: MultilineText, availableSize: CGSize, environment: Environment<Empty>, transition: Transition) -> CGSize {
            self.text.attributedText = NSAttributedString(string: component.text, font: component.font, textColor: component.color, paragraphAlignment: nil)
            let textSize = self.text.updateLayout(availableSize)
            transition.setFrame(view: self.text.view, frame: CGRect(origin: CGPoint(), size: textSize))

            return textSize
        }
    }

    public func makeView() -> View {
        return View()
    }

    public func update(view: View, availableSize: CGSize, environment: Environment<Empty>, transition: Transition) -> CGSize {
        return view.update(component: self, availableSize: availableSize, environment: environment, transition: transition)
    }
}

public final class LottieAnimationComponent: Component {
    public let name: String

    public init(
        name: String
    ) {
        self.name = name
    }

    public static func ==(lhs: LottieAnimationComponent, rhs: LottieAnimationComponent) -> Bool {
        if lhs.name != rhs.name {
            return false
        }
        return true
    }

    public final class View: UIView {
        private var animationNode: AnimationNode?
        private var currentName: String?

        init() {
            super.init(frame: CGRect())
        }

        required init?(coder aDecoder: NSCoder) {
            preconditionFailure()
        }

        func update(component: LottieAnimationComponent, availableSize: CGSize, environment: Environment<Empty>, transition: Transition) -> CGSize {
            if self.currentName != component.name {
                self.currentName = component.name

                if let animationNode = self.animationNode {
                    animationNode.removeFromSupernode()
                    self.animationNode = nil
                }

                let animationNode = AnimationNode(animation: component.name, colors: [:], scale: 1.0)
                self.animationNode = animationNode
                self.addSubnode(animationNode)

                animationNode.play()
            }

            if let animationNode = self.animationNode {
                let preferredSize = animationNode.preferredSize()
                return preferredSize ?? CGSize(width: 32.0, height: 32.0)
            } else {
                return CGSize()
            }
        }
    }

    public func makeView() -> View {
        return View()
    }

    public func update(view: View, availableSize: CGSize, environment: Environment<Empty>, transition: Transition) -> CGSize {
        return view.update(component: self, availableSize: availableSize, environment: environment, transition: transition)
    }
}

public final class TooltipComponent: Component {
    public let icon: AnyComponent<Empty>?
    public let content: AnyComponent<Empty>
    public let arrowLocation: CGRect

    public init(
        icon: AnyComponent<Empty>?,
        content: AnyComponent<Empty>,
        arrowLocation: CGRect
    ) {
        self.icon = icon
        self.content = content
        self.arrowLocation = arrowLocation
    }

    public static func ==(lhs: TooltipComponent, rhs: TooltipComponent) -> Bool {
        if lhs.icon != rhs.icon {
            return false
        }
        if lhs.content != rhs.content {
            return false
        }
        if lhs.arrowLocation != rhs.arrowLocation {
            return false
        }
        return true
    }

    public final class View: UIView {
        private let backgroundNode: NavigationBackgroundNode
        private var icon: ComponentHostView<Empty>?
        private let content: ComponentHostView<Empty>

        init() {
            self.backgroundNode = NavigationBackgroundNode(color: UIColor(white: 0.2, alpha: 0.7))
            self.content = ComponentHostView<Empty>()

            super.init(frame: CGRect())

            self.addSubnode(self.backgroundNode)
            self.addSubview(self.content)
        }

        required init?(coder aDecoder: NSCoder) {
            preconditionFailure()
        }

        func update(component: TooltipComponent, availableSize: CGSize, environment: Environment<Empty>, transition: Transition) -> CGSize {
            let insets = UIEdgeInsets(top: 8.0, left: 8.0, bottom: 8.0, right: 8.0)
            let spacing: CGFloat = 8.0

            var iconSize: CGSize?
            if let icon = component.icon {
                let iconView: ComponentHostView<Empty>
                if let current = self.icon {
                    iconView = current
                } else {
                    iconView = ComponentHostView<Empty>()
                    self.icon = iconView
                    self.addSubview(iconView)
                }
                iconSize = iconView.update(
                    transition: transition,
                    component: icon,
                    environment: {},
                    containerSize: availableSize
                )
            } else if let icon = self.icon {
                self.icon = nil
                icon.removeFromSuperview()
            }

            var contentLeftInset: CGFloat = 0.0
            if let iconSize = iconSize {
                contentLeftInset += iconSize.width + spacing
            }

            let contentSize = self.content.update(
                transition: transition,
                component: component.content,
                environment: {},
                containerSize: CGSize(width: min(200.0, availableSize.width - contentLeftInset), height: availableSize.height)
            )

            var innerContentHeight = contentSize.height
            if let iconSize = iconSize, iconSize.height > innerContentHeight {
                innerContentHeight = iconSize.height
            }

            let combinedContentSize = CGSize(width: insets.left + insets.right + contentLeftInset + contentSize.width, height: insets.top + insets.bottom + innerContentHeight)
            var contentRect = CGRect(origin: CGPoint(x: component.arrowLocation.minX - combinedContentSize.width, y: component.arrowLocation.maxY), size: combinedContentSize)
            if contentRect.minX < 0.0 {
                contentRect.origin.x = component.arrowLocation.maxX
            }
            if contentRect.minY < 0.0 {
                contentRect.origin.y = component.arrowLocation.minY - contentRect.height
            }

            transition.setFrame(view: self.backgroundNode.view, frame: contentRect)
            self.backgroundNode.update(size: contentRect.size, cornerRadius: 8.0, transition: .immediate)

            if let iconSize = iconSize, let icon = self.icon {
                transition.setFrame(view: icon, frame: CGRect(origin: CGPoint(x: contentRect.minX + insets.left, y: contentRect.minY + insets.top + floor((contentRect.height - insets.top - insets.bottom - iconSize.height) / 2.0)), size: iconSize))
            }
            transition.setFrame(view: self.content, frame: CGRect(origin: CGPoint(x: contentRect.minX + insets.left + contentLeftInset, y: contentRect.minY + insets.top + floor((contentRect.height - insets.top - insets.bottom - contentSize.height) / 2.0)), size: contentSize))

            return availableSize
        }
    }

    public func makeView() -> View {
        return View()
    }

    public func update(view: View, availableSize: CGSize, environment: Environment<Empty>, transition: Transition) -> CGSize {
        return view.update(component: self, availableSize: availableSize, environment: environment, transition: transition)
    }
}

private final class RoundedRectangle: Component {
    let color: UIColor

    init(color: UIColor) {
        self.color = color
    }

    static func ==(lhs: RoundedRectangle, rhs: RoundedRectangle) -> Bool {
        if !lhs.color.isEqual(rhs.color) {
            return false
        }
        return true
    }

    final class View: UIView {
        private let backgroundView: UIImageView

        private var currentColor: UIColor?
        private var currentDiameter: CGFloat?

        init() {
            self.backgroundView = UIImageView()

            super.init(frame: CGRect())

            self.addSubview(self.backgroundView)
        }

        required init?(coder aDecoder: NSCoder) {
            preconditionFailure()
        }

        func update(component: RoundedRectangle, availableSize: CGSize, environment: Environment<Empty>, transition: Transition) -> CGSize {
            let shadowInset: CGFloat = 0.0
            let diameter = min(availableSize.width, availableSize.height)

            var updated = false
            if let currentColor = self.currentColor {
                if !component.color.isEqual(currentColor) {
                    updated = true
                }
            } else {
                updated = true
            }

            let diameterUpdated = self.currentDiameter != diameter
            if self.currentDiameter != diameter || updated {
                self.currentDiameter = diameter
                self.currentColor = component.color

                self.backgroundView.image = generateImage(CGSize(width: diameter + shadowInset * 2.0, height: diameter + shadowInset * 2.0), rotatedContext: { size, context in
                    context.clear(CGRect(origin: CGPoint(), size: size))

                    context.setFillColor(component.color.cgColor)

                    context.fillEllipse(in: CGRect(origin: CGPoint(x: shadowInset, y: shadowInset), size: CGSize(width: size.width - shadowInset * 2.0, height: size.height - shadowInset * 2.0)))
                })?.stretchableImage(withLeftCapWidth: Int(diameter + shadowInset * 2.0) / 2, topCapHeight: Int(diameter + shadowInset * 2.0) / 2)
            }

            transition.setFrame(view: self.backgroundView, frame: CGRect(origin: CGPoint(x: -shadowInset, y: -shadowInset), size: CGSize(width: availableSize.width + shadowInset * 2.0, height: availableSize.height + shadowInset * 2.0)))

            let _ = diameterUpdated

            return availableSize
        }
    }

    func makeView() -> View {
        return View()
    }

    func update(view: View, availableSize: CGSize, environment: Environment<Empty>, transition: Transition) -> CGSize {
        return view.update(component: self, availableSize: availableSize, environment: environment, transition: transition)
    }
}

private final class ShadowRoundedRectangle: Component {
    let color: UIColor

    init(color: UIColor) {
        self.color = color
    }

    static func ==(lhs: ShadowRoundedRectangle, rhs: ShadowRoundedRectangle) -> Bool {
        if !lhs.color.isEqual(rhs.color) {
            return false
        }
        return true
    }

    final class View: UIView {
        private let backgroundView: UIImageView

        private var currentColor: UIColor?
        private var currentDiameter: CGFloat?

        init() {
            self.backgroundView = UIImageView()

            super.init(frame: CGRect())

            self.addSubview(self.backgroundView)
        }

        required init?(coder aDecoder: NSCoder) {
            preconditionFailure()
        }

        func update(component: ShadowRoundedRectangle, availableSize: CGSize, environment: Environment<Empty>, transition: Transition) -> CGSize {
            let shadowInset: CGFloat = 10.0
            let diameter = min(availableSize.width, availableSize.height)

            var updated = false
            if let currentColor = self.currentColor {
                if !component.color.isEqual(currentColor) {
                    updated = true
                }
            } else {
                updated = true
            }

            if self.currentDiameter != diameter || updated {
                self.currentDiameter = diameter
                self.currentColor = component.color

                self.backgroundView.image = generateImage(CGSize(width: diameter + shadowInset * 2.0, height: diameter + shadowInset * 2.0), rotatedContext: { size, context in
                    context.clear(CGRect(origin: CGPoint(), size: size))

                    context.setFillColor(component.color.cgColor)
                    context.setShadow(offset: CGSize(width: 0.0, height: -2.0), blur: 5.0, color: UIColor(white: 0.0, alpha: 0.3).cgColor)

                    context.fillEllipse(in: CGRect(origin: CGPoint(x: shadowInset, y: shadowInset), size: CGSize(width: size.width - shadowInset * 2.0, height: size.height - shadowInset * 2.0)))
                })?.stretchableImage(withLeftCapWidth: Int(diameter + shadowInset * 2.0) / 2, topCapHeight: Int(diameter + shadowInset * 2.0) / 2)
            }

            transition.setFrame(view: self.backgroundView, frame: CGRect(origin: CGPoint(x: -shadowInset, y: -shadowInset), size: CGSize(width: availableSize.width + shadowInset * 2.0, height: availableSize.height + shadowInset * 2.0)))

            return availableSize
        }
    }

    func makeView() -> View {
        return View()
    }

    func update(view: View, availableSize: CGSize, environment: Environment<Empty>, transition: Transition) -> CGSize {
        return view.update(component: self, availableSize: availableSize, environment: environment, transition: transition)
    }
}

private final class SparseItemGridScrollingIndicatorComponent: CombinedComponent {
    let backgroundColor: UIColor
    let shadowColor: UIColor
    let foregroundColor: UIColor
    let dateString: String

    init(
        backgroundColor: UIColor,
        shadowColor: UIColor,
        foregroundColor: UIColor,
        dateString: String
    ) {
        self.backgroundColor = backgroundColor
        self.shadowColor = shadowColor
        self.foregroundColor = foregroundColor
        self.dateString = dateString
    }

    static func ==(lhs: SparseItemGridScrollingIndicatorComponent, rhs: SparseItemGridScrollingIndicatorComponent) -> Bool {
        if lhs.backgroundColor != rhs.backgroundColor {
            return false
        }
        if lhs.shadowColor != rhs.shadowColor {
            return false
        }
        if lhs.foregroundColor != rhs.foregroundColor {
            return false
        }
        if lhs.dateString != rhs.dateString {
            return false
        }
        return true
    }

    static var body: Body {
        let rect = Child(ShadowRoundedRectangle.self)
        let text = Child(Text.self)

        return { context in
            let text = text.update(
                component: Text(
                    text: context.component.dateString,
                    font: Font.medium(13.0),
                    color: .black
                ),
                availableSize: CGSize(width: 200.0, height: 100.0),
                transition: .immediate
            )

            let rect = rect.update(
                component: ShadowRoundedRectangle(
                    color: .white
                ),
                availableSize: CGSize(width: text.size.width + 26.0, height: 32.0),
                transition: .immediate
            )

            let rectFrame = rect.size.centered(around: CGPoint(
                x: rect.size.width / 2.0,
                y: rect.size.height / 2.0
            ))

            context.add(rect
                .position(CGPoint(x: rectFrame.midX, y: rectFrame.midY))
            )

            let textFrame = text.size.centered(in: rectFrame)
            context.add(text
                .position(CGPoint(x: textFrame.midX, y: textFrame.midY))
            )

            return rect.size
        }
    }
}

public final class SparseItemGridScrollingArea: ASDisplayNode {
    private final class DragGesture: UIGestureRecognizer {
        private let shouldBegin: (CGPoint) -> Bool
        private let began: () -> Void
        private let ended: () -> Void
        private let moved: (CGFloat) -> Void

        private var initialLocation: CGPoint?

        public init(
            shouldBegin: @escaping (CGPoint) -> Bool,
            began: @escaping () -> Void,
            ended: @escaping () -> Void,
            moved: @escaping (CGFloat) -> Void
        ) {
            self.shouldBegin = shouldBegin
            self.began = began
            self.ended = ended
            self.moved = moved

            super.init(target: nil, action: nil)
        }

        deinit {
        }

        override public func reset() {
            super.reset()

            self.initialLocation = nil
            self.initialLocation = nil
        }

        override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
            super.touchesBegan(touches, with: event)

            if self.numberOfTouches > 1 {
                self.state = .failed
                self.ended()
                return
            }

            if self.state == .possible {
                if let location = touches.first?.location(in: self.view) {
                    if self.shouldBegin(location) {
                        self.initialLocation = location
                        self.state = .began
                        self.began()
                    } else {
                        self.state = .failed
                    }
                } else {
                    self.state = .failed
                }
            }
        }

        override public func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
            super.touchesEnded(touches, with: event)

            self.initialLocation = nil

            if self.state == .began || self.state == .changed {
                self.ended()
                self.state = .failed
            }
        }

        override public func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
            super.touchesCancelled(touches, with: event)

            self.initialLocation = nil

            if self.state == .began || self.state == .changed {
                self.ended()
                self.state = .failed
            }
        }

        override public func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
            super.touchesMoved(touches, with: event)

            if (self.state == .began || self.state == .changed), let initialLocation = self.initialLocation, let location = touches.first?.location(in: self.view) {
                self.state = .changed
                let offset = location.y - initialLocation.y
                self.moved(offset)
            }
        }
    }

    private let dateIndicator: ComponentHostView<Empty>

    private let lineIndicator: ComponentHostView<Empty>

    private var displayedTooltip: Bool = false
    private var lineTooltip: ComponentHostView<Empty>?

    private var containerSize: CGSize?
    private var indicatorPosition: CGFloat?
    private var scrollIndicatorHeight: CGFloat?

    private var dragGesture: DragGesture?
    public private(set) var isDragging: Bool = false

    private weak var draggingScrollView: UIScrollView?
    private var scrollingInitialOffset: CGFloat?

    private var activityTimer: SwiftSignalKit.Timer?

    public var beginScrolling: (() -> UIScrollView?)?
    public var setContentOffset: ((CGPoint) -> Void)?
    public var openCurrentDate: (() -> Void)?

    private var offsetBarTimer: SwiftSignalKit.Timer?
    private var beganAtDateIndicator = false
    private let hapticFeedback = HapticFeedback()

    private struct ProjectionData {
        var minY: CGFloat
        var maxY: CGFloat
        var indicatorHeight: CGFloat
        var scrollableHeight: CGFloat
    }
    private var projectionData: ProjectionData?

    public struct DisplayTooltip {
        public var animation: String?
        public var text: String
        public var completed: () -> Void

        public init(animation: String?, text: String, completed: @escaping () -> Void) {
            self.animation = animation
            self.text = text
            self.completed = completed
        }
    }

    public var displayTooltip: DisplayTooltip?

    override public init() {
        self.dateIndicator = ComponentHostView<Empty>()
        self.lineIndicator = ComponentHostView<Empty>()

        self.dateIndicator.alpha = 0.0
        self.lineIndicator.alpha = 0.0

        super.init()

        self.dateIndicator.isUserInteractionEnabled = false
        self.lineIndicator.isUserInteractionEnabled = false

        self.view.addSubview(self.dateIndicator)
        self.view.addSubview(self.lineIndicator)

        let dragGesture = DragGesture(
            shouldBegin: { [weak self] point in
                guard let strongSelf = self else {
                    return false
                }

                if strongSelf.dateIndicator.frame.contains(point) {
                    strongSelf.beganAtDateIndicator = true
                } else {
                    strongSelf.beganAtDateIndicator = false
                }

                return true
            },
            began: { [weak self] in
                guard let strongSelf = self else {
                    return
                }

                let offsetBarTimer = SwiftSignalKit.Timer(timeout: 0.2, repeat: false, completion: {
                    guard let strongSelf = self else {
                        return
                    }
                    strongSelf.performOffsetBarTimerEvent()
                }, queue: .mainQueue())
                strongSelf.offsetBarTimer?.invalidate()
                strongSelf.offsetBarTimer = offsetBarTimer
                offsetBarTimer.start()

                strongSelf.isDragging = true

                if let scrollView = strongSelf.beginScrolling?() {
                    strongSelf.draggingScrollView = scrollView
                    strongSelf.scrollingInitialOffset = scrollView.contentOffset.y
                    strongSelf.setContentOffset?(scrollView.contentOffset)
                }

                strongSelf.updateActivityTimer(isScrolling: false)
            },
            ended: { [weak self] in
                guard let strongSelf = self else {
                    return
                }
                strongSelf.draggingScrollView = nil

                if strongSelf.offsetBarTimer != nil {
                    strongSelf.offsetBarTimer?.invalidate()
                    strongSelf.offsetBarTimer = nil

                    strongSelf.openCurrentDate?()
                }

                let transition: ContainedViewLayoutTransition = .animated(duration: 0.2, curve: .easeInOut)
                transition.updateSublayerTransformOffset(layer: strongSelf.dateIndicator.layer, offset: CGPoint(x: 0.0, y: 0.0))

                strongSelf.isDragging = false

                strongSelf.updateLineIndicator(transition: transition)

                strongSelf.updateActivityTimer(isScrolling: false)
            },
            moved: { [weak self] relativeOffset in
                guard let strongSelf = self else {
                    return
                }
                guard let scrollView = strongSelf.draggingScrollView, let scrollingInitialOffset = strongSelf.scrollingInitialOffset else {
                    return
                }
                guard let projectionData = strongSelf.projectionData else {
                    return
                }

                if strongSelf.offsetBarTimer != nil {
                    strongSelf.offsetBarTimer?.invalidate()
                    strongSelf.offsetBarTimer = nil
                    strongSelf.performOffsetBarTimerEvent()
                }

                let indicatorArea = projectionData.maxY - projectionData.minY
                let scrollFraction = projectionData.scrollableHeight / indicatorArea

                var offset = scrollingInitialOffset + scrollFraction * relativeOffset
                if offset < 0.0 {
                    offset = 0.0
                }
                if offset > scrollView.contentSize.height - scrollView.bounds.height {
                    offset = scrollView.contentSize.height - scrollView.bounds.height
                }

                strongSelf.setContentOffset?(CGPoint(x: 0.0, y: offset))
                let _ = scrollView
                let _ = projectionData
            }
        )
        self.dragGesture = dragGesture

        self.view.addGestureRecognizer(dragGesture)
    }

    private func performOffsetBarTimerEvent() {
        self.hapticFeedback.impact()
        self.offsetBarTimer = nil

        let transition: ContainedViewLayoutTransition = .animated(duration: 0.1, curve: .easeInOut)
        transition.updateSublayerTransformOffset(layer: self.dateIndicator.layer, offset: self.beganAtDateIndicator ? CGPoint(x: -80.0, y: 0.0) : CGPoint(x: -3.0, y: 0.0))
        self.updateLineIndicator(transition: transition)
    }

    func feedbackTap() {
        self.hapticFeedback.tap()
    }

    public func update(
        containerSize: CGSize,
        containerInsets: UIEdgeInsets,
        contentHeight: CGFloat,
        contentOffset: CGFloat,
        isScrolling: Bool,
        dateString: String,
        transition: ContainedViewLayoutTransition
    ) {
        self.containerSize = containerSize

        if isScrolling {
            self.updateActivityTimer(isScrolling: true)
        }

        let indicatorSize = self.dateIndicator.update(
            transition: .immediate,
            component: AnyComponent(SparseItemGridScrollingIndicatorComponent(
                backgroundColor: .white,
                shadowColor: .black,
                foregroundColor: .black,
                dateString: dateString
            )),
            environment: {},
            containerSize: containerSize
        )

        let scrollIndicatorHeightFraction = min(1.0, max(0.0, (containerSize.height - containerInsets.top - containerInsets.bottom) / contentHeight))
        if scrollIndicatorHeightFraction >= 1.0 - .ulpOfOne {
            self.dateIndicator.isHidden = true
            self.lineIndicator.isHidden = true
        } else {
            self.dateIndicator.isHidden = false
            self.lineIndicator.isHidden = false
        }

        let indicatorVerticalInset: CGFloat = 3.0
        let topIndicatorInset: CGFloat = indicatorVerticalInset + containerInsets.top
        let bottomIndicatorInset: CGFloat = indicatorVerticalInset + containerInsets.bottom

        let scrollIndicatorHeight = max(35.0, ceil(scrollIndicatorHeightFraction * containerSize.height))

        let indicatorPositionFraction = min(1.0, max(0.0, contentOffset / (contentHeight - containerSize.height)))

        let indicatorTopPosition = topIndicatorInset
        let indicatorBottomPosition = containerSize.height - bottomIndicatorInset - scrollIndicatorHeight

        let dateIndicatorTopPosition = topIndicatorInset
        let dateIndicatorBottomPosition = containerSize.height - bottomIndicatorInset - indicatorSize.height

        self.indicatorPosition = indicatorTopPosition * (1.0 - indicatorPositionFraction) + indicatorBottomPosition * indicatorPositionFraction
        self.scrollIndicatorHeight = scrollIndicatorHeight

        let dateIndicatorPosition = dateIndicatorTopPosition * (1.0 - indicatorPositionFraction) + dateIndicatorBottomPosition * indicatorPositionFraction

        self.projectionData = ProjectionData(
            minY: dateIndicatorTopPosition,
            maxY: dateIndicatorBottomPosition,
            indicatorHeight: indicatorSize.height,
            scrollableHeight: contentHeight - containerSize.height
        )

        transition.updateFrame(view: self.dateIndicator, frame: CGRect(origin: CGPoint(x: containerSize.width - 12.0 - indicatorSize.width, y: dateIndicatorPosition), size: indicatorSize))
        if isScrolling {
            self.dateIndicator.alpha = 1.0
            self.lineIndicator.alpha = 1.0
        }

        self.updateLineTooltip(containerSize: containerSize)

        self.updateLineIndicator(transition: transition)

        if isScrolling {
            self.displayTooltipOnFirstScroll()
        }
    }

    private func updateLineIndicator(transition: ContainedViewLayoutTransition) {
        guard let indicatorPosition = self.indicatorPosition, let scrollIndicatorHeight = self.scrollIndicatorHeight else {
            return
        }

        let lineIndicatorSize = CGSize(width: self.isDragging ? 6.0 : 3.0, height: scrollIndicatorHeight)
        let mappedTransition: Transition
        switch transition {
        case .immediate:
            mappedTransition = .immediate
        case let .animated(duration, _):
            mappedTransition = Transition(animation: .curve(duration: duration, curve: .easeInOut))
        }
        let _ = self.lineIndicator.update(
            transition: mappedTransition,
            component: AnyComponent(RoundedRectangle(
                color: UIColor(white: 0.0, alpha: 0.3)
            )),
            environment: {},
            containerSize: lineIndicatorSize
        )

        transition.updateFrame(view: self.lineIndicator, frame: CGRect(origin: CGPoint(x: self.bounds.size.width - 3.0 - lineIndicatorSize.width, y: indicatorPosition), size: lineIndicatorSize))
    }

    private func updateActivityTimer(isScrolling: Bool) {
        self.activityTimer?.invalidate()

        if self.isDragging {
            let transition: ContainedViewLayoutTransition = .animated(duration: 0.3, curve: .easeInOut)
            transition.updateAlpha(layer: self.dateIndicator.layer, alpha: 1.0)
            transition.updateAlpha(layer: self.lineIndicator.layer, alpha: 1.0)
        } else {
            self.activityTimer = SwiftSignalKit.Timer(timeout: 2.0, repeat: false, completion: { [weak self] in
                guard let strongSelf = self else {
                    return
                }
                let transition: ContainedViewLayoutTransition = .animated(duration: 0.3, curve: .easeInOut)
                transition.updateAlpha(layer: strongSelf.dateIndicator.layer, alpha: 0.0)
                transition.updateAlpha(layer: strongSelf.lineIndicator.layer, alpha: 0.0)

                if let lineTooltip = strongSelf.lineTooltip {
                    strongSelf.lineTooltip = nil
                    lineTooltip.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.3, removeOnCompletion: false, completion: { [weak lineTooltip] _ in
                        lineTooltip?.removeFromSuperview()
                    })
                }
            }, queue: .mainQueue())
            self.activityTimer?.start()
        }
    }

    private func displayTooltipOnFirstScroll() {
        guard let displayTooltip = self.displayTooltip else {
            return
        }
        if self.displayedTooltip {
            return
        }
        self.displayedTooltip = true

        let lineTooltip = ComponentHostView<Empty>()
        self.lineTooltip = lineTooltip
        self.view.addSubview(lineTooltip)

        if let containerSize = self.containerSize {
            self.updateLineTooltip(containerSize: containerSize)
        }

        lineTooltip.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.2)

        displayTooltip.completed()
    }

    private func updateLineTooltip(containerSize: CGSize) {
        guard let displayTooltip = self.displayTooltip else {
            return
        }
        guard let lineTooltip = self.lineTooltip else {
            return
        }
        let lineTooltipSize = lineTooltip.update(
            transition: .immediate,
            component: AnyComponent(TooltipComponent(
                icon: displayTooltip.animation.flatMap { animation in
                    AnyComponent(LottieAnimationComponent(
                        name: animation
                    ))
                },
                content: AnyComponent(MultilineText(
                    text: displayTooltip.text,
                    font: Font.regular(13.0),
                    color: .white
                )),
                arrowLocation: self.lineIndicator.frame.insetBy(dx: -4.0, dy: -4.0)
            )),
            environment: {},
            containerSize: containerSize
        )
        lineTooltip.frame = CGRect(origin: CGPoint(), size: lineTooltipSize)
    }

    override public func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if self.dateIndicator.alpha <= 0.01 {
            return nil
        }
        if self.dateIndicator.frame.contains(point) {
            return super.hitTest(point, with: event)
        }

        if self.lineIndicator.alpha <= 0.01 {
            return nil
        }
        if self.lineIndicator.frame.insetBy(dx: -4.0, dy: -2.0).contains(point) {
            return super.hitTest(point, with: event)
        }

        return nil
    }
}
