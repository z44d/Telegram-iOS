import SGSimpleSettings
import Foundation
import UIKit
import AsyncDisplayKit
import Postbox
import SwiftSignalKit
import Display
import TelegramCore
import TelegramPresentationData
import TelegramUIPreferences
import UniversalMediaPlayer
import TextFormat
import AccountContext
import RadialStatusNode
import StickerResources
import PhotoResources
import TelegramUniversalVideoContent
import TelegramStringFormatting
import GalleryUI
import AnimatedStickerNode
import TelegramAnimatedStickerNode
import LocalMediaResources
import WallpaperResources
import ChatMessageInteractiveMediaBadge
import ContextUI
import InvisibleInkDustNode
import ChatControllerInteraction
import StoryContainerScreen
import ChatMessageDateAndStatusNode
import ChatHistoryEntry
import ChatMessageItemCommon
import WallpaperPreviewMedia
import TextNodeWithEntities

private struct FetchControls {
    let fetch: (Bool) -> Void
    let cancel: () -> Void
}

public enum InteractiveMediaNodeSizeCalculation {
    case constrained(CGSize)
    case unconstrained
}

public enum InteractiveMediaNodeContentMode {
    case aspectFit
    case aspectFill
    
    public var bubbleVideoDecorationContentMode: ChatBubbleVideoDecorationContentMode {
        switch self {
        case .aspectFit:
            return .aspectFit
        case .aspectFill:
            return .aspectFill
        }
    }
}

public enum InteractiveMediaNodeActivateContent {
    case `default`
    case stream
    case automaticPlayback
}

public enum InteractiveMediaNodeAutodownloadMode {
    case none
    case prefetch
    case full
}

public enum InteractiveMediaNodePlayWithSoundMode {
    case single
    case loop
}

public struct ChatMessageDateAndStatus {
    public var type: ChatMessageDateAndStatusType
    public var edited: Bool
    public var viewCount: Int?
    public var dateReactions: [MessageReaction]
    public var dateReactionPeers: [(MessageReaction.Reaction, EnginePeer)]
    public var dateReplies: Int
    public var isPinned: Bool
    public var dateText: String

    public init(
        type: ChatMessageDateAndStatusType,
        edited: Bool,
        viewCount: Int?,
        dateReactions: [MessageReaction],
        dateReactionPeers: [(MessageReaction.Reaction, EnginePeer)],
        dateReplies: Int,
        isPinned: Bool,
        dateText: String
    ) {
        self.type = type
        self.edited = edited
        self.viewCount = viewCount
        self.dateReactions = dateReactions
        self.dateReactionPeers = dateReactionPeers
        self.dateReplies = dateReplies
        self.isPinned = isPinned
        self.dateText = dateText
    }
}

public func roundedRectCgPath(roundRect rect: CGRect, topLeftRadius: CGFloat = 0.0, topRightRadius: CGFloat = 0.0, bottomLeftRadius: CGFloat = 0.0, bottomRightRadius: CGFloat = 0.0) -> CGPath {
    let path = CGMutablePath()

    let topLeft = rect.origin
    let topRight = CGPoint(x: rect.maxX, y: rect.minY)
    let bottomRight = CGPoint(x: rect.maxX, y: rect.maxY)
    let bottomLeft = CGPoint(x: rect.minX, y: rect.maxY)

    if topLeftRadius != .zero {
        path.move(to: CGPoint(x: topLeft.x+topLeftRadius, y: topLeft.y))
    } else {
        path.move(to: CGPoint(x: topLeft.x, y: topLeft.y))
    }

    if topRightRadius != .zero {
        path.addLine(to: CGPoint(x: topRight.x-topRightRadius, y: topRight.y))
        path.addCurve(to:  CGPoint(x: topRight.x, y: topRight.y+topRightRadius), control1: CGPoint(x: topRight.x, y: topRight.y), control2:CGPoint(x: topRight.x, y: topRight.y + topRightRadius))
    } else {
         path.addLine(to: CGPoint(x: topRight.x, y: topRight.y))
    }

    if bottomRightRadius != .zero {
        path.addLine(to: CGPoint(x: bottomRight.x, y: bottomRight.y-bottomRightRadius))
        path.addCurve(to: CGPoint(x: bottomRight.x-bottomRightRadius, y: bottomRight.y), control1: CGPoint(x: bottomRight.x, y: bottomRight.y), control2: CGPoint(x: bottomRight.x-bottomRightRadius, y: bottomRight.y))
    } else {
        path.addLine(to: CGPoint(x: bottomRight.x, y: bottomRight.y))
    }

    if bottomLeftRadius != .zero {
        path.addLine(to: CGPoint(x: bottomLeft.x+bottomLeftRadius, y: bottomLeft.y))
        path.addCurve(to: CGPoint(x: bottomLeft.x, y: bottomLeft.y-bottomLeftRadius), control1: CGPoint(x: bottomLeft.x, y: bottomLeft.y), control2: CGPoint(x: bottomLeft.x, y: bottomLeft.y-bottomLeftRadius))
    } else {
        path.addLine(to: CGPoint(x: bottomLeft.x, y: bottomLeft.y))
    }

    if topLeftRadius != .zero {
        path.addLine(to: CGPoint(x: topLeft.x, y: topLeft.y+topLeftRadius))
        path.addCurve(to: CGPoint(x: topLeft.x+topLeftRadius, y: topLeft.y) , control1: CGPoint(x: topLeft.x, y: topLeft.y) , control2: CGPoint(x: topLeft.x+topLeftRadius, y: topLeft.y))
    } else {
        path.addLine(to: CGPoint(x: topLeft.x, y: topLeft.y))
    }

    path.closeSubpath()
            
    return path
}

extension UIBezierPath {
    convenience init(roundRect rect: CGRect, topLeftRadius: CGFloat = 0.0, topRightRadius: CGFloat = 0.0, bottomLeftRadius: CGFloat = 0.0, bottomRightRadius: CGFloat = 0.0) {
        self.init()

        let path = CGMutablePath()

        let topLeft = rect.origin
        let topRight = CGPoint(x: rect.maxX, y: rect.minY)
        let bottomRight = CGPoint(x: rect.maxX, y: rect.maxY)
        let bottomLeft = CGPoint(x: rect.minX, y: rect.maxY)

        if topLeftRadius != .zero {
            path.move(to: CGPoint(x: topLeft.x+topLeftRadius, y: topLeft.y))
        } else {
            path.move(to: CGPoint(x: topLeft.x, y: topLeft.y))
        }

        if topRightRadius != .zero {
            path.addLine(to: CGPoint(x: topRight.x-topRightRadius, y: topRight.y))
            path.addCurve(to:  CGPoint(x: topRight.x, y: topRight.y+topRightRadius), control1: CGPoint(x: topRight.x, y: topRight.y), control2:CGPoint(x: topRight.x, y: topRight.y + topRightRadius))
        } else {
             path.addLine(to: CGPoint(x: topRight.x, y: topRight.y))
        }

        if bottomRightRadius != .zero {
            path.addLine(to: CGPoint(x: bottomRight.x, y: bottomRight.y-bottomRightRadius))
            path.addCurve(to: CGPoint(x: bottomRight.x-bottomRightRadius, y: bottomRight.y), control1: CGPoint(x: bottomRight.x, y: bottomRight.y), control2: CGPoint(x: bottomRight.x-bottomRightRadius, y: bottomRight.y))
        } else {
            path.addLine(to: CGPoint(x: bottomRight.x, y: bottomRight.y))
        }

        if bottomLeftRadius != .zero {
            path.addLine(to: CGPoint(x: bottomLeft.x+bottomLeftRadius, y: bottomLeft.y))
            path.addCurve(to: CGPoint(x: bottomLeft.x, y: bottomLeft.y-bottomLeftRadius), control1: CGPoint(x: bottomLeft.x, y: bottomLeft.y), control2: CGPoint(x: bottomLeft.x, y: bottomLeft.y-bottomLeftRadius))
        } else {
            path.addLine(to: CGPoint(x: bottomLeft.x, y: bottomLeft.y))
        }

        if topLeftRadius != .zero {
            path.addLine(to: CGPoint(x: topLeft.x, y: topLeft.y+topLeftRadius))
            path.addCurve(to: CGPoint(x: topLeft.x+topLeftRadius, y: topLeft.y) , control1: CGPoint(x: topLeft.x, y: topLeft.y) , control2: CGPoint(x: topLeft.x+topLeftRadius, y: topLeft.y))
        } else {
            path.addLine(to: CGPoint(x: topLeft.x, y: topLeft.y))
        }

        path.closeSubpath()
        cgPath = path
    }
}

private class ExtendedMediaOverlayNode: ASDisplayNode {
    enum Icon {
        case lock
        case eye
        
        var image: UIImage {
            switch self {
            case .lock:
                return generateTintedImage(image: UIImage(bundleImageName: "Chat/Stickers/SmallLock"), color: .white)!
            case .eye:
                return generateTintedImage(image: UIImage(bundleImageName: "Chat/Message/AgeRestricted"), color: .white)!
            }
        }
    }
    private let context: AccountContext
    
    private let blurredImageNode: TransformImageNode
    fileprivate let dustNode: MediaDustNode
    fileprivate let buttonNode: HighlightTrackingButtonNode
    private let highlightedBackgroundNode: ASDisplayNode
    private let iconNode: ASImageNode
    private let textNode: ImmediateTextNodeWithEntities
    
    private var maskView: UIView?
    private var maskLayer: CAShapeLayer?
    
    private var randomId: Int32?
    var isRevealed = false
    var tapped: () -> Void = {}
    
    init(context: AccountContext, hasImageOverlay: Bool, icon: Icon?, enableAnimations: Bool) {
        self.context = context
        
        self.blurredImageNode = TransformImageNode()
        self.blurredImageNode.contentAnimations = []
         
        self.dustNode = MediaDustNode(enableAnimations: enableAnimations)
        
        self.buttonNode = HighlightTrackingButtonNode()
        self.buttonNode.backgroundColor = UIColor(rgb: 0x000000, alpha: 0.3)
        self.buttonNode.clipsToBounds = true
        self.buttonNode.cornerRadius = 16.0
        
        self.highlightedBackgroundNode = ASDisplayNode()
        self.highlightedBackgroundNode.backgroundColor = UIColor(rgb: 0xffffff, alpha: 0.2)
        self.highlightedBackgroundNode.alpha = 0.0
        
        self.iconNode = ASImageNode()
        self.iconNode.displaysAsynchronously = false
        self.iconNode.image = icon?.image
        
        self.textNode = ImmediateTextNodeWithEntities()
        self.textNode.isUserInteractionEnabled = false
        
        super.init()
                
        if hasImageOverlay {
            self.addSubnode(self.blurredImageNode)
        }
        self.addSubnode(self.dustNode)
        self.addSubnode(self.buttonNode)

        self.buttonNode.addSubnode(self.highlightedBackgroundNode)
        self.buttonNode.addSubnode(self.iconNode)
        self.buttonNode.addSubnode(self.textNode)
        
        self.buttonNode.highligthedChanged = { [weak self] highlighted in
            if let strongSelf = self {
                if highlighted {
                    strongSelf.highlightedBackgroundNode.layer.removeAnimation(forKey: "opacity")
                    strongSelf.highlightedBackgroundNode.alpha = 1.0
                } else {
                    strongSelf.highlightedBackgroundNode.alpha = 0.0
                    strongSelf.highlightedBackgroundNode.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.3)
                }
            }
        }
        
        self.buttonNode.addTarget(self, action: #selector(self.buttonPressed), forControlEvents: .touchUpInside)
    }
    
    @objc private func buttonPressed() {
        self.tapped()
    }
        
    override func didLoad() {
        super.didLoad()
        
        if #available(iOS 13.0, *) {
            self.buttonNode.layer.cornerCurve = .continuous
        }
        
        let maskView = UIView()
        self.maskView = maskView
        self.dustNode.view.mask = maskView
        
        let maskLayer = CAShapeLayer()
        maskLayer.fillRule = .evenOdd
        maskLayer.fillColor = UIColor.white.cgColor
        maskView.layer.addSublayer(maskLayer)
        self.maskLayer = maskLayer
    }
    
    func reveal(animated: Bool = false) {
        self.isRevealed = true
        if animated {
            self.dustNode.revealOnTap = true
            self.dustNode.tap(at: CGPoint(x: self.dustNode.bounds.width / 2.0, y: self.dustNode.bounds.height / 2.0))
        } else {
            self.blurredImageNode.removeFromSupernode()
            self.dustNode.removeFromSupernode()
        }
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let result = super.hitTest(point, with: event)
        if self.isRevealed {
            return nil
        }
        return result
    }
        
    func update(size: CGSize, text: String, imageSignal: (Signal<(TransformImageArguments) -> DrawingContext?, NoError>, CGSize, CGSize, Int32)?, imageFrame: CGRect, corners: ImageCorners?) {
        let spacing: CGFloat = 2.0
        let padding: CGFloat = 10.0
        
        if let (imageSignal, drawingSize, boundingSize, randomId) = imageSignal {
            if self.randomId != randomId {
                self.randomId = randomId
                self.blurredImageNode.setSignal(imageSignal, attemptSynchronously: true)
                
                let imageLayout = self.blurredImageNode.asyncLayout()
                let arguments = TransformImageArguments(corners: corners ?? ImageCorners(), imageSize: drawingSize, boundingSize: boundingSize, intrinsicInsets: UIEdgeInsets(), resizeMode: .blurBackground, emptyColor: .clear, custom: nil)
                let apply = imageLayout(arguments)
                apply()
            }
            
            self.blurredImageNode.isHidden = false

            self.isRevealed = self.dustNode.isRevealed
            self.dustNode.revealed = { [weak self] in
                guard let self else {
                    return
                }
                self.isRevealed = true
                self.blurredImageNode.removeFromSupernode()
                self.buttonNode.removeFromSupernode()
            }
            self.dustNode.tapped = { [weak self] in
                guard let self else {
                    return
                }
                if !self.isRevealed {
                    self.tapped()
                }
            }
        } else {
            self.blurredImageNode.isHidden = true
            self.isRevealed = true
        }
        self.blurredImageNode.frame = imageFrame
                
        self.dustNode.frame = CGRect(origin: .zero, size: size)
        self.dustNode.update(size: size, color: .white, transition: .immediate)
        
        if text.isEmpty {
            self.buttonNode.isHidden = true
            self.textNode.isHidden = true
        } else {
            self.buttonNode.isHidden = false
            self.textNode.isHidden = false
            
            self.textNode.arguments = TextNodeWithEntities.Arguments(context: self.context, cache: self.context.animationCache, renderer: self.context.animationRenderer, placeholderColor: .clear, attemptSynchronous: true)
            
            let string = NSMutableAttributedString(string: text, font: Font.semibold(15.0), textColor: .white)
            if let range = string.string.range(of: "⭐️") {
                string.addAttribute(ChatTextInputAttributes.customEmoji, value: ChatTextInputTextCustomEmojiAttribute(interactivelySelectedFromPackId: nil, fileId: 0, file: nil, custom: .stars(tinted: false)), range: NSRange(range, in: string.string))
                string.addAttribute(.baselineOffset, value: 0.5, range: NSRange(range, in: string.string))
            }
        
            self.textNode.attributedText = string
            let textSize = self.textNode.updateLayout(size)
            let iconSize = self.iconNode.image?.size ?? .zero
                
            var contentSize = CGSize(width: textSize.width + padding * 2.0, height: 32.0)
            if iconSize.width > 0.0 {
                contentSize.width += iconSize.width + spacing
            }
            
            self.buttonNode.frame = CGRect(origin: CGPoint(x: floorToScreenPixels((size.width - contentSize.width) / 2.0), y: floorToScreenPixels((size.height - contentSize.height) / 2.0)), size: contentSize)
            self.highlightedBackgroundNode.frame = CGRect(origin: .zero, size: contentSize)
            
            self.iconNode.frame = CGRect(origin: CGPoint(x: padding, y: floorToScreenPixels((contentSize.height - iconSize.height) / 2.0) + 1.0 - UIScreenPixel), size: iconSize)
            self.textNode.frame = CGRect(origin: CGPoint(x: contentSize.width - padding - textSize.width, y: floorToScreenPixels((contentSize.height - textSize.height) / 2.0)), size: textSize)
        }
        
        var leftOffset: CGFloat = 0.0
        var rightOffset: CGFloat = 0.0
        let corners = corners ?? ImageCorners(radius: 16.0)
        if case .Tail = corners.bottomLeft {
            leftOffset = 4.0
        } else if case .Tail = corners.bottomRight {
            rightOffset = 4.0
        }
        let rect = CGRect(origin: CGPoint(x: leftOffset, y: 0.0), size: CGSize(width: size.width - leftOffset - rightOffset, height: size.height))
        let path = UIBezierPath(roundRect: rect, topLeftRadius: corners.topLeft.radius, topRightRadius: corners.topRight.radius, bottomLeftRadius: corners.bottomLeft.radius, bottomRightRadius: corners.bottomRight.radius)
        let buttonPath = UIBezierPath(roundedRect: self.buttonNode.frame, cornerRadius: 16.0)
        path.append(buttonPath)
        path.usesEvenOddFillRule = true
        self.maskLayer?.path = path.cgPath
    }
}

private func selectStoryMedia(item: Stories.Item, preferredHighQuality: Bool) -> Media? {
    if !preferredHighQuality, let alternativeMedia = item.alternativeMedia {
        return alternativeMedia
    } else {
        return item.media
    }
}

public final class ChatMessageInteractiveMediaNode: ASDisplayNode, GalleryItemTransitionNode {
    private let pinchContainerNode: PinchSourceContainerNode
    private let imageNode: TransformImageNode
    private var currentImageArguments: TransformImageArguments?
    private var currentHighQualityImageSignal: (Signal<(TransformImageArguments) -> DrawingContext?, NoError>, CGSize)?
    private var currentBlurredImageSignal: (Signal<(TransformImageArguments) -> DrawingContext?, NoError>, CGSize, CGSize, Int32)?
    private var highQualityImageNode: TransformImageNode?

    private var videoNode: UniversalVideoNode?
    private var videoContent: NativeVideoContent?
    private var animatedStickerNode: AnimatedStickerNode?
    private var statusNode: RadialStatusNode?
    public var videoNodeDecoration: ChatBubbleVideoDecoration?
    public var decoration: UniversalVideoDecoration? {
        return self.videoNodeDecoration
    }
    public let dateAndStatusNode: ChatMessageDateAndStatusNode
    private var badgeNode: ChatMessageInteractiveMediaBadge?
    
    private var extendedMediaOverlayNode: ExtendedMediaOverlayNode?
        
    private var context: AccountContext?
    private var message: Message?
    private var attributes: ChatMessageEntryAttributes?
    private var media: Media?
    private var mediaIndex: Int?
    private var themeAndStrings: (PresentationTheme, PresentationStrings, String, Bool)?
    private var sizeCalculation: InteractiveMediaNodeSizeCalculation?
    private var wideLayout: Bool?
    private var automaticDownload: InteractiveMediaNodeAutodownloadMode?
    public var automaticPlayback: Bool?
    private var preferredStoryHighQuality: Bool = false
    private var showSensitiveContent: Bool = false
    
    private let statusDisposable = MetaDisposable()
    private let fetchControls = Atomic<FetchControls?>(value: nil)
    private var fetchStatus: MediaResourceStatus?
    private var actualFetchStatus: MediaResourceStatus?
    private let fetchDisposable = MetaDisposable()
    
    private let videoNodeReadyDisposable = MetaDisposable()
    private let playerStatusDisposable = MetaDisposable()
    
    private var playerUpdateTimer: SwiftSignalKit.Timer?
    private var playerStatus: MediaPlayerStatus? {
        didSet {
            if self.playerStatus != oldValue {
                if let playerStatus = playerStatus, case .playing = playerStatus.status {
                    self.ensureHasTimer()
                } else {
                    self.stopTimer()
                }
                self.updateStatus(animated: false)
            }
        }
    }
    
    private var secretTimer: SwiftSignalKit.Timer?
    
    public var visibilityPromise = ValuePromise<Bool>(false, ignoreRepeated: true)
    public var visibility: Bool = false {
        didSet {
            self.updateVisibility()
        }
    }
    
    private var internallyVisible = true
    private func updateVisibility() {
        let isPreview = self.themeAndStrings?.3 ?? false
        let visibility = self.visibility && self.internallyVisible && !isPreview
        
        if let videoNode = self.videoNode {
            if visibility {
                if !videoNode.canAttachContent {
                    videoNode.canAttachContent = true
                    if videoNode.hasAttachedContext {
                        videoNode.play()
                    }
                }
            } else {
                videoNode.canAttachContent = false
            }
        }
        self.animatedStickerNode?.visibility = visibility
        self.visibilityPromise.set(visibility)
    }
    
    public var activateLocalContent: (InteractiveMediaNodeActivateContent) -> Void = { _ in }
    public var activatePinch: ((PinchSourceContainerNode) -> Void)?
    public var updateMessageReaction: ((Message, ChatControllerInteractionReaction, Bool, ContextExtractedContentContainingView?) -> Void)?
    public var playMessageEffect: ((Message) -> Void)?
    public var activateAgeRestrictedMedia: (() -> Void)?
    
    override public init() {
        self.pinchContainerNode = PinchSourceContainerNode()

        self.dateAndStatusNode = ChatMessageDateAndStatusNode()

        self.imageNode = TransformImageNode()
        self.imageNode.contentAnimations = [.subsequentUpdates]
        
        super.init()

        self.addSubnode(self.pinchContainerNode)
        
        self.imageNode.displaysAsynchronously = false
        self.pinchContainerNode.contentNode.addSubnode(self.imageNode)
        
        self.pinchContainerNode.activate = { [weak self] sourceNode in
            guard let strongSelf = self else {
                return
            }
            strongSelf.activatePinch?(sourceNode)
        }

        self.pinchContainerNode.scaleUpdated = { [weak self] scale, transition in
            guard let strongSelf = self else {
                return
            }

            let factor: CGFloat = max(0.0, min(1.0, (scale - 1.0) * 8.0))

            if abs(scale - 1.0) > CGFloat.ulpOfOne {
                var highQualityImageNode: TransformImageNode?
                if let current = strongSelf.highQualityImageNode {
                    highQualityImageNode = current
                } else if let (currentHighQualityImageSignal, nativeImageSize) = strongSelf.currentHighQualityImageSignal, let currentImageArguments = strongSelf.currentImageArguments {
                    let imageNode = TransformImageNode()
                    imageNode.frame = strongSelf.imageNode.frame

                    let corners = currentImageArguments.corners
                    if isRoundEqualCorners(corners) {
                        imageNode.cornerRadius = corners.topLeft.radius
                        imageNode.layer.mask = nil
                    } else {
                        imageNode.cornerRadius = 0

                        let boundingSize: CGSize = CGSize(width: max(corners.topLeft.radius, corners.bottomLeft.radius) + max(corners.topRight.radius, corners.bottomRight.radius), height: max(corners.topLeft.radius, corners.topRight.radius) + max(corners.bottomLeft.radius, corners.bottomRight.radius))
                        let size: CGSize = CGSize(width: boundingSize.width + corners.extendedEdges.left + corners.extendedEdges.right, height: boundingSize.height + corners.extendedEdges.top + corners.extendedEdges.bottom)
                        let arguments = TransformImageArguments(corners: corners, imageSize: size, boundingSize: boundingSize, intrinsicInsets: UIEdgeInsets())
                        guard let context = DrawingContext(size: size, clear: true) else {
                            return
                        }
                        context.withContext { ctx in
                            ctx.setFillColor(UIColor.black.cgColor)
                            ctx.fill(arguments.drawingRect)
                        }
                        addCorners(context, arguments: arguments)

                        if let maskImage = context.generateImage() {
                            let mask = CALayer()
                            mask.contents = maskImage.cgImage
                            mask.contentsScale = maskImage.scale
                            mask.contentsCenter = CGRect(x: max(corners.topLeft.radius, corners.bottomLeft.radius) / maskImage.size.width, y: max(corners.topLeft.radius, corners.topRight.radius) / maskImage.size.height, width: (maskImage.size.width - max(corners.topLeft.radius, corners.bottomLeft.radius) - max(corners.topRight.radius, corners.bottomRight.radius)) / maskImage.size.width, height: (maskImage.size.height - max(corners.topLeft.radius, corners.topRight.radius) - max(corners.bottomLeft.radius, corners.bottomRight.radius)) / maskImage.size.height)

                            imageNode.layer.mask = mask
                            imageNode.layer.mask?.frame = imageNode.bounds
                        }
                    }

                    strongSelf.pinchContainerNode.contentNode.insertSubnode(imageNode, aboveSubnode: strongSelf.imageNode)

                    let scaleFactor = nativeImageSize.height / currentImageArguments.imageSize.height

                    let apply = imageNode.asyncLayout()(TransformImageArguments(corners: ImageCorners(), imageSize: CGSize(width: currentImageArguments.imageSize.width * scaleFactor, height: currentImageArguments.imageSize.height * scaleFactor), boundingSize: CGSize(width: currentImageArguments.boundingSize.width * scaleFactor, height: currentImageArguments.boundingSize.height * scaleFactor), intrinsicInsets: UIEdgeInsets(top: currentImageArguments.intrinsicInsets.top * scaleFactor, left: currentImageArguments.intrinsicInsets.left * scaleFactor, bottom: currentImageArguments.intrinsicInsets.bottom * scaleFactor, right: currentImageArguments.intrinsicInsets.right * scaleFactor)))
                    let _ = apply()
                    imageNode.setSignal(currentHighQualityImageSignal, attemptSynchronously: false)

                    highQualityImageNode = imageNode
                    strongSelf.highQualityImageNode = imageNode
                }
                if let highQualityImageNode = highQualityImageNode {
                    transition.updateAlpha(node: highQualityImageNode, alpha: factor)
                }
            } else if let highQualityImageNode = strongSelf.highQualityImageNode {
                strongSelf.highQualityImageNode = nil
                transition.updateAlpha(node: highQualityImageNode, alpha: 0.0, completion: { [weak highQualityImageNode] _ in
                    highQualityImageNode?.removeFromSupernode()
                })
            }

            transition.updateAlpha(node: strongSelf.dateAndStatusNode, alpha: 1.0 - factor)
            if let badgeNode = strongSelf.badgeNode {
                transition.updateAlpha(node: badgeNode, alpha: 1.0 - factor)
            }
            if let statusNode = strongSelf.statusNode {
                transition.updateAlpha(node: statusNode, alpha: 1.0 - factor)
            }
        }
    }
    
    deinit {
        self.statusDisposable.dispose()
        self.videoNodeReadyDisposable.dispose()
        self.playerStatusDisposable.dispose()
        self.fetchDisposable.dispose()
        self.secretTimer?.invalidate()
    }
    
    public func isAvailableForGalleryTransition() -> Bool {
        return self.automaticPlayback ?? false
    }
    
    public func isAvailableForInstantPageTransition() -> Bool {
        return false
    }
    
    override public func didLoad() {
        super.didLoad()
        
        self.imageNode.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.imageTap(_:))))
    }
    
    private func progressPressed(canActivate: Bool) {
        if let _ = self.attributes?.updatingMedia {
            if let message = self.message {
                self.context?.account.pendingUpdateMessageManager.cancel(messageId: message.id)
            }
        } else if let fetchStatus = self.fetchStatus {
            var activateContent = false
            if let state = self.statusNode?.state, case .play = state {
                activateContent = true
            } else if let message = self.message, !message.flags.isSending && (self.automaticPlayback ?? false) {
                activateContent = true
            }
            if canActivate, activateContent {
                switch fetchStatus {
                    case .Remote, .Fetching:
                        self.activateLocalContent(.stream)
                    default:
                        break
                }
                return
            }
            
            switch fetchStatus {
                case .Fetching:
                    if let context = self.context, let message = self.message, message.flags.isSending {
                        let _ = context.engine.messages.deleteMessagesInteractively(messageIds: [message.id], type: .forEveryone).startStandalone()
                    } else if let media = self.media, let context = self.context, let message = self.message {
                        if let media = media as? TelegramMediaFile {
                            messageMediaFileCancelInteractiveFetch(context: context, messageId: message.id, file: media)
                        } else if let media = media as? TelegramMediaImage, let resource = largestImageRepresentation(media.representations)?.resource {
                            messageMediaImageCancelInteractiveFetch(context: context, messageId: message.id, image: media, resource: resource)
                        } else if let invoice = media as? TelegramMediaInvoice, let extendedMedia = invoice.extendedMedia, case let .full(media) = extendedMedia {
                            if let media = media as? TelegramMediaFile {
                                messageMediaFileCancelInteractiveFetch(context: context, messageId: message.id, file: media)
                            } else if let media = media as? TelegramMediaImage, let resource = largestImageRepresentation(media.representations)?.resource {
                                messageMediaImageCancelInteractiveFetch(context: context, messageId: message.id, image: media, resource: resource)
                            }
                        } else if let storyMedia = media as? TelegramMediaStory, let storyItem = message.associatedStories[storyMedia.storyId]?.get(Stories.StoredItem.self) {
                            if case let .item(item) = storyItem, let media = item.media {
                                if let media = media as? TelegramMediaFile {
                                    messageMediaFileCancelInteractiveFetch(context: context, messageId: message.id, file: media)
                                } else if let media = media as? TelegramMediaImage, let resource = largestImageRepresentation(media.representations)?.resource {
                                    messageMediaImageCancelInteractiveFetch(context: context, messageId: message.id, image: media, resource: resource)
                                }
                                if let alternativeMedia = item.alternativeMedia {
                                    if let media = alternativeMedia as? TelegramMediaFile {
                                        messageMediaFileCancelInteractiveFetch(context: context, messageId: message.id, file: media)
                                    } else if let media = alternativeMedia as? TelegramMediaImage, let resource = largestImageRepresentation(media.representations)?.resource {
                                        messageMediaImageCancelInteractiveFetch(context: context, messageId: message.id, image: media, resource: resource)
                                    }
                                }
                            }
                        }
                    }
                    if let cancel = self.fetchControls.with({ return $0?.cancel }) {
                        cancel()
                    }
                case .Remote, .Paused:
                    if let fetch = self.fetchControls.with({ return $0?.fetch }) {
                        fetch(true)
                    }
                case .Local:
                    break
            }
        }
    }
    
    override public func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let result = super.hitTest(point, with: event)
        return result
    }
    
    @objc private func imageTap(_ recognizer: UITapGestureRecognizer) {
        if case .ended = recognizer.state {
            let point = recognizer.location(in: self.imageNode.view)
            if let _ = self.attributes?.updatingMedia {
                if let statusNode = self.statusNode, statusNode.frame.contains(point) {
                    self.progressPressed(canActivate: true)
                }
            } else if let fetchStatus = self.fetchStatus, case .Local = fetchStatus {
                var videoContentMatch = true
                if let content = self.videoContent, case let .message(stableId, mediaId) = content.nativeId {
                    var media = self.media
                    if let invoice = media as? TelegramMediaInvoice, let extendedMedia = invoice.extendedMedia, case let .full(fullMedia) = extendedMedia {
                        media = fullMedia
                    }
                    
                    if let storyMedia = media as? TelegramMediaStory, let storyItem = self.message?.associatedStories[storyMedia.storyId]?.get(Stories.StoredItem.self) {
                        if case let .item(item) = storyItem, let _ = item.media {
                            media = selectStoryMedia(item: item, preferredHighQuality: self.preferredStoryHighQuality)
                        }
                    }
                    
                    videoContentMatch = self.message?.stableId == stableId && media?.id == mediaId
                }
                self.activateLocalContent((self.automaticPlayback ?? false) && videoContentMatch ? .automaticPlayback : .default)
            } else {
                if let message = self.message, message.flags.isSending {
                    if let statusNode = self.statusNode, statusNode.frame.contains(point) {
                        self.progressPressed(canActivate: true)
                    }
                } else {
                    if let invoice = self.media as? TelegramMediaInvoice, let _ = invoice.extendedMedia {
                        self.activateLocalContent(.default)
                    } else if let _ = self.media as? TelegramMediaPaidContent {
                        self.activateLocalContent(.default)
                    } else if let storyMedia = media as? TelegramMediaStory, let storyItem = self.message?.associatedStories[storyMedia.storyId]?.get(Stories.StoredItem.self) {
                        if case let .item(item) = storyItem, let _ = item.media {
                            self.activateLocalContent(.default)
                        }
                    } else {
                        self.progressPressed(canActivate: true)
                    }
                }
            }
        }
    }
    
    public func asyncLayout() -> (_ context: AccountContext, _ presentationData: ChatPresentationData, _ dateTimeFormat: PresentationDateTimeFormat, _ message: Message, _ associatedData: ChatMessageItemAssociatedData,  _ attributes: ChatMessageEntryAttributes, _ media: Media, _ mediaIndex: Int?, _ dateAndStatus: ChatMessageDateAndStatus?, _ automaticDownload: InteractiveMediaNodeAutodownloadMode, _ peerType: MediaAutoDownloadPeerType, _ peerId: EnginePeer.Id?, _ sizeCalculation: InteractiveMediaNodeSizeCalculation, _ layoutConstants: ChatMessageItemLayoutConstants, _ contentMode: InteractiveMediaNodeContentMode, _ presentationContext: ChatPresentationContext) -> (CGSize, CGFloat, (CGSize, Bool, Bool, ImageCorners) -> (CGFloat, (CGFloat) -> (CGSize, (ListViewItemUpdateAnimation, Bool) -> Void))) {
        let currentMessage = self.message
        let currentMedia = self.media
        let imageLayout = self.imageNode.asyncLayout()
        let statusLayout = self.dateAndStatusNode.asyncLayout()
        
        let currentVideoNode = self.videoNode
        let currentAnimatedStickerNode = self.animatedStickerNode
        
        let hasCurrentVideoNode = currentVideoNode != nil
        let hasCurrentAnimatedStickerNode = currentAnimatedStickerNode != nil
        let currentAutomaticDownload = self.automaticDownload
        let currentAutomaticPlayback = self.automaticPlayback
        
        return { [weak self] context, presentationData, dateTimeFormat, message, associatedData, attributes, media, mediaIndex, dateAndStatus, automaticDownload, peerType, peerId, sizeCalculation, layoutConstants, contentMode, presentationContext in
            let _ = peerType
            
            var nativeSize: CGSize
            
            let isSecretMedia = message.containsSecretMedia
            var secretBeginTimeAndTimeout: (Double, Double)?
            if isSecretMedia {
                if let attribute = message.autoclearAttribute {
                    if let countdownBeginTime = attribute.countdownBeginTime {
                        secretBeginTimeAndTimeout = (Double(countdownBeginTime), Double(attribute.timeout))
                    }
                } else if let attribute = message.autoremoveAttribute {
                    if let countdownBeginTime = attribute.countdownBeginTime {
                        secretBeginTimeAndTimeout = (Double(countdownBeginTime), Double(attribute.timeout))
                    }
                }
            }
            
            var storeToDownloadsPeerId: EnginePeer.Id?
            for media in message.media {
                if media is TelegramMediaImage {
                    storeToDownloadsPeerId = peerId
                }
            }
            
            let hasSpoiler = message.attributes.contains(where: { $0 is MediaSpoilerMessageAttribute })
            var isExtendedMediaPreview = false
            var isInlinePlayableVideo = false
            var isSticker = false
            var maxDimensions = layoutConstants.image.maxDimensions
            var maxHeight = layoutConstants.image.maxDimensions.height
            // MARK: Swiftgram
            var imageOriginalMaxDimensions: CGSize?
            var isStory = false
            
            let _ = isStory
            
            var additionalWidthConstrainment = false
            var unboundSize: CGSize
            if let story = media as? TelegramMediaStory {
                if message.media.contains(where: { $0 is TelegramMediaWebpage }) {
                    additionalWidthConstrainment = true
                    unboundSize = CGSize(width: 174.0, height: 239.0)
                } else {
                    unboundSize = CGSize(width: 1080, height: 1920)
                }
                
                if let storyItem = message.associatedStories[story.storyId]?.get(Stories.StoredItem.self), case let .item(item) = storyItem, let media = item.media {
                    if let file = media as? TelegramMediaFile {
                        isInlinePlayableVideo = file.isVideo && !isSecretMedia
                    }
                }
            } else if let image = media as? TelegramMediaImage, let dimensions = largestImageRepresentation(image.representations)?.dimensions {
                unboundSize = CGSize(width: max(10.0, floor(dimensions.cgSize.width * 0.5)), height: max(10.0, floor(dimensions.cgSize.height * 0.5)))
                // MARK: Swiftgram
                if let channel = message.peers[message.id.peerId] as? TelegramChannel, case .broadcast = channel.info, SGSimpleSettings.shared.wideChannelPosts {
                    imageOriginalMaxDimensions = maxDimensions
                    switch sizeCalculation {
                    case let .constrained(constrainedSize):
                        maxDimensions.width = constrainedSize.width
                    case .unconstrained:
                        maxDimensions.width = unboundSize.width
                    }
                    if message.text.isEmpty {
                        maxDimensions.width = max(layoutConstants.image.maxDimensions.width, unboundSize.aspectFitted(CGSize(width: maxDimensions.width, height: layoutConstants.image.minDimensions.height)).width)
                    }
                }
            } else if let file = media as? TelegramMediaFile, var dimensions = file.dimensions {
                if let thumbnail = file.previewRepresentations.first {
                    let dimensionsVertical = dimensions.width < dimensions.height
                    let thumbnailVertical = thumbnail.dimensions.width < thumbnail.dimensions.height
                    if dimensionsVertical != thumbnailVertical {
                        dimensions = PixelDimensions(CGSize(width: dimensions.cgSize.height, height: dimensions.cgSize.width))
                    }
                }
                unboundSize = CGSize(width: floor(dimensions.cgSize.width * 0.5), height: floor(dimensions.cgSize.height * 0.5))
                if file.isSticker || file.isAnimatedSticker || file.isVideoSticker {
                    unboundSize = unboundSize.aspectFilled(CGSize(width: 162.0, height: 162.0))
                    isSticker = true
                } else if file.isAnimated {
                    unboundSize = unboundSize.aspectFilled(CGSize(width: 480.0, height: 480.0))
                } else if file.isVideo && !file.isAnimated, case let .constrained(constrainedSize) = sizeCalculation {
                    if unboundSize.width > unboundSize.height {
                        maxDimensions = CGSize(width: constrainedSize.width, height: layoutConstants.video.maxHorizontalHeight)
                    } else {
                        maxDimensions = CGSize(width: constrainedSize.width, height: layoutConstants.video.maxVerticalHeight)
                    }
                    maxHeight = maxDimensions.height
                }
                isInlinePlayableVideo = file.isVideo && !isSecretMedia
            } else if let image = media as? TelegramMediaWebFile, let dimensions = image.dimensions {
                unboundSize = CGSize(width: floor(dimensions.cgSize.width * 0.5), height: floor(dimensions.cgSize.height * 0.5))
            } else if let wallpaper = media as? WallpaperPreviewMedia {
                switch wallpaper.content {
                    case let .file(file, _, _, _, isTheme, isSupported):
                        if let thumbnail = file.previewRepresentations.first, var dimensions = file.dimensions {
                            let dimensionsVertical = dimensions.width < dimensions.height
                            let thumbnailVertical = thumbnail.dimensions.width < thumbnail.dimensions.height
                            if dimensionsVertical != thumbnailVertical {
                                dimensions = PixelDimensions(CGSize(width: dimensions.cgSize.height, height: dimensions.cgSize.width))
                            }
                            unboundSize = CGSize(width: floor(dimensions.cgSize.width * 0.5), height: floor(dimensions.cgSize.height * 0.5)).fitted(CGSize(width: 240.0, height: 240.0))
                        } else if file.mimeType == "image/svg+xml" || file.mimeType == "application/x-tgwallpattern" {
                            let dimensions = CGSize(width: 1440.0, height: 2960.0)
                            unboundSize = CGSize(width: floor(dimensions.width * 0.5), height: floor(dimensions.height * 0.5)).fitted(CGSize(width: 240.0, height: 240.0))
                        } else if isTheme {
                            if isSupported {
                                unboundSize = CGSize(width: 160.0, height: 240.0).fitted(CGSize(width: 240.0, height: 240.0))
                            } else if let thumbnail = file.previewRepresentations.first {
                                unboundSize = CGSize(width: floor(thumbnail.dimensions.cgSize.width), height: floor(thumbnail.dimensions.cgSize.height)).fitted(CGSize(width: 240.0, height: 240.0))
                            } else {
                                unboundSize = CGSize(width: 54.0, height: 54.0)
                            }
                        } else {
                            unboundSize = CGSize(width: 54.0, height: 54.0)
                        }
                    case .themeSettings, .image:
                        unboundSize = CGSize(width: 160.0, height: 240.0).fitted(CGSize(width: 240.0, height: 240.0))
                    case .color, .gradient, .emoticon:
                        unboundSize = CGSize(width: 128.0, height: 128.0)
                }
            } else {
                var extendedMedia: TelegramExtendedMedia?
                if let invoice = media as? TelegramMediaInvoice, let selectedMedia = invoice.extendedMedia {
                    extendedMedia = selectedMedia
                } else if let paidContent = media as? TelegramMediaPaidContent {
                    let selectedMediaIndex = mediaIndex ?? 0
                    if selectedMediaIndex < paidContent.extendedMedia.count {
                        extendedMedia = paidContent.extendedMedia[selectedMediaIndex]
                    }
                }
                if let extendedMedia {
                    switch extendedMedia {
                    case let .preview(dimensions, _, _):
                        if let dimensions = dimensions {
                            unboundSize = CGSize(width: max(10.0, floor(dimensions.cgSize.width * 0.5)), height: max(10.0, floor(dimensions.cgSize.height * 0.5)))
                        } else {
                            unboundSize =  CGSize(width: 200.0, height: 100.0)
                        }
                        isExtendedMediaPreview = true
                    case let .full(media):
                        if let image = media as? TelegramMediaImage, let dimensions = largestImageRepresentation(image.representations)?.dimensions {
                            unboundSize = CGSize(width: max(10.0, floor(dimensions.cgSize.width * 0.5)), height: max(10.0, floor(dimensions.cgSize.height * 0.5)))
                        } else if let file = media as? TelegramMediaFile, var dimensions = file.dimensions {
                            if let thumbnail = file.previewRepresentations.first {
                                let dimensionsVertical = dimensions.width < dimensions.height
                                let thumbnailVertical = thumbnail.dimensions.width < thumbnail.dimensions.height
                                if dimensionsVertical != thumbnailVertical {
                                    dimensions = PixelDimensions(CGSize(width: dimensions.cgSize.height, height: dimensions.cgSize.width))
                                }
                            }
                            unboundSize = CGSize(width: floor(dimensions.cgSize.width * 0.5), height: floor(dimensions.cgSize.height * 0.5))
                            if file.isAnimated {
                                unboundSize = unboundSize.aspectFilled(CGSize(width: 480.0, height: 480.0))
                            } else if file.isVideo && !file.isAnimated, case let .constrained(constrainedSize) = sizeCalculation {
                                if unboundSize.width > unboundSize.height {
                                    maxDimensions = CGSize(width: constrainedSize.width, height: layoutConstants.video.maxHorizontalHeight)
                                } else {
                                    maxDimensions = CGSize(width: constrainedSize.width, height: layoutConstants.video.maxVerticalHeight)
                                }
                                maxHeight = maxDimensions.height
                            }
                            isInlinePlayableVideo = file.isVideo && !isSecretMedia
                        } else {
                            unboundSize = CGSize(width: 54.0, height: 54.0)
                        }
                    }
                } else {
                    unboundSize = CGSize(width: 54.0, height: 54.0)
                }
            }
            
            switch sizeCalculation {
                case let .constrained(constrainedSize):
                    if isSticker {
                        nativeSize = unboundSize.aspectFittedOrSmaller(constrainedSize)
                    } else {
                        var constrainedSize = constrainedSize
                        if additionalWidthConstrainment {
                            constrainedSize.width = min(constrainedSize.width, unboundSize.width)
                            constrainedSize.height = min(constrainedSize.height, unboundSize.height)
                        }
                        if unboundSize.width > unboundSize.height || additionalWidthConstrainment {
                            nativeSize = unboundSize.aspectFitted(constrainedSize)
                        } else {
                            nativeSize = unboundSize.aspectFitted(CGSize(width: constrainedSize.height, height: constrainedSize.width))
                        }
                    }
                case .unconstrained:
                    nativeSize = unboundSize
            }

            var statusSize = CGSize()
            var statusApply: ((ListViewItemUpdateAnimation) -> Void)?
            
            let messageEffect = message.messageEffect(availableMessageEffects: associatedData.availableMessageEffects)

            if let dateAndStatus = dateAndStatus {
                let statusSuggestedWidthAndContinue = statusLayout(ChatMessageDateAndStatusNode.Arguments(
                    context: context,
                    presentationData: presentationData,
                    edited: dateAndStatus.edited && !presentationData.isPreview,
                    impressionCount: !presentationData.isPreview ? dateAndStatus.viewCount : nil,
                    dateText: dateAndStatus.dateText,
                    type: dateAndStatus.type,
                    layoutInput: .standalone(reactionSettings: shouldDisplayInlineDateReactions(message: message, isPremium: associatedData.isPremium, forceInline: associatedData.forceInlineReactions) ? ChatMessageDateAndStatusNode.StandaloneReactionSettings() : nil),
                    constrainedSize: CGSize(width: nativeSize.width - 30.0, height: CGFloat.greatestFiniteMagnitude),
                    availableReactions: associatedData.availableReactions,
                    savedMessageTags: associatedData.savedMessageTags,
                    reactions: dateAndStatus.dateReactions,
                    reactionPeers: dateAndStatus.dateReactionPeers,
                    displayAllReactionPeers: message.id.peerId.namespace == Namespaces.Peer.CloudUser,
                    areReactionsTags: message.areReactionsTags(accountPeerId: context.account.peerId),
                    messageEffect: messageEffect,
                    replyCount: dateAndStatus.dateReplies,
                    isPinned: dateAndStatus.isPinned,
                    hasAutoremove: message.isSelfExpiring,
                    canViewReactionList: canViewMessageReactionList(message: message),
                    animationCache: presentationContext.animationCache,
                    animationRenderer: presentationContext.animationRenderer
                ))
                
                let (size, apply) = statusSuggestedWidthAndContinue.1(statusSuggestedWidthAndContinue.0)
                
                statusSize = size
                statusApply = apply
            }
            
            let maxWidth: CGFloat
            if isSecretMedia {
                maxWidth = 200.0
            } else {
                maxWidth = maxDimensions.width
            }
            
            return (nativeSize, maxWidth, { constrainedSize, automaticPlayback, wideLayout, corners in
                var resultWidth: CGFloat
                
                isInlinePlayableVideo = isInlinePlayableVideo && automaticPlayback
                
                switch sizeCalculation {
                    case .constrained:
                        if isSecretMedia {
                            resultWidth = maxWidth
                        } else {
                            let maxFittedSize: CGSize
                            if additionalWidthConstrainment {
                                maxFittedSize = nativeSize.aspectFittedOrSmaller(maxDimensions)
                            } else {
                                maxFittedSize = nativeSize.aspectFitted(maxDimensions)
                            }
                            resultWidth = min(nativeSize.width, min(maxFittedSize.width, min(constrainedSize.width, maxDimensions.width)))
                            resultWidth = max(resultWidth, layoutConstants.image.minDimensions.width)
                        }
                    case .unconstrained:
                        resultWidth = constrainedSize.width
                }
                
                return (resultWidth, { boundingWidth in
                    var boundingSize: CGSize
                    var drawingSize: CGSize
                    
                    switch sizeCalculation {
                        case .constrained:
                            if isSecretMedia {
                                boundingSize = CGSize(width: maxWidth, height: maxWidth / 5.0 * 3.0)
                                drawingSize = nativeSize.aspectFilled(boundingSize)
                            } else {
                                let fittedSize = nativeSize.fittedToWidthOrSmaller(boundingWidth)
                                let filledSize: CGSize
                                if additionalWidthConstrainment {
                                    filledSize = fittedSize
                                } else {
                                    filledSize = fittedSize.aspectFilled(CGSize(width: boundingWidth, height: fittedSize.height))
                                }
                                
                                boundingSize = CGSize(width: boundingWidth, height: filledSize.height).cropped(CGSize(width: CGFloat.greatestFiniteMagnitude, height: maxHeight))
                                if let imageOriginalMaxDimensions = imageOriginalMaxDimensions {
                                    boundingSize.height = min(boundingSize.height, nativeSize.aspectFitted(imageOriginalMaxDimensions).height)
                                }
                                boundingSize.height = max(boundingSize.height, layoutConstants.image.minDimensions.height)
                                boundingSize.width = max(boundingSize.width, layoutConstants.image.minDimensions.width)
                                switch contentMode {
                                    case .aspectFit:
                                        drawingSize = nativeSize.aspectFittedWithOverflow(boundingSize, leeway: 4.0)
                                    case .aspectFill:
                                        drawingSize = nativeSize.aspectFilled(boundingSize)
                                }
                                if additionalWidthConstrainment {
                                    drawingSize.height = drawingSize.width * (1920.0 / 1080.0)
                                }
                            }
                        case .unconstrained:
                            boundingSize = constrainedSize
                            drawingSize = nativeSize.aspectFilled(boundingSize)
                    }
                    
                    var updateImageSignal: ((Bool, Bool) -> Signal<(TransformImageArguments) -> DrawingContext?, NoError>)?
                    var updateBlurredImageSignal: ((Bool, Bool) -> Signal<(TransformImageArguments) -> DrawingContext?, NoError>)?
                    var updatedStatusSignal: Signal<(MediaResourceStatus, MediaResourceStatus?), NoError>?
                    var updatedFetchControls: FetchControls?
                    
                    var mediaUpdated = false
                    if let currentMedia = currentMedia {
                        mediaUpdated = !media.isSemanticallyEqual(to: currentMedia)
                        
                        if !mediaUpdated, let media = media as? TelegramMediaStory {
                            if message.associatedStories[media.storyId] != currentMessage?.associatedStories[media.storyId] {
                                let previousStory = message.associatedStories[media.storyId]
                                let updatedStory = currentMessage?.associatedStories[media.storyId]
                                
                                if let previousItem = previousStory?.get(Stories.StoredItem.self), let updatedItem = updatedStory?.get(Stories.StoredItem.self), case let .item(previousItemValue) = previousItem, case let .item(updatedItemValue) = updatedItem {
                                    if let previousItemMedia = previousItemValue.media, let updatedItemMedia = updatedItemValue.media {
                                        mediaUpdated = !previousItemMedia.isSemanticallyEqual(to: updatedItemMedia)
                                    }
                                } else {
                                    mediaUpdated = true
                                }
                            }
                        }
                    } else {
                        mediaUpdated = true
                    }
                    
                    var isSendingUpdated = false
                    if let currentMessage = currentMessage {
                        isSendingUpdated = message.flags.isSending != currentMessage.flags.isSending
                    }
                    
                    var automaticPlaybackUpdated = false
                    if let currentAutomaticPlayback = currentAutomaticPlayback {
                        automaticPlaybackUpdated = automaticPlayback != currentAutomaticPlayback
                    }
                    
                    var statusUpdated = mediaUpdated
                    if currentMessage?.id != message.id || currentMessage?.flags != message.flags {
                        statusUpdated = true
                    }
                    
                    var replaceVideoNode: Bool?
                    var replaceAnimatedStickerNode: Bool?
                    var updateVideoFile: TelegramMediaFile?
                    var updateAnimatedStickerFile: TelegramMediaFile?
                    var onlyFullSizeVideoThumbnail: Bool?
                    
                    var emptyColor: UIColor
                    var patternArguments: PatternWallpaperArguments?
                    if isSticker {
                        emptyColor = .clear
                    } else {
                        emptyColor = message.effectivelyIncoming(context.account.peerId) ? presentationData.theme.theme.chat.message.incoming.mediaPlaceholderColor : presentationData.theme.theme.chat.message.outgoing.mediaPlaceholderColor
                    }
                    if let wallpaper = media as? WallpaperPreviewMedia {
                        if case let .file(_, patternColors, rotation, intensity, _, _) = wallpaper.content {
                            var colors: [UIColor] = []
                            var customPatternColor: UIColor? = nil
                            var bakePatternAlpha: CGFloat = 1.0
                            if let intensity = intensity, intensity < 0 {
                                if patternColors.isEmpty {
                                    colors.append(UIColor(rgb: 0xd6e2ee, alpha: 0.5))
                                } else {
                                    colors.append(contentsOf: patternColors.map(UIColor.init(rgb:)))
                                }
                                customPatternColor = UIColor(white: 0.0, alpha: 1.0 - CGFloat(abs(intensity)))
                            } else {
                                if patternColors.isEmpty {
                                    colors.append(UIColor(rgb: 0xd6e2ee, alpha: 0.5))
                                } else {
                                    colors.append(contentsOf: patternColors.map(UIColor.init(rgb:)))
                                }
                                let isLight = UIColor.average(of: patternColors.map(UIColor.init(rgb:))).hsb.b > 0.3
                                customPatternColor = isLight ? .black : .white
                                bakePatternAlpha = CGFloat(intensity ?? 50) / 100.0
                            }
                            patternArguments = PatternWallpaperArguments(colors: colors, rotation: rotation, customPatternColor: customPatternColor, bakePatternAlpha: bakePatternAlpha)
                        }
                    }
                    
                    if mediaUpdated || isSendingUpdated || automaticPlaybackUpdated {
                        var media = media
                        
                        var extendedMedia: TelegramExtendedMedia?
                        if let invoice = media as? TelegramMediaInvoice, let selectedMedia = invoice.extendedMedia {
                            extendedMedia = selectedMedia
                        } else if let paidContent = media as? TelegramMediaPaidContent {
                            let selectedMediaIndex = mediaIndex ?? 0
                            if selectedMediaIndex < paidContent.extendedMedia.count {
                                extendedMedia = paidContent.extendedMedia[selectedMediaIndex]
                            }
                        }
                        
                        if let extendedMedia {
                            switch extendedMedia {
                            case let .preview(_, immediateThumbnailData, _):
                                let thumbnailMedia = TelegramMediaImage(imageId: MediaId(namespace: 0, id: 0), representations: [], immediateThumbnailData: immediateThumbnailData, reference: nil, partialReference: nil, flags: [])
                                media = thumbnailMedia
                            case let .full(fullMedia):
                                if presentationData.isPreview {
                                    if let image = fullMedia as? TelegramMediaImage {
                                        let thumbnailMedia = TelegramMediaImage(imageId: MediaId(namespace: 0, id: 0), representations: [], immediateThumbnailData: image.immediateThumbnailData, reference: nil, partialReference: nil, flags: [])
                                        media = thumbnailMedia
                                    } else if let video = fullMedia as? TelegramMediaFile {
                                        let thumbnailMedia = TelegramMediaImage(imageId: MediaId(namespace: 0, id: 0), representations: [], immediateThumbnailData: video.immediateThumbnailData, reference: nil, partialReference: nil, flags: [])
                                        media = thumbnailMedia
                                    }
                                } else {
                                    media = fullMedia
                                }
                            }
                        }
                        
                        if let story = media as? TelegramMediaStory {
                            isStory = true
                            
                            if hasCurrentVideoNode {
                                replaceVideoNode = true
                            }
                            if hasCurrentAnimatedStickerNode {
                                replaceAnimatedStickerNode = true
                            }
                            
                            if let storyItem = message.associatedStories[story.storyId]?.get(Stories.StoredItem.self), case let .item(item) = storyItem, let media = selectStoryMedia(item: item, preferredHighQuality: associatedData.preferredStoryHighQuality) {
                                if let image = media as? TelegramMediaImage {
                                    if hasCurrentVideoNode {
                                        replaceVideoNode = true
                                    }
                                    if hasCurrentAnimatedStickerNode {
                                        replaceAnimatedStickerNode = true
                                    }
                                    if isSecretMedia {
                                        updateImageSignal = { synchronousLoad, _ in
                                            return chatSecretPhoto(account: context.account, userLocation: .peer(message.id.peerId), photoReference: .message(message: MessageReference(message), media: image))
                                        }
                                    } else {
                                        updateImageSignal = { synchronousLoad, highQuality in
                                            return storyPreviewWithAddedReactions(context: context, storyItem: item, signal: chatMessagePhoto(postbox: context.account.postbox, userLocation: .peer(message.id.peerId), photoReference: .message(message: MessageReference(message), media: image), synchronousLoad: synchronousLoad, highQuality: highQuality))
                                        }
                                        updateBlurredImageSignal = { synchronousLoad, _ in
                                            return chatSecretPhoto(account: context.account, userLocation: .peer(message.id.peerId), photoReference: .message(message: MessageReference(message), media: image), ignoreFullSize: true, synchronousLoad: true)
                                        }
                                    }
                                    
                                    updatedFetchControls = FetchControls(fetch: { manual in
                                        if let strongSelf = self {
                                            if let representation = largestRepresentationForPhoto(image) {
                                                strongSelf.fetchDisposable.set(messageMediaImageInteractiveFetched(context: context, message: message, image: image, resource: representation.resource, range: representationFetchRangeForDisplayAtSize(representation: representation, dimension: nil/*isSecretMedia ? nil : 600*/), userInitiated: manual, storeToDownloadsPeerId: storeToDownloadsPeerId).startStrict())
                                            }
                                        }
                                    }, cancel: {
                                        chatMessagePhotoCancelInteractiveFetch(account: context.account, photoReference: .message(message: MessageReference(message), media: image))
                                        if let resource = largestRepresentationForPhoto(image)?.resource {
                                            messageMediaImageCancelInteractiveFetch(context: context, messageId: message.id, image: image, resource: resource)
                                        }
                                    })
                                } else if let file = media as? TelegramMediaFile {
                                    if isSecretMedia {
                                        updateImageSignal = { synchronousLoad, _ in
                                            return chatSecretMessageVideo(account: context.account, userLocation: .peer(message.id.peerId), videoReference: .message(message: MessageReference(message), media: file))
                                        }
                                    } else {
                                        if file.isAnimatedSticker {
                                            let dimensions = file.dimensions ?? PixelDimensions(width: 512, height: 512)
                                            updateImageSignal = { synchronousLoad, _ in
                                                return chatMessageAnimatedSticker(postbox: context.account.postbox, userLocation: .peer(message.id.peerId), file: file, small: false, size: dimensions.cgSize.aspectFitted(CGSize(width: 400.0, height: 400.0)))
                                            }
                                        } else if file.isSticker || file.isVideoSticker {
                                            updateImageSignal = { synchronousLoad, _ in
                                                return chatMessageSticker(account: context.account, userLocation: .peer(message.id.peerId), file: file, small: false)
                                            }
                                        } else {
                                            onlyFullSizeVideoThumbnail = isSendingUpdated
                                            updateImageSignal = { synchronousLoad, _ in
                                                return storyPreviewWithAddedReactions(context: context, storyItem: item, signal: mediaGridMessageVideo(postbox: context.account.postbox, userLocation: .peer(message.id.peerId), videoReference: .message(message: MessageReference(message), media: file), onlyFullSize: currentMedia?.id?.namespace == Namespaces.Media.LocalFile, autoFetchFullSizeThumbnail: true))
                                            }
                                            updateBlurredImageSignal = { synchronousLoad, _ in
                                                return chatSecretMessageVideo(account: context.account, userLocation: .peer(message.id.peerId), videoReference: .message(message: MessageReference(message), media: file), synchronousLoad: true)
                                            }
                                        }
                                    }
                                    
                                    var uploading = false
                                    if file.resource is VideoLibraryMediaResource {
                                        uploading = true
                                    }
                                    
                                    if file.isVideo && !file.isVideoSticker && !isSecretMedia && automaticPlayback && !uploading {
                                        updateVideoFile = file
                                        if hasCurrentVideoNode {
                                            if let currentFile = currentMedia as? TelegramMediaFile {
                                                if currentFile.resource is EmptyMediaResource {
                                                    replaceVideoNode = true
                                                } else if currentFile.fileId.namespace == Namespaces.Media.CloudFile && file.fileId.namespace == Namespaces.Media.CloudFile && currentFile.fileId != file.fileId {
                                                    replaceVideoNode = true
                                                } else if currentFile.fileId != file.fileId && file.fileId.namespace == Namespaces.Media.CloudSecretFile {
                                                    replaceVideoNode = true
                                                } else if file.isAnimated && currentFile.fileId.namespace == Namespaces.Media.LocalFile && file.fileId.namespace == Namespaces.Media.CloudFile {
                                                    replaceVideoNode = true
                                                }
                                            }
                                        } else if !(file.resource is LocalFileVideoMediaResource) {
                                            replaceVideoNode = true
                                        }
                                    } else {
                                        if hasCurrentVideoNode {
                                            replaceVideoNode = false
                                        }
                                        
                                        if file.isAnimatedSticker || file.isVideoSticker {
                                            updateAnimatedStickerFile = file
                                            if hasCurrentAnimatedStickerNode {
                                                if let currentMedia = currentMedia {
                                                    if !currentMedia.isSemanticallyEqual(to: file) {
                                                        replaceAnimatedStickerNode = true
                                                    }
                                                } else {
                                                    replaceAnimatedStickerNode = true
                                                }
                                            } else {
                                                replaceAnimatedStickerNode = true
                                            }
                                        }
                                    }
                                    
                                    updatedFetchControls = FetchControls(fetch: { manual in
                                        if let strongSelf = self {
                                            if file.isAnimated {
                                                strongSelf.fetchDisposable.set(fetchedMediaResource(mediaBox: context.account.postbox.mediaBox, userLocation: .peer(message.id.peerId), userContentType: MediaResourceUserContentType(file: file), reference: AnyMediaReference.message(message: MessageReference(message), media: file).resourceReference(file.resource), statsCategory: statsCategoryForFileWithAttributes(file.attributes)).startStrict())
                                            } else {
                                                strongSelf.fetchDisposable.set(messageMediaFileInteractiveFetched(context: context, message: message, file: file, userInitiated: manual, storeToDownloadsPeerId: storeToDownloadsPeerId).startStrict())
                                            }
                                        }
                                    }, cancel: {
                                        if file.isAnimated {
                                            context.account.postbox.mediaBox.cancelInteractiveResourceFetch(file.resource)
                                        } else {
                                            messageMediaFileCancelInteractiveFetch(context: context, messageId: message.id, file: file)
                                        }
                                    })
                                }
                            }
                        } else if let image = media as? TelegramMediaImage {
                            if hasCurrentVideoNode {
                                replaceVideoNode = true
                            }
                            if hasCurrentAnimatedStickerNode {
                                replaceAnimatedStickerNode = true
                            }
                            if isSecretMedia {
                                updateImageSignal = { synchronousLoad, _ in
                                    return chatSecretPhoto(account: context.account, userLocation: .peer(message.id.peerId), photoReference: .message(message: MessageReference(message), media: image), ignoreFullSize: true)
                                }
                            } else {
                                updateImageSignal = { synchronousLoad, highQuality in
                                    return chatMessagePhoto(postbox: context.account.postbox, userLocation: .peer(message.id.peerId), photoReference: .message(message: MessageReference(message), media: image), synchronousLoad: synchronousLoad, highQuality: highQuality)
                                }
                                updateBlurredImageSignal = { synchronousLoad, _ in
                                    return chatSecretPhoto(account: context.account, userLocation: .peer(message.id.peerId), photoReference: .message(message: MessageReference(message), media: image), ignoreFullSize: true, synchronousLoad: true)
                                }
                            }
                            
                            updatedFetchControls = FetchControls(fetch: { manual in
                                if let strongSelf = self {
                                    if let representation = largestRepresentationForPhoto(image) {
                                        strongSelf.fetchDisposable.set(messageMediaImageInteractiveFetched(context: context, message: message, image: image, resource: representation.resource, range: representationFetchRangeForDisplayAtSize(representation: representation, dimension: nil/*isSecretMedia ? nil : 600*/), userInitiated: manual, storeToDownloadsPeerId: storeToDownloadsPeerId).startStrict())
                                    }
                                }
                            }, cancel: {
                                chatMessagePhotoCancelInteractiveFetch(account: context.account, photoReference: .message(message: MessageReference(message), media: image))
                                if let resource = largestRepresentationForPhoto(image)?.resource {
                                    messageMediaImageCancelInteractiveFetch(context: context, messageId: message.id, image: image, resource: resource)
                                }
                            })
                        } else if let image = media as? TelegramMediaWebFile {
                            if hasCurrentVideoNode {
                                replaceVideoNode = true
                            }
                            if hasCurrentAnimatedStickerNode {
                                replaceAnimatedStickerNode = true
                            }
                            updateImageSignal = { synchronousLoad, _ in
                                return chatWebFileImage(account: context.account, file: image)
                            }
                            
                            updatedFetchControls = FetchControls(fetch: { _ in
                                if let strongSelf = self {
                                    strongSelf.fetchDisposable.set(chatMessageWebFileInteractiveFetched(account: context.account, userLocation: .peer(message.id.peerId), image: image).startStrict())
                                }
                            }, cancel: {
                                chatMessageWebFileCancelInteractiveFetch(account: context.account, image: image)
                            })
                        } else if let file = media as? TelegramMediaFile {
                            if isSecretMedia {
                                updateImageSignal = { synchronousLoad, _ in
                                    return chatSecretMessageVideo(account: context.account, userLocation: .peer(message.id.peerId), videoReference: .message(message: MessageReference(message), media: file))
                                }
                            } else {
                                if file.isAnimatedSticker {
                                    let dimensions = file.dimensions ?? PixelDimensions(width: 512, height: 512)
                                    updateImageSignal = { synchronousLoad, _ in
                                        return chatMessageAnimatedSticker(postbox: context.account.postbox, userLocation: .peer(message.id.peerId), file: file, small: false, size: dimensions.cgSize.aspectFitted(CGSize(width: 400.0, height: 400.0)))
                                    }
                                } else if file.isSticker || file.isVideoSticker {
                                    updateImageSignal = { synchronousLoad, _ in
                                        return chatMessageSticker(account: context.account, userLocation: .peer(message.id.peerId), file: file, small: false)
                                    }
                                } else {
                                    onlyFullSizeVideoThumbnail = isSendingUpdated
                                    updateImageSignal = { synchronousLoad, _ in
                                        return mediaGridMessageVideo(postbox: context.account.postbox, userLocation: .peer(message.id.peerId), videoReference: .message(message: MessageReference(message), media: file), onlyFullSize: currentMedia?.id?.namespace == Namespaces.Media.LocalFile, autoFetchFullSizeThumbnail: true)
                                    }
                                    updateBlurredImageSignal = { synchronousLoad, _ in
                                        return chatSecretMessageVideo(account: context.account, userLocation: .peer(message.id.peerId), videoReference: .message(message: MessageReference(message), media: file), synchronousLoad: true)
                                    }
                                }
                            }
                            
                            var uploading = false
                            if file.resource is VideoLibraryMediaResource {
                                uploading = true
                            }
                            
                            if file.isVideo && !file.isVideoSticker && !isSecretMedia && automaticPlayback && !uploading {
                                updateVideoFile = file
                                if hasCurrentVideoNode {
                                    if let currentFile = currentMedia as? TelegramMediaFile {
                                        if currentFile.resource is EmptyMediaResource {
                                            replaceVideoNode = true
                                        } else if currentFile.fileId.namespace == Namespaces.Media.CloudFile && file.fileId.namespace == Namespaces.Media.CloudFile && currentFile.fileId != file.fileId {
                                            replaceVideoNode = true
                                        } else if currentFile.fileId != file.fileId && file.fileId.namespace == Namespaces.Media.CloudSecretFile {
                                            replaceVideoNode = true
                                        } else if file.isAnimated && currentFile.fileId.namespace == Namespaces.Media.LocalFile && file.fileId.namespace == Namespaces.Media.CloudFile {
                                            replaceVideoNode = true
                                        }
                                    }
                                } else if !(file.resource is LocalFileVideoMediaResource) {
                                    replaceVideoNode = true
                                }
                            } else {
                                if hasCurrentVideoNode {
                                    replaceVideoNode = false
                                }
                                
                                if file.isAnimatedSticker || file.isVideoSticker {
                                    updateAnimatedStickerFile = file
                                    if hasCurrentAnimatedStickerNode {
                                        if let currentMedia = currentMedia {
                                            if !currentMedia.isSemanticallyEqual(to: file) {
                                                replaceAnimatedStickerNode = true
                                            }
                                        } else {
                                            replaceAnimatedStickerNode = true
                                        }
                                    } else {
                                        replaceAnimatedStickerNode = true
                                    }
                                }
                            }
                            
                            updatedFetchControls = FetchControls(fetch: { manual in
                                if let strongSelf = self {
                                    if file.isAnimated {
                                        strongSelf.fetchDisposable.set(fetchedMediaResource(mediaBox: context.account.postbox.mediaBox, userLocation: .peer(message.id.peerId), userContentType: MediaResourceUserContentType(file: file), reference: AnyMediaReference.message(message: MessageReference(message), media: file).resourceReference(file.resource), statsCategory: statsCategoryForFileWithAttributes(file.attributes)).startStrict())
                                    } else {
                                        strongSelf.fetchDisposable.set(messageMediaFileInteractiveFetched(context: context, message: message, file: file, userInitiated: manual, storeToDownloadsPeerId: storeToDownloadsPeerId).startStrict())
                                    }
                                }
                            }, cancel: {
                                if file.isAnimated {
                                    context.account.postbox.mediaBox.cancelInteractiveResourceFetch(file.resource)
                                } else {
                                    messageMediaFileCancelInteractiveFetch(context: context, messageId: message.id, file: file)
                                }
                            })
                        } else if let wallpaper = media as? WallpaperPreviewMedia {
                            updateImageSignal = { synchronousLoad, _ in
                                switch wallpaper.content {
                                    case let .file(file, _, _, _, isTheme, _):
                                        if isTheme {
                                            return themeImage(account: context.account, accountManager: context.sharedContext.accountManager, source: .file(FileMediaReference.message(message: MessageReference(message), media: file)), synchronousLoad: synchronousLoad)
                                        } else {
                                            var representations: [ImageRepresentationWithReference] = file.previewRepresentations.map({ ImageRepresentationWithReference(representation: $0, reference: AnyMediaReference.message(message: MessageReference(message), media: file).resourceReference($0.resource)) })
                                            if file.mimeType == "image/svg+xml" || file.mimeType == "application/x-tgwallpattern" {
                                                representations.append(ImageRepresentationWithReference(representation: .init(dimensions: PixelDimensions(width: 1440, height: 2960), resource: file.resource, progressiveSizes: [], immediateThumbnailData: nil, hasVideo: false, isPersonal: false), reference: AnyMediaReference.message(message: MessageReference(message), media: file).resourceReference(file.resource)))
                                            }
                                            if ["image/png", "image/svg+xml", "application/x-tgwallpattern"].contains(file.mimeType) {
                                                return patternWallpaperImage(account: context.account, accountManager: context.sharedContext.accountManager, representations: representations, mode: .screen)
                                                |> mapToSignal { value -> Signal<(TransformImageArguments) -> DrawingContext?, NoError> in
                                                    if let value = value {
                                                        return .single(value)
                                                    } else {
                                                        return .complete()
                                                    }
                                                }
                                            } else {
                                                return wallpaperImage(account: context.account, accountManager: context.sharedContext.accountManager, fileReference: FileMediaReference.message(message: MessageReference(message), media: file), representations: representations, alwaysShowThumbnailFirst: false, thumbnail: true, autoFetchFullSize: true, synchronousLoad: synchronousLoad)
                                            }
                                        }
                                    case let .image(representations):
                                        return wallpaperImage(account: context.account, accountManager: context.sharedContext.accountManager, fileReference: nil, representations: representations.map({ ImageRepresentationWithReference(representation: $0, reference: .standalone(resource: $0.resource)) }), alwaysShowThumbnailFirst: false, thumbnail: true, autoFetchFullSize: true)
                                    case let .themeSettings(settings):
                                        return themeImage(account: context.account, accountManager: context.sharedContext.accountManager, source: .settings(settings))
                                    case let .color(color):
                                        return solidColorImage(color)
                                    case let .gradient(colors, rotation):
                                        return gradientImage(colors.map(UIColor.init(rgb:)), rotation: rotation ?? 0)
                                    case .emoticon:
                                        return solidColorImage(.black)
                                }
                            }
                            
                            if case let .file(file, _, _, _, _, _) = wallpaper.content {
                                updatedFetchControls = FetchControls(fetch: { manual in
                                    if let strongSelf = self {
                                        strongSelf.fetchDisposable.set(messageMediaFileInteractiveFetched(context: context, message: message, file: file, userInitiated: manual).startStrict())
                                    }
                                }, cancel: {
                                    messageMediaFileCancelInteractiveFetch(context: context, messageId: message.id, file: file)
                                })
                            } else if case .themeSettings = wallpaper.content {
                            } else {
                                boundingSize = CGSize(width: boundingSize.width, height: boundingSize.width)
                            }
                        }
                    }
                    
                    var isExtendedMedia = false
                    if statusUpdated {
                        var media = media
                        var extendedMedia: TelegramExtendedMedia?
                        if let invoice = media as? TelegramMediaInvoice, let selectedMedia = invoice.extendedMedia {
                            extendedMedia = selectedMedia
                        } else if let paidContent = media as? TelegramMediaPaidContent {
                            let selectedMediaIndex = mediaIndex ?? 0
                            if selectedMediaIndex < paidContent.extendedMedia.count {
                                extendedMedia = paidContent.extendedMedia[selectedMediaIndex]
                            }
                        }
                        if let extendedMedia, case let .full(fullMedia) = extendedMedia, !presentationData.isPreview {
                            isExtendedMedia = true
                            media = fullMedia
                        }
                        if let storyMedia = media as? TelegramMediaStory, let storyItem = message.associatedStories[storyMedia.storyId]?.get(Stories.StoredItem.self) {
                            if case let .item(item) = storyItem, let mediaValue = selectStoryMedia(item: item, preferredHighQuality: associatedData.preferredStoryHighQuality) {
                                media = mediaValue
                            }
                        }
                        
                        if let image = media as? TelegramMediaImage {
                            if message.flags.isSending {
                                updatedStatusSignal = combineLatest(chatMessagePhotoStatus(context: context, messageId: message.id, photoReference: .message(message: MessageReference(message), media: image)), context.account.pendingMessageManager.pendingMessageStatus(message.id) |> map { $0.0 })
                                |> map { resourceStatus, pendingStatus -> (MediaResourceStatus, MediaResourceStatus?) in
                                    if let pendingStatus = pendingStatus {
                                        var progress: Float = pendingStatus.progress.progress
                                        if let id = media.id, let mediaProgress = pendingStatus.progress.mediaProgress[id] {
                                            progress = mediaProgress
                                        }
                                        let adjustedProgress = max(progress, 0.027)
                                        return (.Fetching(isActive: pendingStatus.isRunning, progress: adjustedProgress), resourceStatus)
                                    } else {
                                        return (resourceStatus, nil)
                                    }
                                }
                            } else {
                                updatedStatusSignal = chatMessagePhotoStatus(context: context, messageId: message.id, photoReference: .message(message: MessageReference(message), media: image), displayAtSize: nil)
                                |> map { resourceStatus -> (MediaResourceStatus, MediaResourceStatus?) in
                                    return (resourceStatus, nil)
                                }
                            }
                        } else if let file = media as? TelegramMediaFile {
                            updatedStatusSignal = combineLatest(messageMediaFileStatus(context: context, messageId: message.id, file: file, adjustForVideoThumbnail: true), context.account.pendingMessageManager.pendingMessageStatus(message.id) |> map { $0.0 })
                                |> map { resourceStatus, pendingStatus -> (MediaResourceStatus, MediaResourceStatus?) in
                                    if let pendingStatus = pendingStatus {
                                        var progress: Float = pendingStatus.progress.progress
                                        if let id = media.id, let mediaProgress = pendingStatus.progress.mediaProgress[id] {
                                            progress = mediaProgress
                                        }
                                        let adjustedProgress = max(progress, 0.027)
                                        return (.Fetching(isActive: pendingStatus.isRunning, progress: adjustedProgress), resourceStatus)
                                    } else {
                                        return (resourceStatus, nil)
                                    }
                            }
                        } else if let wallpaper = media as? WallpaperPreviewMedia {
                            switch wallpaper.content {
                                case let .file(file, _, _, _, _, _):
                                    updatedStatusSignal = messageMediaFileStatus(context: context, messageId: message.id, file: file)
                                    |> map { resourceStatus -> (MediaResourceStatus, MediaResourceStatus?) in
                                        return (resourceStatus, nil)
                                    }
                                case .themeSettings, .color, .gradient, .image, .emoticon:
                                    updatedStatusSignal = .single((.Local, nil))
                            }
                        }
                    }

                    var videoCorners = corners
                    var imageCorners = corners
                    if let file = media as? TelegramMediaFile, file.isInstantVideo {
                        videoCorners = ImageCorners(radius: boundingSize.width / 2.0)
                        imageCorners = ImageCorners(radius: 0.0)
                    }
                    
                    let arguments = TransformImageArguments(corners: imageCorners, imageSize: drawingSize, boundingSize: boundingSize, intrinsicInsets: UIEdgeInsets(), resizeMode: isInlinePlayableVideo ? .fill(.black) : .blurBackground, emptyColor: emptyColor, custom: patternArguments)
                    
                    let imageFrame = CGRect(origin: CGPoint(x: -arguments.insets.left, y: -arguments.insets.top), size: arguments.drawingSize).ensuredValid
                    let cleanImageFrame = CGRect(origin: imageFrame.origin, size: CGSize(width: imageFrame.width - arguments.corners.extendedEdges.right, height: imageFrame.height))
                    
                    let imageApply = imageLayout(arguments)
                    
                    return (boundingSize, { transition, synchronousLoads in
                        if let strongSelf = self {
                            strongSelf.context = context
                            strongSelf.message = message
                            strongSelf.attributes = attributes
                            strongSelf.media = media
                            strongSelf.mediaIndex = mediaIndex
                            strongSelf.wideLayout = wideLayout
                            strongSelf.themeAndStrings = (presentationData.theme.theme, presentationData.strings, dateTimeFormat.decimalSeparator, presentationData.isPreview)
                            strongSelf.sizeCalculation = sizeCalculation
                            strongSelf.automaticPlayback = automaticPlayback
                            strongSelf.automaticDownload = automaticDownload
                            strongSelf.preferredStoryHighQuality = associatedData.preferredStoryHighQuality
                            strongSelf.showSensitiveContent = associatedData.showSensitiveContent
                                                        
                            if let previousArguments = strongSelf.currentImageArguments {
                                if previousArguments.imageSize == arguments.imageSize {
                                    strongSelf.pinchContainerNode.frame = imageFrame
                                    strongSelf.pinchContainerNode.update(size: imageFrame.size, transition: .immediate)
                                    strongSelf.imageNode.frame = CGRect(origin: CGPoint(), size: imageFrame.size)
                                } else {
                                    transition.animator.updateFrame(layer: strongSelf.pinchContainerNode.layer, frame: imageFrame, completion: nil)
                                    transition.animator.updateFrame(layer: strongSelf.imageNode.layer, frame: CGRect(origin: CGPoint(), size: imageFrame.size), completion: nil)
                                    strongSelf.pinchContainerNode.update(size: imageFrame.size, transition: transition.transition)
                                    
                                }
                            } else {
                                strongSelf.pinchContainerNode.frame = imageFrame
                                strongSelf.pinchContainerNode.update(size: imageFrame.size, transition: .immediate)
                                strongSelf.imageNode.frame = CGRect(origin: CGPoint(), size: imageFrame.size)
                            }
                            strongSelf.currentImageArguments = arguments
                            imageApply()

                            if let statusApply = statusApply {
                                let dateAndStatusFrame = CGRect(origin: CGPoint(x: cleanImageFrame.width - layoutConstants.image.statusInsets.right - statusSize.width, y: cleanImageFrame.height - layoutConstants.image.statusInsets.bottom - statusSize.height), size: statusSize)
                                if strongSelf.dateAndStatusNode.supernode == nil {
                                    strongSelf.dateAndStatusNode.view.tag = 0xFACE
                                    strongSelf.pinchContainerNode.contentNode.addSubnode(strongSelf.dateAndStatusNode)
                                    statusApply(.None)
                                    strongSelf.dateAndStatusNode.frame = dateAndStatusFrame
                                } else {
                                    transition.animator.updateFrame(layer: strongSelf.dateAndStatusNode.layer, frame: dateAndStatusFrame, completion: nil)
                                    statusApply(transition)
                                }
                                
                                if messageEffect != nil {
                                    strongSelf.dateAndStatusNode.pressed = { [weak strongSelf] in
                                        guard let strongSelf, let message = strongSelf.message else {
                                            return
                                        }
                                        strongSelf.playMessageEffect?(message)
                                    }
                                } else {
                                    strongSelf.dateAndStatusNode.pressed = nil
                                }
                            } else if strongSelf.dateAndStatusNode.supernode != nil {
                                strongSelf.dateAndStatusNode.removeFromSupernode()
                                strongSelf.dateAndStatusNode.pressed = nil
                            }
                            
                            if let statusNode = strongSelf.statusNode {
                                var statusFrame = statusNode.frame
                                statusFrame.origin.x = floor(imageFrame.width / 2.0 - statusFrame.width / 2.0)
                                statusFrame.origin.y = floor(imageFrame.height / 2.0 - statusFrame.height / 2.0)
                                statusNode.frame = statusFrame
                            }
                                                        
                            var updatedVideoNodeReadySignal: Signal<Void, NoError>?
                            var updatedPlayerStatusSignal: Signal<MediaPlayerStatus?, NoError>?
                            if let currentReplaceVideoNode = replaceVideoNode {
                                replaceVideoNode = nil
                                if let videoNode = strongSelf.videoNode {
                                    videoNode.canAttachContent = false
                                    videoNode.removeFromSupernode()
                                    strongSelf.videoNode = nil
                                }
                                
                                if currentReplaceVideoNode, let updatedVideoFile = updateVideoFile {
                                    let decoration = ChatBubbleVideoDecoration(corners: videoCorners, nativeSize: nativeSize, contentMode: contentMode.bubbleVideoDecorationContentMode, backgroundColor: arguments.emptyColor ?? .black)
                                    strongSelf.videoNodeDecoration = decoration
                                    let mediaManager = context.sharedContext.mediaManager
                                    
                                    let streamVideo = isMediaStreamable(message: message, media: updatedVideoFile)
                                    let loopVideo = updatedVideoFile.isAnimated
                                    let videoContent = NativeVideoContent(id: .message(message.stableId, updatedVideoFile.fileId), userLocation: .peer(message.id.peerId), fileReference: .message(message: MessageReference(message), media: updatedVideoFile), streamVideo: streamVideo ? .conservative : .none, loopVideo: loopVideo, enableSound: false, fetchAutomatically: false, onlyFullSizeThumbnail: (onlyFullSizeVideoThumbnail ?? false), continuePlayingWithoutSoundOnLostAudioSession: isInlinePlayableVideo, placeholderColor: emptyColor, captureProtected: message.isCopyProtected() || isExtendedMedia, storeAfterDownload: { [weak context] in
                                        guard let context, let peerId else {
                                            return
                                        }
                                        let _ = storeDownloadedMedia(storeManager: context.downloadedMediaStoreManager, media: .message(message: MessageReference(message), media: updatedVideoFile), peerId: peerId).startStandalone()
                                    })
                                    let videoNode = UniversalVideoNode(postbox: context.account.postbox, audioSession: mediaManager.audioSession, manager: mediaManager.universalVideoManager, decoration: decoration, content: videoContent, priority: .embedded)
                                    videoNode.isUserInteractionEnabled = false
                                    videoNode.ownsContentNodeUpdated = { [weak self] owns in
                                        if let strongSelf = self {
                                            strongSelf.videoNode?.isHidden = !owns
                                            if owns {
                                                strongSelf.videoNode?.setBaseRate(1.0)
                                                strongSelf.videoNode?.continuePlayingWithoutSound()
                                            }
                                        }
                                    }
                                    strongSelf.videoContent = videoContent
                                    strongSelf.videoNode = videoNode
                                    
                                    if presentationData.isPreview {
                                        videoNode.isHidden = true
                                        strongSelf.pinchContainerNode.contentNode.insertSubnode(videoNode, aboveSubnode: strongSelf.imageNode)
                                    }
                                    
                                    updatedVideoNodeReadySignal = videoNode.ready
                                    updatedPlayerStatusSignal = videoNode.status
                                    |> mapToSignal { status -> Signal<MediaPlayerStatus?, NoError> in
                                        if let status = status, case .buffering = status.status {
                                            return .single(status) |> delay(0.5, queue: Queue.mainQueue())
                                        } else {
                                            return .single(status)
                                        }
                                    }
                                }
                            }
                            
                            if let currentReplaceAnimatedStickerNode = replaceAnimatedStickerNode {
                                replaceAnimatedStickerNode = nil
                                if currentReplaceAnimatedStickerNode, let animatedStickerNode = strongSelf.animatedStickerNode {
                                    animatedStickerNode.removeFromSupernode()
                                    strongSelf.animatedStickerNode = nil
                                }
                                
                                if currentReplaceAnimatedStickerNode, let updatedAnimatedStickerFile = updateAnimatedStickerFile {
                                    let animatedStickerNode = DefaultAnimatedStickerNodeImpl()
                                    animatedStickerNode.isUserInteractionEnabled = false
                                    animatedStickerNode.started = {
                                        guard let strongSelf = self else {
                                            return
                                        }
                                        strongSelf.imageNode.isHidden = true
                                    }
                                    strongSelf.animatedStickerNode = animatedStickerNode
                                    let dimensions = updatedAnimatedStickerFile.dimensions ?? PixelDimensions(width: 512, height: 512)
                                    let fittedDimensions = dimensions.cgSize.aspectFitted(CGSize(width: 384.0, height: 384.0))
                                    animatedStickerNode.setup(source: AnimatedStickerResourceSource(account: context.account, resource: updatedAnimatedStickerFile.resource, isVideo: updatedAnimatedStickerFile.isVideo), width: Int(fittedDimensions.width), height: Int(fittedDimensions.height), mode: .direct(cachePathPrefix: nil))
                                    strongSelf.pinchContainerNode.contentNode.insertSubnode(animatedStickerNode, aboveSubnode: strongSelf.imageNode)
                                    animatedStickerNode.visibility = strongSelf.visibility
                                }
                            }
                            
                            
                            if message.attributes.contains(where: { $0 is MediaSpoilerMessageAttribute }), strongSelf.extendedMediaOverlayNode == nil {
                                strongSelf.internallyVisible = false
                            }
                                                        
                            if let videoNode = strongSelf.videoNode {
                                if !(replaceVideoNode ?? false), let decoration = videoNode.decoration as? ChatBubbleVideoDecoration, decoration.corners != videoCorners {
                                    decoration.updateCorners(videoCorners)
                                }
                                
                                if !videoCorners.isEmpty && imageCorners.isEmpty {
                                    strongSelf.imageNode.clipsToBounds = true
                                    strongSelf.imageNode.cornerRadius = videoCorners.topLeft.radius
                                } else {
                                    strongSelf.imageNode.cornerRadius = 0.0
                                }
                                
                                videoNode.updateLayout(size: arguments.drawingSize, transition: .immediate)
                                videoNode.frame = CGRect(origin: CGPoint(), size: imageFrame.size)
                                
                                if strongSelf.visibility && strongSelf.internallyVisible && !presentationData.isPreview {
                                    if !videoNode.canAttachContent {
                                        videoNode.canAttachContent = true
                                        if videoNode.hasAttachedContext {
                                            videoNode.play()
                                        }
                                    }
                                } else {
                                    videoNode.canAttachContent = false
                                }
                            }
                            
                            if let animatedStickerNode = strongSelf.animatedStickerNode {
                                animatedStickerNode.frame = imageFrame
                                animatedStickerNode.updateLayout(size: imageFrame.size)
                            }
                            
                            if let updateImageSignal = updateImageSignal {
                                strongSelf.imageNode.captureProtected = message.isCopyProtected() || isExtendedMedia
                                strongSelf.imageNode.setSignal(updateImageSignal(synchronousLoads, false), attemptSynchronously: synchronousLoads)

                                var imageDimensions: CGSize?
                                if let image = media as? TelegramMediaImage, let dimensions = largestImageRepresentation(image.representations)?.dimensions {
                                    imageDimensions = dimensions.cgSize
                                } else if let file = media as? TelegramMediaFile, let dimensions = file.dimensions {
                                    imageDimensions = dimensions.cgSize
                                } else if let image = media as? TelegramMediaWebFile, let dimensions = image.dimensions {
                                    imageDimensions = dimensions.cgSize
                                }

                                if let imageDimensions = imageDimensions {
                                    strongSelf.currentHighQualityImageSignal = (updateImageSignal(false, true), imageDimensions)
                                    
                                    if let updateBlurredImageSignal = updateBlurredImageSignal {
                                        strongSelf.currentBlurredImageSignal = (updateBlurredImageSignal(false, true), drawingSize, boundingSize, Int32.random(in: 0..<Int32.max))
                                    }
                                }
                            }
                                                        
                            if let _ = secretBeginTimeAndTimeout {
                                if updatedStatusSignal == nil, let fetchStatus = strongSelf.fetchStatus, case .Local = fetchStatus {
                                    if let statusNode = strongSelf.statusNode, case .secretTimeout = statusNode.state {   
                                    } else {
                                        updatedStatusSignal = .single((fetchStatus, nil))
                                    }
                                }
                            }
                            
                            if let updatedStatusSignal = updatedStatusSignal {
                                strongSelf.statusDisposable.set((updatedStatusSignal
                                |> deliverOnMainQueue).startStrict(next: { [weak strongSelf] status, actualFetchStatus in
                                    displayLinkDispatcher.dispatch {
                                        if let strongSelf = strongSelf {
                                            strongSelf.fetchStatus = status
                                            strongSelf.actualFetchStatus = actualFetchStatus
                                            strongSelf.updateStatus(animated: synchronousLoads)
                                        }
                                    }
                                }))
                            }
                            
                            if let updatedVideoNodeReadySignal = updatedVideoNodeReadySignal {
                                strongSelf.videoNodeReadyDisposable.set((updatedVideoNodeReadySignal
                                |> deliverOnMainQueue).startStrict(next: { [weak strongSelf] status in
                                    displayLinkDispatcher.dispatch {
                                        if let strongSelf = strongSelf, let videoNode = strongSelf.videoNode {
                                            strongSelf.pinchContainerNode.contentNode.insertSubnode(videoNode, aboveSubnode: strongSelf.imageNode)
                                        }
                                    }
                                }))
                            }
                            
                            if let updatedPlayerStatusSignal = updatedPlayerStatusSignal {
                                strongSelf.playerStatusDisposable.set((updatedPlayerStatusSignal
                                |> deliverOnMainQueue).startStrict(next: { [weak strongSelf] status in
                                    displayLinkDispatcher.dispatch {
                                        if let strongSelf = strongSelf {
                                            strongSelf.playerStatus = status
                                        }
                                    }
                                }))
                            }
                            
                            if let updatedFetchControls = updatedFetchControls {
                                let _ = strongSelf.fetchControls.swap(updatedFetchControls)
                                
                                var media = media
                                var extendedMedia: TelegramExtendedMedia?
                                if let invoice = media as? TelegramMediaInvoice, let selectedMedia = invoice.extendedMedia {
                                    extendedMedia = selectedMedia
                                } else if let paidContent = media as? TelegramMediaPaidContent {
                                    let selectedMediaIndex = mediaIndex ?? 0
                                    if selectedMediaIndex < paidContent.extendedMedia.count {
                                        extendedMedia = paidContent.extendedMedia[selectedMediaIndex]
                                    }
                                }
                                if let extendedMedia, case let .full(fullMedia) = extendedMedia {
                                    media = fullMedia
                                }
                                if let storyMedia = media as? TelegramMediaStory, let storyItem = message.associatedStories[storyMedia.storyId]?.get(Stories.StoredItem.self) {
                                    if case let .item(item) = storyItem, let mediaValue = selectStoryMedia(item: item, preferredHighQuality: associatedData.preferredStoryHighQuality) {
                                        media = mediaValue
                                    }
                                }
                                
                                if case .full = automaticDownload {
                                    if let _ = media as? TelegramMediaImage {
                                        updatedFetchControls.fetch(false)
                                    } else if let image = media as? TelegramMediaWebFile {
                                        strongSelf.fetchDisposable.set(chatMessageWebFileInteractiveFetched(account: context.account, userLocation: .peer(message.id.peerId), image: image).startStrict())
                                    } else if let file = media as? TelegramMediaFile {
                                        let fetchSignal = messageMediaFileInteractiveFetched(context: context, message: message, file: file, userInitiated: false, storeToDownloadsPeerId: peerId)
                                        let visibilityAwareFetchSignal = strongSelf.visibilityPromise.get()
                                        |> mapToSignal { visibility -> Signal<Void, NoError> in
                                            if visibility {
                                                return fetchSignal
                                                |> mapToSignal { _ -> Signal<Void, NoError> in
                                                    return .complete()
                                                }
                                            } else {
                                                return .complete()
                                            }
                                        }
                                        strongSelf.fetchDisposable.set(visibilityAwareFetchSignal.startStrict())
                                    }
                                } else if case .prefetch = automaticDownload, message.id.namespace != Namespaces.Message.SecretIncoming /*&& message.id.namespace != Namespaces.Message.Local*/ {
                                    if let file = media as? TelegramMediaFile {
                                        let fetchSignal = preloadVideoResource(postbox: context.account.postbox, userLocation: .peer(message.id.peerId), userContentType: MediaResourceUserContentType(file: file), resourceReference: AnyMediaReference.message(message: MessageReference(message), media: file).resourceReference(file.resource), duration: 4.0)
                                        let visibilityAwareFetchSignal = strongSelf.visibilityPromise.get()
                                        |> mapToSignal { visibility -> Signal<Void, NoError> in
                                            if visibility {
                                                return fetchSignal
                                                |> mapToSignal { _ -> Signal<Void, NoError> in
                                                }
                                            } else {
                                                return .complete()
                                            }
                                        }
                                        strongSelf.fetchDisposable.set(visibilityAwareFetchSignal.startStrict())
                                    }
                                }
                            } else if currentAutomaticDownload != automaticDownload, case .full = automaticDownload {
                                strongSelf.fetchControls.with({ $0 })?.fetch(false)
                            }
                            
                            strongSelf.updateStatus(animated: synchronousLoads)

                            strongSelf.pinchContainerNode.isPinchGestureEnabled = !isSecretMedia && !isExtendedMediaPreview && !hasSpoiler
                        }
                    })
                })
            })
        }
    }
    
    private func ensureHasTimer() {
        if self.playerUpdateTimer == nil {
            let timer = SwiftSignalKit.Timer(timeout: 0.5, repeat: true, completion: { [weak self] in
                self?.updateStatus(animated: false)
                }, queue: Queue.mainQueue())
            self.playerUpdateTimer = timer
            timer.start()
        }
    }
    
    private func stopTimer() {
        self.playerUpdateTimer?.invalidate()
        self.playerUpdateTimer = nil
    }
    
    private func updateStatus(animated: Bool) {
        guard let (theme, strings, decimalSeparator, isPreview) = self.themeAndStrings, let sizeCalculation = self.sizeCalculation, let message = self.message, let attributes = self.attributes, var automaticPlayback = self.automaticPlayback, let wideLayout = self.wideLayout else {
            return
        }
        
        /*let automaticDownload: Bool
        if let autoDownload = self.automaticDownload, case .full = autoDownload {
            automaticDownload = true
        } else {
            automaticDownload = false
        }*/
        
        var secretBeginTimeAndTimeout: (Double?, Double)?
        let isSecretMedia = message.containsSecretMedia
        if isSecretMedia {
            if let attribute = message.autoclearAttribute {
                if let countdownBeginTime = attribute.countdownBeginTime {
                    secretBeginTimeAndTimeout = (Double(countdownBeginTime), Double(attribute.timeout))
                }
            } else if let attribute = message.autoremoveAttribute {
                if let countdownBeginTime = attribute.countdownBeginTime {
                    secretBeginTimeAndTimeout = (Double(countdownBeginTime), Double(attribute.timeout))
                }
            }
        }
        
        var isStory: Bool = false
        
        var game: TelegramMediaGame?
        var webpage: TelegramMediaWebpage?
        var invoice: TelegramMediaInvoice?
        var paidContent: TelegramMediaPaidContent?
        for media in message.media {
            if let media = media as? TelegramMediaWebpage {
                webpage = media
            } else if let media = media as? TelegramMediaInvoice {
                invoice = media
            } else if let media = media as? TelegramMediaPaidContent {
                paidContent = media
            } else if let media = media as? TelegramMediaGame {
                game = media
            } else if let _ = media as? TelegramMediaStory {
                isStory = true
                automaticPlayback = false
            }
        }
        
        var progressRequired = false
        if let updatingMedia = attributes.updatingMedia, case .update = updatingMedia.media {
            progressRequired = true
        } else if secretBeginTimeAndTimeout?.0 != nil {
            progressRequired = true
        } else if let fetchStatus = self.fetchStatus {
            switch fetchStatus {
                case .Local:
                    if let file = media as? TelegramMediaFile, file.isVideo && !file.isVideoSticker {
                        progressRequired = true
                    } else if isSecretMedia {
                        progressRequired = true
                    } else if let webpage = webpage, case let .Loaded(content) = webpage.content {
                        if content.embedUrl != nil {
                            progressRequired = true
                        } else if let file = content.file, file.isVideo, !file.isAnimated && !file.isVideoSticker {
                            progressRequired = true
                        }
                    } else if isStory {
                        progressRequired = true
                    }
                case .Remote, .Fetching, .Paused:
                    if let webpage = webpage, let automaticDownload = self.automaticDownload, case .full = automaticDownload, case let .Loaded(content) = webpage.content {
                        if content.type == "telegram_background" {
                            progressRequired = true
                        } else if content.embedUrl != nil {
                            progressRequired = true
                        } else if let file = content.file, file.isVideo, !file.isAnimated {
                            progressRequired = true
                        }
                    } else {
                        progressRequired = true
                    }
            }
        }
        if isPreview {
            progressRequired = true
        }
        
        var radialStatusSize: CGFloat
        if isSecretMedia {
            radialStatusSize = 48.0
        } else {
            radialStatusSize = wideLayout ? 50.0 : 32.0
        }
        if progressRequired {
            if self.statusNode == nil {
                let statusNode = RadialStatusNode(backgroundNodeColor: theme.chat.message.mediaOverlayControlColors.fillColor, isPreview: isPreview)
                statusNode.displaysAsynchronously = !isPreview
                let imageSize = self.imageNode.bounds.size
                statusNode.frame = CGRect(origin: CGPoint(x: floor(imageSize.width / 2.0 - radialStatusSize / 2.0), y: floor(imageSize.height / 2.0 - radialStatusSize / 2.0)), size: CGSize(width: radialStatusSize, height: radialStatusSize))
                self.statusNode = statusNode
                self.pinchContainerNode.contentNode.addSubnode(statusNode)
            }
        } else {
            if let statusNode = self.statusNode {
                statusNode.transitionToState(.none, completion: { [weak statusNode] in
                    statusNode?.removeFromSupernode()
                })
                self.statusNode = nil
            }
        }
        
        let messageTheme = theme.chat.message
        
        var state: RadialStatusNodeState = .none
        var backgroundColor = messageTheme.mediaOverlayControlColors.fillColor
        var badgeContent: ChatMessageInteractiveMediaBadgeContent?
        var mediaDownloadState: ChatMessageInteractiveMediaDownloadState?
        
        if isSecretMedia {
            backgroundColor = messageTheme.mediaDateAndStatusFillColor
        }
        
        if let invoice = invoice, invoice.currency != "XTR" {
            if let extendedMedia = invoice.extendedMedia {
                if case let .preview(_, _, maybeVideoDuration) = extendedMedia, let videoDuration = maybeVideoDuration {
                    badgeContent = .text(inset: 0.0, backgroundColor: messageTheme.mediaDateAndStatusFillColor, foregroundColor: messageTheme.mediaDateAndStatusTextColor, text: NSAttributedString(string: stringForDuration(videoDuration, position: nil)), iconName: nil)
                }
            } else {
                let string = NSMutableAttributedString()
                if invoice.receiptMessageId != nil {
                    var title = strings.Checkout_Receipt_Title.uppercased()
                    if invoice.flags.contains(.isTest) {
                        title += " (Test)"
                    }
                    string.append(NSAttributedString(string: title))
                } else {
                    string.append(NSAttributedString(string: "\(formatCurrencyAmount(invoice.totalAmount, currency: invoice.currency)) ", attributes: [ChatTextInputAttributes.bold: true as NSNumber]))
                    
                    var title = strings.Message_InvoiceLabel
                    if invoice.flags.contains(.isTest) {
                        title += " (Test)"
                    }
                    string.append(NSAttributedString(string: title))
                }
                badgeContent = .text(inset: 0.0, backgroundColor: messageTheme.mediaDateAndStatusFillColor, foregroundColor: messageTheme.mediaDateAndStatusTextColor, text: string, iconName: nil)
            }
        }
        
        let gifTitle = game != nil ? strings.Message_Game.uppercased() : strings.Message_Animation.uppercased()
        
        var animated = animated
        if let updatingMedia = attributes.updatingMedia, case .update = updatingMedia.media {
            state = .progress(color: messageTheme.mediaOverlayControlColors.foregroundColor, lineWidth: nil, value: CGFloat(updatingMedia.progress), cancelEnabled: true, animateRotation: true)
        } else if var fetchStatus = self.fetchStatus {
            var playerPosition: Int32?
            var playerDuration: Int32 = 0
            var active = false
            var muted = automaticPlayback
            if let playerStatus = self.playerStatus {
                if !playerStatus.generationTimestamp.isZero, case .playing = playerStatus.status {
                    playerPosition = Int32(playerStatus.timestamp + (CACurrentMediaTime() - playerStatus.generationTimestamp))
                } else {
                    playerPosition = Int32(playerStatus.timestamp)
                }
                playerDuration = Int32(playerStatus.duration)
                if case .buffering = playerStatus.status {
                    active = true
                }
                if playerStatus.soundEnabled {
                    muted = false
                }
            } else if case .Fetching = fetchStatus, !message.flags.contains(.Unsent) {
                active = true
            }
            
            if let file = self.media as? TelegramMediaFile, file.isAnimated {
                muted = false
                
                if case .Fetching = fetchStatus, message.flags.isSending, file.resource is CloudDocumentMediaResource {
                    fetchStatus = .Local
                }
            }
            
            if message.flags.contains(.Unsent) {
                automaticPlayback = false
            }
            
            if isPreview {
                muted = false
            }
            
            if let actualFetchStatus = self.actualFetchStatus {
                if automaticPlayback || message.forwardInfo != nil {
                    fetchStatus = actualFetchStatus
                } else {
                    for attribute in message.attributes {
                        if let attribute = attribute as? ForwardOptionsMessageAttribute, attribute.hideNames {
                            fetchStatus = actualFetchStatus
                            break
                        }
                    }
                }
            }
                        
            let formatting = DataSizeStringFormatting(strings: strings, decimalSeparator: decimalSeparator)
            
            var media = self.media
            var extendedMedia: TelegramExtendedMedia?
            if let invoice = media as? TelegramMediaInvoice, let selectedMedia = invoice.extendedMedia {
                extendedMedia = selectedMedia
            } else if let paidContent = media as? TelegramMediaPaidContent {
                let selectedMediaIndex = self.mediaIndex ?? 0
                if selectedMediaIndex < paidContent.extendedMedia.count {
                    extendedMedia = paidContent.extendedMedia[selectedMediaIndex]
                }
            }
            if let extendedMedia, case let .full(fullMedia) = extendedMedia {
                media = fullMedia
            }
            if let storyMedia = media as? TelegramMediaStory, let storyItem = message.associatedStories[storyMedia.storyId]?.get(Stories.StoredItem.self) {
                if case let .item(item) = storyItem, let mediaValue = selectStoryMedia(item: item, preferredHighQuality: self.preferredStoryHighQuality) {
                    media = mediaValue
                }
            }
            
            switch fetchStatus {
                case let .Fetching(_, progress):
                    let adjustedProgress = max(progress, 0.027)
                    var wasCheck = false
                    if let statusNode = self.statusNode, case .check = statusNode.state {
                        wasCheck = true
                    }
                    if adjustedProgress.isEqual(to: 1.0), case .unconstrained = sizeCalculation, (message.flags.contains(.Unsent) || wasCheck) {
                        state = .check(messageTheme.mediaOverlayControlColors.foregroundColor)
                    } else {
                        state = .progress(color: messageTheme.mediaOverlayControlColors.foregroundColor, lineWidth: nil, value: CGFloat(adjustedProgress), cancelEnabled: true, animateRotation: true)
                    }
                                    
                    if let file = media as? TelegramMediaFile {
                        if file.isVideoSticker {
                            state = .none
                            badgeContent = nil
                        } else if wideLayout {
                            if let size = file.size, size > 0 && size != .max {
                                let sizeString = "\(dataSizeString(Int(Float(size) * progress), forceDecimal: true, formatting: formatting)) / \(dataSizeString(size, forceDecimal: true, formatting: formatting))"
                                if let duration = file.duration, !message.flags.contains(.Unsent) {
                                    let durationString = file.isAnimated ? gifTitle : stringForDuration(playerDuration > 0 ? playerDuration : Int32(duration), position: playerPosition)
                                    if isMediaStreamable(message: message, media: file) {
                                        badgeContent = .mediaDownload(backgroundColor: messageTheme.mediaDateAndStatusFillColor, foregroundColor: messageTheme.mediaDateAndStatusTextColor, duration: durationString, size: active ? sizeString : nil, muted: muted, active: active)
                                        mediaDownloadState = .fetching(progress: automaticPlayback ? nil : adjustedProgress)
                                        if self.playerStatus?.status == .playing {
                                            mediaDownloadState = nil
                                        }
                                        state = automaticPlayback ? .none : .play(messageTheme.mediaOverlayControlColors.foregroundColor)
                                    } else {
                                        if automaticPlayback {
                                            mediaDownloadState = .fetching(progress: adjustedProgress)
                                            badgeContent = .mediaDownload(backgroundColor: messageTheme.mediaDateAndStatusFillColor, foregroundColor: messageTheme.mediaDateAndStatusTextColor, duration: durationString, size: active ? sizeString : nil, muted: muted, active: active)
                                        } else {
                                            badgeContent = .mediaDownload(backgroundColor: messageTheme.mediaDateAndStatusFillColor, foregroundColor: messageTheme.mediaDateAndStatusTextColor, duration: sizeString, size: nil, muted: false, active: false)
                                        }
                                        state = automaticPlayback ? .none : state
                                    }
                                } else {
                                    badgeContent = .mediaDownload(backgroundColor: messageTheme.mediaDateAndStatusFillColor, foregroundColor: messageTheme.mediaDateAndStatusTextColor, duration: "\(dataSizeString(Int(Float(size) * progress), forceDecimal: true, formatting: formatting)) / \(dataSizeString(size, forceDecimal: true, formatting: formatting))", size: nil, muted: false, active: false)
                                }
                            } else if let _ = file.duration {
                                if file.isAnimated {
                                    badgeContent = .mediaDownload(backgroundColor: messageTheme.mediaDateAndStatusFillColor, foregroundColor: messageTheme.mediaDateAndStatusTextColor, duration: "\(gifTitle)", size: nil, muted: false, active: false)
                                } else {
                                    badgeContent = .mediaDownload(backgroundColor: messageTheme.mediaDateAndStatusFillColor, foregroundColor: messageTheme.mediaDateAndStatusTextColor, duration: strings.Conversation_Processing, size: nil, muted: false, active: false)
                                }
                            }
                            if file.isAnimated && isMediaStreamable(message: message, media: file) {
                                state = automaticPlayback ? .none : state
                            }
                        } else {
                            if isMediaStreamable(message: message, media: file), let fileSize = file.size, fileSize > 0 && fileSize != .max {
                                let sizeString = "\(dataSizeString(Int64(Float(fileSize) * progress), forceDecimal: true, formatting: formatting)) / \(dataSizeString(fileSize, forceDecimal: true, formatting: formatting))"
                                
                                if message.flags.contains(.Unsent), let duration = file.duration {
                                    let durationString = stringForDuration(playerDuration > 0 ? playerDuration : Int32(duration), position: playerPosition)
                                    badgeContent = .mediaDownload(backgroundColor: messageTheme.mediaDateAndStatusFillColor, foregroundColor: messageTheme.mediaDateAndStatusTextColor, duration: durationString, size: nil, muted: false, active: false)
                                }
                                else if automaticPlayback && !message.flags.contains(.Unsent), let duration = file.duration {
                                    let durationString = stringForDuration(playerDuration > 0 ? playerDuration : Int32(duration), position: playerPosition)
                                    badgeContent = .mediaDownload(backgroundColor: messageTheme.mediaDateAndStatusFillColor, foregroundColor: messageTheme.mediaDateAndStatusTextColor, duration: durationString, size: active ? sizeString : nil, muted: muted, active: active)
                                    
                                    mediaDownloadState = .fetching(progress: automaticPlayback ? nil : adjustedProgress)
                                    if self.playerStatus?.status == .playing {
                                        mediaDownloadState = nil
                                    }
                                } else {
                                    let progressString = String(format: "%d%%", Int(progress * 100.0))
                                    badgeContent = .text(inset: message.flags.contains(.Unsent) ? 0.0 : 12.0, backgroundColor: messageTheme.mediaDateAndStatusFillColor, foregroundColor: messageTheme.mediaDateAndStatusTextColor, text: NSAttributedString(string: progressString), iconName: nil)
                                    mediaDownloadState = automaticPlayback ? .none : .compactFetching(progress: 0.0)
                                }
                                
                                if !message.flags.contains(.Unsent) {
                                    state = automaticPlayback ? .none : .play(messageTheme.mediaOverlayControlColors.foregroundColor)
                                }
                            } else {
                                if let duration = file.duration, !file.isAnimated {
                                    let durationString = stringForDuration(playerDuration > 0 ? playerDuration : Int32(duration), position: playerPosition)
                                    
                                    if automaticPlayback, let fileSize = file.size, fileSize > 0 && fileSize != .max {
                                        let sizeString = "\(dataSizeString(Int64(Float(fileSize) * progress), forceDecimal: true, formatting: formatting)) / \(dataSizeString(fileSize, forceDecimal: true, formatting: formatting))"
                                        mediaDownloadState = .fetching(progress: progress)
                                        badgeContent = .mediaDownload(backgroundColor: messageTheme.mediaDateAndStatusFillColor, foregroundColor: messageTheme.mediaDateAndStatusTextColor, duration: durationString, size: active ? sizeString : nil, muted: muted, active: active)
                                    } else {
                                        badgeContent = .mediaDownload(backgroundColor: messageTheme.mediaDateAndStatusFillColor, foregroundColor: messageTheme.mediaDateAndStatusTextColor, duration: durationString, size: nil, muted: false, active: false)
                                    }
                                }
                                
                                state = automaticPlayback ? .none : state
                            }
                        }
                    } else if let webpage = webpage, let automaticDownload = self.automaticDownload, case .full = automaticDownload, case let .Loaded(content) = webpage.content, content.type != "telegram_background" {
                        state = .play(messageTheme.mediaOverlayControlColors.foregroundColor)
                    }
                case .Local:
                    state = .none
                    if isSecretMedia, let (maybeBeginTime, timeout) = secretBeginTimeAndTimeout, let beginTime = maybeBeginTime, Int32(timeout) != viewOnceTimeout {
                        state = .secretTimeout(color: messageTheme.mediaOverlayControlColors.foregroundColor, icon: .flame, beginTime: beginTime, timeout: timeout, sparks: true)
                    } else if isSecretMedia {
                        state = .staticTimeout
                    } else if let file = media as? TelegramMediaFile, !file.isVideoSticker {
                        let isInlinePlayableVideo = file.isVideo && !isSecretMedia && (self.automaticPlayback ?? false)
                        if (!isInlinePlayableVideo) && file.isVideo {
                            state = .play(messageTheme.mediaOverlayControlColors.foregroundColor)
                        } else {
                            state = .none
                        }
                    } else if let webpage = webpage, case let .Loaded(content) = webpage.content {
                        if content.embedUrl != nil {
                            state = .play(messageTheme.mediaOverlayControlColors.foregroundColor)
                        } else if let file = content.file, file.isVideo, !file.isAnimated {
                            state = .play(messageTheme.mediaOverlayControlColors.foregroundColor)
                        }
                    }
                    if let file = media as? TelegramMediaFile, let duration = file.duration, !file.isVideoSticker {
                        let durationString = file.isAnimated ? gifTitle : stringForDuration(playerDuration > 0 ? playerDuration : Int32(duration), position: playerPosition)
                        badgeContent = .mediaDownload(backgroundColor: messageTheme.mediaDateAndStatusFillColor, foregroundColor: messageTheme.mediaDateAndStatusTextColor, duration: durationString, size: nil, muted: muted, active: false)
                    }
                case .Remote, .Paused:
                    state = .download(messageTheme.mediaOverlayControlColors.foregroundColor)
                    if let file = media as? TelegramMediaFile, !file.isVideoSticker {
                        do {
                            let durationString = file.isAnimated ? gifTitle : stringForDuration(playerDuration > 0 ? playerDuration : (file.duration.flatMap { Int32(floor($0)) } ?? 0), position: playerPosition)
                            if wideLayout {
                                if isMediaStreamable(message: message, media: file), let fileSize = file.size, fileSize > 0 && fileSize != .max {
                                    state = automaticPlayback ? .none : .play(messageTheme.mediaOverlayControlColors.foregroundColor)
                                    badgeContent = .mediaDownload(backgroundColor: messageTheme.mediaDateAndStatusFillColor, foregroundColor: messageTheme.mediaDateAndStatusTextColor, duration: durationString, size: dataSizeString(fileSize, formatting: formatting), muted: muted, active: true)
                                    mediaDownloadState = .remote
                                } else {
                                    state = automaticPlayback ? .none : state
                                    badgeContent = .mediaDownload(backgroundColor: messageTheme.mediaDateAndStatusFillColor, foregroundColor: messageTheme.mediaDateAndStatusTextColor, duration: durationString, size: nil, muted: muted, active: false)
                                }
                            } else {
                                if isMediaStreamable(message: message, media: file) {
                                    state = automaticPlayback ? .none : .play(messageTheme.mediaOverlayControlColors.foregroundColor)
                                    badgeContent = .text(inset: 12.0, backgroundColor: messageTheme.mediaDateAndStatusFillColor, foregroundColor: messageTheme.mediaDateAndStatusTextColor, text: NSAttributedString(string: durationString), iconName: nil)
                                    mediaDownloadState = .compactRemote
                                } else {
                                    state = automaticPlayback ? .none : state
                                    badgeContent = .text(inset: 0.0, backgroundColor: messageTheme.mediaDateAndStatusFillColor, foregroundColor: messageTheme.mediaDateAndStatusTextColor, text: NSAttributedString(string: durationString), iconName: nil)
                                }
                            }
                        }
                    } else if let webpage = webpage, let automaticDownload = self.automaticDownload, case .full = automaticDownload, case let .Loaded(content) = webpage.content, content.type != "telegram_background" {
                        state = .play(messageTheme.mediaOverlayControlColors.foregroundColor)
                    }
            }
        }
        if isPreview, let file = media as? TelegramMediaFile {
            if let duration = file.duration, !file.isVideoSticker {
                let durationString = file.isAnimated ? gifTitle : stringForDuration(Int32(duration), position: nil)
                badgeContent = .mediaDownload(backgroundColor: messageTheme.mediaDateAndStatusFillColor, foregroundColor: messageTheme.mediaDateAndStatusTextColor, duration: durationString, size: nil, muted: false, active: false)
            }
            state = .play(messageTheme.mediaOverlayControlColors.foregroundColor)
        }
        
        if isSecretMedia {
            let remainingTime: Int32?
            if let (maybeBeginTime, timeout) = secretBeginTimeAndTimeout, Int32(timeout) != viewOnceTimeout {
                if let beginTime = maybeBeginTime {
                    let elapsedTime = CFAbsoluteTimeGetCurrent() + NSTimeIntervalSince1970 - beginTime
                    remainingTime = Int32(max(0.0, timeout - elapsedTime))
                } else {
                    remainingTime = Int32(timeout)
                }
            } else {
                if let attribute = message.autoclearAttribute {
                    remainingTime = attribute.timeout
                } else if let attribute = message.autoremoveAttribute {
                    remainingTime = attribute.timeout
                } else {
                    remainingTime = nil
                }
            }
                        
            if let remainingTime {
                if remainingTime == viewOnceTimeout {
                    badgeContent = .text(inset: 10.0, backgroundColor: messageTheme.mediaDateAndStatusFillColor, foregroundColor: messageTheme.mediaDateAndStatusTextColor, text: NSAttributedString(string: "1"), iconName: "Chat/Message/SecretMediaOnce")
                } else {
                    badgeContent = .text(inset: 10.0, backgroundColor: messageTheme.mediaDateAndStatusFillColor, foregroundColor: messageTheme.mediaDateAndStatusTextColor, text: NSAttributedString(string: strings.MessageTimer_ShortSeconds(Int32(remainingTime))), iconName: "Chat/Message/SecretMediaPlay")
                }
            }
        }
        
        if let statusNode = self.statusNode {
            var removeStatusNode = false
            if statusNode.state != .none && state == .none {
                self.statusNode = nil
                removeStatusNode = true
            }
            
            var animated = animated
            if case .download = statusNode.state, case .progress = state {
                animated = true
            } else if case .progress = statusNode.state, case .download = state {
                animated = true
            }
            
            if isPreview {
                if case .play = state {
                } else {
                    state = .none
                }
            }
            
            statusNode.transitionToState(state, animated: animated, completion: { [weak statusNode] in
                if removeStatusNode {
                    statusNode?.removeFromSupernode()
                }
            })
            statusNode.backgroundNodeColor = backgroundColor
        }
        if var badgeContent = badgeContent {
            if self.badgeNode == nil {
                let badgeNode = ChatMessageInteractiveMediaBadge()
                badgeNode.view.tag = 0xFACE
                if isPreview {
                    badgeNode.durationNode.displaysAsynchronously = false
                }
                
                var inset: CGFloat = 6.0
                if let corners = self.currentImageArguments?.corners, case .Tail = corners.bottomLeft {
                    inset = 10.0
                }
                
                badgeNode.frame = CGRect(origin: CGPoint(x: inset, y: 6.0), size: CGSize(width: radialStatusSize, height: radialStatusSize))
                badgeNode.pressed = { [weak self] in
                    guard let strongSelf = self, let fetchStatus = strongSelf.fetchStatus else {
                        return
                    }
                    switch fetchStatus {
                        case .Remote, .Fetching:
                            strongSelf.progressPressed(canActivate: false)
                        default:
                            break
                    }
                }
                self.badgeNode = badgeNode
                self.pinchContainerNode.contentNode.addSubnode(badgeNode)
                
                animated = false
            }
            if isPreview {
                mediaDownloadState = nil
                if case let .mediaDownload(backgroundColor, foregroundColor, duration, _ ,_ , _) = badgeContent {
                    badgeContent = .text(inset: 0.0, backgroundColor: backgroundColor, foregroundColor: foregroundColor, text: NSAttributedString(string: duration), iconName: nil)
                }
            }
            self.badgeNode?.update(theme: theme, content: badgeContent, mediaDownloadState: mediaDownloadState, animated: animated)
        } else if let badgeNode = self.badgeNode {
            self.badgeNode = nil
            badgeNode.removeFromSupernode()
        }
        
        var icon: ExtendedMediaOverlayNode.Icon?
        var displaySpoiler = false
        
        var extendedMedia: TelegramExtendedMedia?
        if let invoice, let selectedMedia = invoice.extendedMedia {
            extendedMedia = selectedMedia
        } else if let paidContent {
            let selectedMediaIndex = self.mediaIndex ?? 0
            if selectedMediaIndex < paidContent.extendedMedia.count {
                extendedMedia = paidContent.extendedMedia[selectedMediaIndex]
            }
        }
        
        if let extendedMedia, case .preview = extendedMedia {
            if let invoice, invoice.currency != "XTR" {
                icon = .lock
            }
            displaySpoiler = true
        } else if let _ = extendedMedia, isPreview {
            if let invoice, invoice.currency != "XTR" {
                icon = .lock
            }
            displaySpoiler = true
        } else if message.attributes.contains(where: { $0 is MediaSpoilerMessageAttribute }) {
            displaySpoiler = true
        } else if isSecretMedia {
            displaySpoiler = true
        } else if message.isSensitiveContent(platform: "ios") {
            if !self.showSensitiveContent {
                displaySpoiler = true
                icon = .eye
            }
        }
 
        
        if displaySpoiler, let context = self.context {
            let extendedMediaOverlayNode: ExtendedMediaOverlayNode
            if let current = self.extendedMediaOverlayNode {
                extendedMediaOverlayNode = current
            } else {
                let enableAnimations = context.sharedContext.energyUsageSettings.fullTranslucency && !isPreview
                extendedMediaOverlayNode = ExtendedMediaOverlayNode(context: context, hasImageOverlay: !isSecretMedia, icon: icon,  enableAnimations: enableAnimations)
                extendedMediaOverlayNode.tapped = { [weak self] in
                    guard let self else {
                        return
                    }
                    if message.isSensitiveContent(platform: "ios") {
                        self.activateAgeRestrictedMedia?()
                    } else {
                        self.internallyVisible = true
                        self.extendedMediaOverlayNode?.isRevealed = true
                        self.updateVisibility()
                    }
                }
                self.extendedMediaOverlayNode = extendedMediaOverlayNode
                self.pinchContainerNode.contentNode.insertSubnode(extendedMediaOverlayNode, aboveSubnode: self.imageNode)
            }
            extendedMediaOverlayNode.frame = self.imageNode.frame
            
            var tappable = false
            if !isSecretMedia {
                switch state {
                case .play, .pause, .download, .none:
                    tappable = true
                default:
                    break
                }
            }
            extendedMediaOverlayNode.isUserInteractionEnabled = tappable
            
            var viewText: String = ""
            if case .eye = icon {
                viewText = strings.Chat_SensitiveContent
                extendedMediaOverlayNode.dustNode.revealOnTap = false
            } else {
                outer: for attribute in message.attributes {
                    if let attribute = attribute as? ReplyMarkupMessageAttribute {
                        for row in attribute.rows {
                            for button in row.buttons {
                                if case .payment = button.action {
                                    viewText = button.title
                                    break outer
                                }
                            }
                        }
                        break
                    }
                }
                extendedMediaOverlayNode.dustNode.revealOnTap = true
            }
            extendedMediaOverlayNode.update(size: self.imageNode.frame.size, text: viewText, imageSignal: self.currentBlurredImageSignal, imageFrame: self.imageNode.view.convert(self.imageNode.bounds, to: extendedMediaOverlayNode.view), corners: self.currentImageArguments?.corners)
        } else if let extendedMediaOverlayNode = self.extendedMediaOverlayNode {
            self.extendedMediaOverlayNode = nil
            extendedMediaOverlayNode.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.3, removeOnCompletion: false, completion: { [weak extendedMediaOverlayNode] _ in
                extendedMediaOverlayNode?.removeFromSupernode()
            })
        }
             
        if isSecretMedia, secretBeginTimeAndTimeout?.0 != nil {
            if self.secretTimer == nil {
                self.secretTimer = SwiftSignalKit.Timer(timeout: 0.3, repeat: true, completion: { [weak self] in
                    self?.updateStatus(animated: false)
                }, queue: Queue.mainQueue())
                self.secretTimer?.start()
            }
        } else {
            if let secretTimer = self.secretTimer {
                self.secretTimer = nil
                secretTimer.invalidate()
            }
        }
    }
    
    public func reveal() {
        self.extendedMediaOverlayNode?.reveal(animated: true)
    }
    
    public static func asyncLayout(_ node: ChatMessageInteractiveMediaNode?) -> (_ context: AccountContext, _ presentationData: ChatPresentationData, _ dateTimeFormat: PresentationDateTimeFormat, _ message: Message, _ associatedData: ChatMessageItemAssociatedData, _ attributes: ChatMessageEntryAttributes, _ media: Media, _ mediaIndex: Int?, _ dateAndStatus: ChatMessageDateAndStatus?, _ automaticDownload: InteractiveMediaNodeAutodownloadMode, _ peerType: MediaAutoDownloadPeerType, _ peerId: EnginePeer.Id?, _ sizeCalculation: InteractiveMediaNodeSizeCalculation, _ layoutConstants: ChatMessageItemLayoutConstants, _ contentMode: InteractiveMediaNodeContentMode, _ presentationContext: ChatPresentationContext) -> (CGSize, CGFloat, (CGSize, Bool, Bool, ImageCorners) -> (CGFloat, (CGFloat) -> (CGSize, (ListViewItemUpdateAnimation, Bool) -> ChatMessageInteractiveMediaNode))) {
        let currentAsyncLayout = node?.asyncLayout()
        
        return { context, presentationData, dateTimeFormat, message, associatedData, attributes, media, mediaIndex, dateAndStatus, automaticDownload, peerType, peerId, sizeCalculation, layoutConstants, contentMode, presentationContext in
            var imageNode: ChatMessageInteractiveMediaNode
            var imageLayout: (_ context: AccountContext, _ presentationData: ChatPresentationData, _ dateTimeFormat: PresentationDateTimeFormat, _ message: Message, _ associatedData: ChatMessageItemAssociatedData, _ attributes: ChatMessageEntryAttributes, _ media: Media, _ mediaIndex: Int?, _ dateAndStatus: ChatMessageDateAndStatus?, _ automaticDownload: InteractiveMediaNodeAutodownloadMode, _ peerType: MediaAutoDownloadPeerType, _ peerId: EnginePeer.Id?, _ sizeCalculation: InteractiveMediaNodeSizeCalculation, _ layoutConstants: ChatMessageItemLayoutConstants, _ contentMode: InteractiveMediaNodeContentMode, _ presentationContext: ChatPresentationContext) -> (CGSize, CGFloat, (CGSize, Bool, Bool, ImageCorners) -> (CGFloat, (CGFloat) -> (CGSize, (ListViewItemUpdateAnimation, Bool) -> Void)))
            
            if let node = node, let currentAsyncLayout = currentAsyncLayout {
                imageNode = node
                imageLayout = currentAsyncLayout
            } else {
                imageNode = ChatMessageInteractiveMediaNode()
                imageLayout = imageNode.asyncLayout()
            }
            
            let (unboundSize, initialWidth, continueLayout) = imageLayout(context, presentationData, dateTimeFormat, message, associatedData, attributes, media, mediaIndex, dateAndStatus, automaticDownload, peerType, peerId, sizeCalculation, layoutConstants, contentMode, presentationContext)
            
            return (unboundSize, initialWidth, { constrainedSize, automaticPlayback, wideLayout, corners in
                let (finalWidth, finalLayout) = continueLayout(constrainedSize, automaticPlayback, wideLayout, corners)
                
                return (finalWidth, { boundingWidth in
                    let (finalSize, apply) = finalLayout(boundingWidth)
                    
                    return (finalSize, { transition, synchronousLoads in
                        apply(transition, synchronousLoads)
                        return imageNode
                    })
                })
            })
        }
    }
    
    public func setOverlayColor(_ color: UIColor?, animated: Bool) {
        self.imageNode.setOverlayColor(color, animated: animated)
    }
    
    public func isReadyForInteractivePreview() -> Bool {
        if let fetchStatus = self.fetchStatus, case .Local = fetchStatus {
            return true
        } else {
            return false
        }
    }
    
    public func updateIsHidden(_ isHidden: Bool) {
        if isHidden && !self.internallyVisible {
            self.internallyVisible = true
            self.updateVisibility()
            self.extendedMediaOverlayNode?.reveal()
        }
        
        if let badgeNode = self.badgeNode, badgeNode.isHidden != isHidden {
            if isHidden {
                badgeNode.isHidden = true
            } else {
                badgeNode.isHidden = false
                badgeNode.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.2)
            }
        }
    
        if let statusNode = self.statusNode, statusNode.isHidden != isHidden {
            if isHidden {
                statusNode.isHidden = true
            } else {
                statusNode.isHidden = false
                statusNode.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.2)
            }
        }
        if self.dateAndStatusNode.isHidden != isHidden {
            if isHidden {
                self.dateAndStatusNode.isHidden = true
            } else {
                self.dateAndStatusNode.isHidden = false
                self.dateAndStatusNode.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.2)
            }
        }
    }
    
    public func transitionNode(adjustRect: Bool) -> (ASDisplayNode, CGRect, () -> (UIView?, UIView?))? {
        var bounds: CGRect
        if let currentImageArguments = self.currentImageArguments {
            if adjustRect {
                bounds = currentImageArguments.drawingRect
            } else {
                bounds = currentImageArguments.imageRect
            }
        } else {
            bounds = self.bounds
        }
        return (adjustRect ? self.imageNode : self, bounds, { [weak self] in
            var badgeNodeHidden: Bool?
            if let badgeNode = self?.badgeNode {
                badgeNodeHidden = badgeNode.isHidden
                badgeNode.isHidden = true
            }
            var statusNodeHidden: Bool?
            if let statusNode = self?.statusNode {
                statusNodeHidden = statusNode.isHidden
                statusNode.isHidden = true
            }
            var dateAndStatusNodeHidden: Bool?
            if let dateAndStatusNode = self?.dateAndStatusNode {
                dateAndStatusNodeHidden = dateAndStatusNode.isHidden
                dateAndStatusNode.isHidden = true
            }
            
            let view: UIView?
            if let strongSelf = self, strongSelf.imageNode.captureProtected {
                let imageView = UIImageView()
                imageView.contentMode = .scaleToFill
                imageView.image = strongSelf.imageNode.image
                imageView.frame = strongSelf.imageNode.frame
                if imageView.layer.contents == nil {
                    imageView.layer.contents = imageView.image?.cgImage
                }
                strongSelf.imageNode.view.superview?.insertSubview(imageView, aboveSubview: strongSelf.imageNode.view)
                
                view = self?.view.snapshotContentTree(unhide: true)
                imageView.removeFromSuperview()
            } else {
                view = self?.view.snapshotContentTree(unhide: true)
            }
                        
            if let badgeNode = self?.badgeNode, let badgeNodeHidden = badgeNodeHidden {
                badgeNode.isHidden = badgeNodeHidden
            }
            if let statusNode = self?.statusNode, let statusNodeHidden = statusNodeHidden {
                statusNode.isHidden = statusNodeHidden
            }
            if let dateAndStatusNode = self?.dateAndStatusNode, let dateAndStatusNodeHidden = dateAndStatusNodeHidden {
                dateAndStatusNode.isHidden = dateAndStatusNodeHidden
            }
            return (view, nil)
        })
    }
    
    public func playMediaWithSound() -> (action: (Double?) -> Void, soundEnabled: Bool, isVideoMessage: Bool, isUnread: Bool, badgeNode: ASDisplayNode?)? {
        var isAnimated = false
        if let file = self.media as? TelegramMediaFile, file.isAnimated {
            isAnimated = true
        }

        var actionAtEnd: MediaPlayerPlayOnceWithSoundActionAtEnd = .loopDisablingSound
        if let message = self.message, message.id.peerId.namespace == Namespaces.Peer.CloudChannel {
            actionAtEnd = .loop
        } else {
            actionAtEnd = .repeatIfNeeded
        }
        
        if let videoNode = self.videoNode, let context = self.context, (self.automaticPlayback ?? false) && !isAnimated {
            return ({ timecode in
                if let timecode = timecode {
                    context.sharedContext.mediaManager.playlistControl(.playback(.pause), type: nil)
                    videoNode.playOnceWithSound(playAndRecord: false, seek: .timecode(timecode), actionAtEnd: actionAtEnd)
                } else {
                    let _ = (context.sharedContext.mediaManager.globalMediaPlayerState
                    |> take(1)
                    |> deliverOnMainQueue).startStandalone(next: { playlistStateAndType in
                        var canPlay = true
                        if let (_, state, _) = playlistStateAndType {
                            switch state {
                                case let .state(state):
                                    if case .playing = state.status.status {
                                        canPlay = false
                                    }
                                case .loading:
                                    break
                            }
                        }
                        if canPlay {
                            videoNode.playOnceWithSound(playAndRecord: false, seek: .none, actionAtEnd: actionAtEnd)
                        }
                    })
                }
            }, (self.playerStatus?.soundEnabled ?? false), false, false, self.badgeNode)
        } else {
            return nil
        }
    }
    
    public func ignoreTapActionAtPoint(_ point: CGPoint) -> Bool {
        if let extendedMediaOverlayNode = self.extendedMediaOverlayNode {
            let convertedPoint = self.view.convert(point, to: extendedMediaOverlayNode.view)
            if extendedMediaOverlayNode.buttonNode.frame.contains(convertedPoint) {
                return true
            }
        }
        return false
    }
}
