import Foundation
import UIKit
import Display
import AsyncDisplayKit
import SwiftSignalKit

private final class NullActionClass: NSObject, CAAction {
    @objc func run(forKey event: String, object anObject: Any, arguments dict: [AnyHashable : Any]?) {
    }
}

private let nullAction = NullActionClass()

public protocol SparseItemGridLayer: CALayer {
    func update(size: CGSize)
    func needsShimmer() -> Bool
}

public protocol SparseItemGridView: UIView {
    func update(size: CGSize)
    func needsShimmer() -> Bool
}

public protocol SparseItemGridDisplayItem: AnyObject {
    var layer: SparseItemGridLayer? { get }
    var view: SparseItemGridView? { get }
}

public protocol SparseItemGridBinding: AnyObject {
    func createLayer() -> SparseItemGridLayer?
    func createView() -> SparseItemGridView?
    func bindLayers(items: [SparseItemGrid.Item], layers: [SparseItemGridDisplayItem])
    func unbindLayer(layer: SparseItemGridLayer)
    func scrollerTextForTag(tag: Int32) -> String?
    func loadHole(anchor: SparseItemGrid.HoleAnchor, at location: SparseItemGrid.HoleLocation) -> Signal<Never, NoError>
    func onTap(item: SparseItemGrid.Item)
    func onTagTap()
    func didScroll()
    func coveringInsetOffsetUpdated(transition: ContainedViewLayoutTransition)
    func onBeginFastScrolling()
    func getShimmerColors() -> SparseItemGrid.ShimmerColors
}

private func binarySearch(_ inputArr: [SparseItemGrid.Item], searchItem: Int) -> (index: Int?, lowerBound: Int?, upperBound: Int?) {
    var lowerIndex = 0
    var upperIndex = inputArr.count - 1

    if lowerIndex > upperIndex {
        return (nil, nil, nil)
    }

    while true {
        let currentIndex = (lowerIndex + upperIndex) / 2
        let value = inputArr[currentIndex].index

        if value == searchItem {
            return (currentIndex, nil, nil)
        } else if lowerIndex > upperIndex {
            return (nil, upperIndex >= 0 ? upperIndex : nil, lowerIndex < inputArr.count ? lowerIndex : nil)
        } else {
            if (value > searchItem) {
                upperIndex = currentIndex - 1
            } else {
                lowerIndex = currentIndex + 1
            }
        }
    }
}

private func binarySearch(_ inputArr: [SparseItemGrid.HoleAnchor], searchItem: Int) -> (index: Int?, lowerBound: Int?, upperBound: Int?) {
    var lowerIndex = 0
    var upperIndex = inputArr.count - 1

    if lowerIndex > upperIndex {
        return (nil, nil, nil)
    }

    while true {
        let currentIndex = (lowerIndex + upperIndex) / 2
        let value = inputArr[currentIndex].index

        if value == searchItem {
            return (currentIndex, nil, nil)
        } else if lowerIndex > upperIndex {
            return (nil, upperIndex >= 0 ? upperIndex : nil, lowerIndex < inputArr.count ? lowerIndex : nil)
        } else {
            if (value > searchItem) {
                upperIndex = currentIndex - 1
            } else {
                lowerIndex = currentIndex + 1
            }
        }
    }
}

private final class Shimmer {
    private var image: UIImage?
    private var colors: SparseItemGrid.ShimmerColors = SparseItemGrid.ShimmerColors(background: 0, foreground: 0)

    func update(colors: SparseItemGrid.ShimmerColors, layer: CALayer, containerSize: CGSize, frame: CGRect) {
        if self.colors != colors {
            self.colors = colors

            self.image = generateImage(CGSize(width: 1.0, height: 320.0), opaque: false, scale: 1.0, rotatedContext: { size, context in
                context.clear(CGRect(origin: CGPoint(), size: size))
                context.setFillColor(UIColor(rgb: colors.background).cgColor)
                context.fill(CGRect(origin: CGPoint(), size: size))

                context.clip(to: CGRect(origin: CGPoint(), size: size))

                let transparentColor = UIColor(argb: colors.foreground).withAlphaComponent(0.0).cgColor
                let peakColor = UIColor(argb: colors.foreground).cgColor

                var locations: [CGFloat] = [0.0, 0.5, 1.0]
                let colors: [CGColor] = [transparentColor, peakColor, transparentColor]

                let colorSpace = CGColorSpaceCreateDeviceRGB()
                let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: &locations)!

                context.drawLinearGradient(gradient, start: CGPoint(x: 0.0, y: 0.0), end: CGPoint(x: 0.0, y: size.height), options: CGGradientDrawingOptions())
            })
        }

        if let image = self.image {
            layer.contents = image.cgImage

            let shiftedContentsRect = CGRect(origin: CGPoint(x: frame.minX / containerSize.width, y: frame.minY / containerSize.height), size: CGSize(width: frame.width / containerSize.width, height: frame.height / containerSize.height))
            let _ = shiftedContentsRect
            layer.contentsRect = shiftedContentsRect

            if layer.animation(forKey: "shimmer") == nil {
                let animation = CABasicAnimation(keyPath: "contentsRect.origin.y")
                animation.fromValue = 1.0 as NSNumber
                animation.toValue = -1.0 as NSNumber
                animation.isAdditive = true
                animation.repeatCount = .infinity
                animation.duration = 0.8
                animation.beginTime = 1.0
                layer.add(animation, forKey: "shimmer")
            }
        }
    }

    final class Layer: CALayer {
        override func action(forKey event: String) -> CAAction? {
            return nullAction
        }
    }
}

public final class SparseItemGrid: ASDisplayNode {
    public struct ShimmerColors: Equatable {
        public var background: UInt32
        public var foreground: UInt32

        public init(background: UInt32, foreground: UInt32) {
            self.background = background
            self.foreground = foreground
        }
    }

    open class Item {
        open var id: AnyHashable {
            preconditionFailure()
        }

        open var index: Int {
            preconditionFailure()
        }

        open var tag: Int32 {
            preconditionFailure()
        }

        public init() {
        }
    }

    public enum HoleLocation {
        case around
        case toLower
        case toUpper
    }

    open class HoleAnchor {
        open var id: AnyHashable {
            preconditionFailure()
        }

        open var index: Int {
            preconditionFailure()
        }

        open var tag: Int32 {
            preconditionFailure()
        }

        public init() {
        }
    }

    public final class Items {
        public let items: [Item]
        public let holeAnchors: [HoleAnchor]
        public let count: Int
        public let itemBinding: SparseItemGridBinding

        public init(items: [Item], holeAnchors: [HoleAnchor], count: Int, itemBinding: SparseItemGridBinding) {
            self.items = items
            self.holeAnchors = holeAnchors
            self.count = count
            self.itemBinding = itemBinding
        }

        func item(at index: Int) -> Item? {
            if let itemIndex = binarySearch(self.items, searchItem: index).index {
                return self.items[itemIndex]
            }
            return nil
        }

        func itemOrLower(at index: Int) -> Item? {
            let searchResult = binarySearch(self.items, searchItem: index)
            if let itemIndex = searchResult.index {
                return self.items[itemIndex]
            } else if let lowerBound = searchResult.lowerBound {
                return self.items[lowerBound]
            } else {
                return nil
            }
        }

        func tag(atIndexOrLower index: Int) -> Int32? {
            var item: Item?
            let itemsResult = binarySearch(self.items, searchItem: index)
            if let itemIndex = itemsResult.index {
                item = self.items[itemIndex]
            } else if let lowerBound = itemsResult.lowerBound {
                item = self.items[lowerBound]
            }

            var holeAnchor: HoleAnchor?
            let holeResult = binarySearch(self.holeAnchors, searchItem: index)
            if let itemIndex = holeResult.index {
                holeAnchor = self.holeAnchors[itemIndex]
            } else if let lowerBound = holeResult.lowerBound {
                holeAnchor = self.holeAnchors[lowerBound]
            }

            if let item = item, let holeAnchor = holeAnchor {
                if abs(index - item.index) < abs(index - holeAnchor.index) {
                    return item.tag
                } else {
                    return holeAnchor.tag
                }
            } else if let item = item {
                return item.tag
            } else if let holeAnchor = holeAnchor {
                return holeAnchor.tag
            } else {
                return nil
            }
        }

        func closestItem(at index: Int) -> Item? {
            let searchResult = binarySearch(self.items, searchItem: index)
            if let itemIndex = searchResult.index {
                return self.items[itemIndex]
            } else if let lowerBound = searchResult.lowerBound, let upperBound = searchResult.upperBound {
                let lowerBoundIndex = self.items[lowerBound].index
                let upperBoundIndex = self.items[upperBound].index
                if abs(index - lowerBoundIndex) < abs(index - upperBoundIndex) {
                    return self.items[lowerBound]
                } else {
                    return self.items[upperBound]
                }
            } else if let lowerBound = searchResult.lowerBound {
                return self.items[lowerBound]
            } else if let upperBound = searchResult.upperBound {
                return self.items[upperBound]
            } else {
                return nil
            }
        }

        func closestHole(to index: Int) -> HoleAnchor? {
            let searchResult = binarySearch(self.holeAnchors, searchItem: index)
            if let itemIndex = searchResult.index {
                return self.holeAnchors[itemIndex]
            } else if let lowerBound = searchResult.lowerBound, let upperBound = searchResult.upperBound {
                let lowerBoundIndex = self.holeAnchors[lowerBound].index
                let upperBoundIndex = self.holeAnchors[upperBound].index
                if abs(index - lowerBoundIndex) < abs(index - upperBoundIndex) {
                    return self.holeAnchors[lowerBound]
                } else {
                    return self.holeAnchors[upperBound]
                }
            } else if let lowerBound = searchResult.lowerBound {
                return self.holeAnchors[lowerBound]
            } else if let upperBound = searchResult.upperBound {
                return self.holeAnchors[upperBound]
            } else {
                return nil
            }
        }
    }

    public struct ZoomLevel: Equatable, Comparable {
        public var rawValue: Int

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        public static func <(lhs: ZoomLevel, rhs: ZoomLevel) -> Bool {
            return lhs.rawValue < rhs.rawValue
        }
    }

    private final class Viewport: ASDisplayNode, UIScrollViewDelegate {
        final class VisibleItem: SparseItemGridDisplayItem {
            let layer: SparseItemGridLayer?
            let view: SparseItemGridView?

            init(layer: SparseItemGridLayer?, view: SparseItemGridView?) {
                self.layer = layer
                self.view = view
            }

            var displayLayer: CALayer {
                if let layer = self.layer {
                    return layer
                } else if let view = self.view {
                    return view.layer
                } else {
                    preconditionFailure()
                }
            }

            var frame: CGRect {
                get {
                    return self.displayLayer.frame
                } set(value) {
                    if let layer = self.layer {
                        layer.frame = value
                    } else if let view = self.view {
                        view.frame = value
                    } else {
                        preconditionFailure()
                    }
                }
            }

            var needsShimmer: Bool {
                if let layer = self.layer {
                    return layer.needsShimmer()
                } else if let view = self.view {
                    return view.needsShimmer()
                } else {
                    preconditionFailure()
                }
            }
        }

        final class Layout {
            let containerLayout: ContainerLayout
            let itemSize: CGSize
            let itemSpacing: CGFloat
            let lastItemSize: CGFloat
            let itemsPerRow: Int

            init(containerLayout: ContainerLayout, zoomLevel: ZoomLevel) {
                self.containerLayout = containerLayout
                if let fixedItemHeight = containerLayout.fixedItemHeight {
                    self.itemsPerRow = 1
                    self.itemSize = CGSize(width: containerLayout.size.width, height: fixedItemHeight)
                    self.lastItemSize = containerLayout.size.width
                    self.itemSpacing = 0.0
                } else {
                    self.itemSpacing = 1.0

                    let width = containerLayout.size.width
                    let baseItemWidth = floor(min(150.0, width / 3.0))
                    let unclippedItemWidth = (CGFloat(zoomLevel.rawValue) / 100.0) * baseItemWidth
                    let itemsPerRow = floor(width / unclippedItemWidth)
                    self.itemsPerRow = Int(itemsPerRow)
                    let itemSize = floorToScreenPixels((width - (self.itemSpacing * CGFloat(self.itemsPerRow - 1))) / itemsPerRow)
                    self.itemSize = CGSize(width: itemSize, height: itemSize)

                    self.lastItemSize = width - (self.itemSize.width + self.itemSpacing) * CGFloat(self.itemsPerRow - 1)
                }
            }

            func frame(at index: Int) -> CGRect {
                let row = index / self.itemsPerRow
                let column = index % self.itemsPerRow

                return CGRect(origin: CGPoint(x: CGFloat(column) * (self.itemSize.width + self.itemSpacing), y: self.containerLayout.insets.top + CGFloat(row) * (self.itemSize.height + self.itemSpacing)), size: CGSize(width: column == (self.itemsPerRow - 1) ? self.lastItemSize : itemSize.width, height: itemSize.height))
            }

            func contentHeight(count: Int) -> CGFloat {
                return self.frame(at: count - 1).maxY
            }

            func visibleItemRange(for rect: CGRect, count: Int) -> (minIndex: Int, maxIndex: Int) {
                let offsetRect = rect.offsetBy(dx: 0.0, dy: -self.containerLayout.insets.top)
                var minVisibleRow = Int(floor((offsetRect.minY - self.itemSpacing) / (self.itemSize.height + self.itemSpacing)))
                minVisibleRow = max(0, minVisibleRow)
                let maxVisibleRow = Int(ceil((offsetRect.maxY - self.itemSpacing) / (self.itemSize.height + itemSpacing)))

                let minVisibleIndex = minVisibleRow * self.itemsPerRow
                let maxVisibleIndex = min(count - 1, (maxVisibleRow + 1) * self.itemsPerRow - 1)

                return (minVisibleIndex, maxVisibleIndex)
            }
        }

        let zoomLevel: ZoomLevel

        private let scrollView: UIScrollView
        private let shimmer: Shimmer

        var layout: Layout?
        var items: Items?
        var visibleItems: [AnyHashable: VisibleItem] = [:]
        var visiblePlaceholders: [Shimmer.Layer] = []

        private var scrollingArea: SparseItemGridScrollingArea?
        private var currentScrollingTag: Int32?
        private let maybeLoadHoleAnchor: (HoleAnchor, HoleLocation) -> Void

        private var ignoreScrolling: Bool = false
        private var isFastScrolling: Bool = false

        private var previousScrollOffset: CGFloat = 0.0
        var coveringInsetOffset: CGFloat = 0.0

        init(zoomLevel: ZoomLevel, maybeLoadHoleAnchor: @escaping (HoleAnchor, HoleLocation) -> Void) {
            self.zoomLevel = zoomLevel
            self.maybeLoadHoleAnchor = maybeLoadHoleAnchor

            self.scrollView = UIScrollView()
            if #available(iOSApplicationExtension 11.0, iOS 11.0, *) {
                self.scrollView.contentInsetAdjustmentBehavior = .never
            }
            self.scrollView.scrollsToTop = false
            self.scrollView.showsVerticalScrollIndicator = false
            self.scrollView.showsHorizontalScrollIndicator = false
            self.scrollView.delaysContentTouches = false
            self.scrollView.clipsToBounds = false

            self.shimmer = Shimmer()

            super.init()

            self.anchorPoint = CGPoint()

            self.scrollView.delegate = self
            self.view.addSubview(self.scrollView)
        }

        func update(containerLayout: ContainerLayout, items: Items, restoreScrollPosition: (y: CGFloat, index: Int)?) {
            if self.layout?.containerLayout != containerLayout || self.items !== items {
                self.layout = Layout(containerLayout: containerLayout, zoomLevel: self.zoomLevel)
                self.items = items

                self.updateVisibleItems(resetScrolling: true, restoreScrollPosition: restoreScrollPosition)
            }
        }

        @objc func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
            self.items?.itemBinding.didScroll()
        }

        @objc func scrollViewDidScroll(_ scrollView: UIScrollView) {
            if !self.ignoreScrolling {
                self.updateVisibleItems(resetScrolling: false, restoreScrollPosition: nil)

                if let layout = self.layout, let items = self.items {
                    let offset = scrollView.contentOffset.y
                    let delta = offset - self.previousScrollOffset
                    self.previousScrollOffset = offset

                    if self.isFastScrolling {
                        if offset <= layout.containerLayout.insets.top {
                            var coveringInsetOffset = self.coveringInsetOffset + delta
                            if coveringInsetOffset < 0.0 {
                                coveringInsetOffset = 0.0
                            }
                            if coveringInsetOffset > layout.containerLayout.insets.top {
                                coveringInsetOffset = layout.containerLayout.insets.top
                            }
                            if offset <= 0.0 {
                                coveringInsetOffset = 0.0
                            }
                            if coveringInsetOffset < self.coveringInsetOffset {
                                self.coveringInsetOffset = coveringInsetOffset
                                items.itemBinding.coveringInsetOffsetUpdated(transition: .immediate)
                            }
                        }
                    } else {
                        var coveringInsetOffset = self.coveringInsetOffset + delta
                        if coveringInsetOffset < 0.0 {
                            coveringInsetOffset = 0.0
                        }
                        if coveringInsetOffset > layout.containerLayout.insets.top {
                            coveringInsetOffset = layout.containerLayout.insets.top
                        }
                        if offset <= 0.0 {
                            coveringInsetOffset = 0.0
                        }
                        if coveringInsetOffset != self.coveringInsetOffset {
                            self.coveringInsetOffset = coveringInsetOffset
                            items.itemBinding.coveringInsetOffsetUpdated(transition: .immediate)
                        }
                    }
                }
            }
        }

        @objc func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
            if !self.ignoreScrolling {
                self.snapCoveringInsetOffset()
            }
        }

        @objc func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
            if !self.ignoreScrolling {
                if !decelerate {
                    self.snapCoveringInsetOffset()
                }
            }
        }

        @objc func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
            if !self.ignoreScrolling {
                self.snapCoveringInsetOffset()
            }
        }

        private func snapCoveringInsetOffset() {
            if let layout = self.layout, let items = self.items {
                let offset = self.scrollView.contentOffset.y
                if offset < layout.containerLayout.insets.top {
                    if offset <= layout.containerLayout.insets.top / 2.0 {
                        self.scrollView.setContentOffset(CGPoint(), animated: true)
                    } else {
                        self.scrollView.setContentOffset(CGPoint(x: 0.0, y: layout.containerLayout.insets.top), animated: true)
                    }
                } else {
                    var coveringInsetOffset = self.coveringInsetOffset
                    if coveringInsetOffset > layout.containerLayout.insets.top / 2.0 {
                        coveringInsetOffset = layout.containerLayout.insets.top
                    } else {
                        coveringInsetOffset = 0.0
                    }
                    if offset <= 0.0 {
                        coveringInsetOffset = 0.0
                    }

                    if coveringInsetOffset != self.coveringInsetOffset {
                        self.coveringInsetOffset = coveringInsetOffset
                        items.itemBinding.coveringInsetOffsetUpdated(transition: .animated(duration: 0.2, curve: .easeInOut))
                    }
                }
            }
        }

        func item(at point: CGPoint) -> Item? {
            guard let items = self.items, !items.items.isEmpty else {
                return nil
            }

            let localPoint = self.scrollView.convert(point, from: self.view)

            for (id, visibleItem) in self.visibleItems {
                if visibleItem.frame.contains(localPoint) {
                    for item in items.items {
                        if item.id == id {
                            return item
                        }
                    }
                    return nil
                }
            }

            return nil
        }

        func anchorItem(at point: CGPoint) -> Item? {
            guard let items = self.items, !items.items.isEmpty else {
                return nil
            }

            let localPoint = self.scrollView.convert(point, from: self.view)

            var closestItem: (CGFloat, AnyHashable)?
            for (id, visibleItem) in self.visibleItems {
                let itemCenter = visibleItem.frame.center
                let distanceX = itemCenter.x - localPoint.x
                let distanceY = itemCenter.y - localPoint.y
                let distance2 = distanceX * distanceX + distanceY * distanceY

                if let (currentDistance2, _) = closestItem {
                    if distance2 < currentDistance2 {
                        closestItem = (distance2, id)
                    }
                } else {
                    closestItem = (distance2, id)
                }
            }

            if let (_, id) = closestItem {
                for item in items.items {
                    if item.id == id {
                        return item
                    }
                }
                return nil
            } else {
                return nil
            }
        }

        func frameForItem(at index: Int) -> CGRect? {
            guard let layout = self.layout else {
                return nil
            }
            return self.scrollView.convert(layout.frame(at: index), to: self.view)
        }

        func frameForItem(layer: SparseItemGridLayer) -> CGRect {
            return self.scrollView.convert(layer.frame, to: self.view)
        }

        func scrollToItem(at index: Int) {
            guard let layout = self.layout, let _ = self.items else {
                return
            }
            if layout.containerLayout.lockScrollingAtTop {
                return
            }
            let itemFrame = layout.frame(at: index)
            var contentOffset = itemFrame.minY
            if contentOffset > self.scrollView.contentSize.height - self.scrollView.bounds.height {
                contentOffset = self.scrollView.contentSize.height - self.scrollView.bounds.height
            }
            if contentOffset < 0.0 {
                contentOffset = 0.0
            }
            self.scrollView.setContentOffset(CGPoint(x: 0.0, y: contentOffset), animated: false)
        }

        func scrollToTop() -> Bool {
            if self.scrollView.contentOffset.y > 0.0 {
                self.scrollView.setContentOffset(CGPoint(), animated: true)
                return true
            } else {
                return false
            }
        }

        private func updateVisibleItems(resetScrolling: Bool, restoreScrollPosition: (y: CGFloat, index: Int)?) {
            guard let layout = self.layout, let items = self.items else {
                return
            }

            let contentHeight = layout.contentHeight(count: items.count)
            let shimmerColors = items.itemBinding.getShimmerColors()

            if resetScrolling {
                if !self.scrollView.bounds.isEmpty {
                    //get anchor item id
                }

                self.ignoreScrolling = true
                self.scrollView.frame = CGRect(origin: CGPoint(), size: layout.containerLayout.size)
                self.scrollView.contentSize = CGSize(width: layout.containerLayout.size.width, height: contentHeight + layout.containerLayout.insets.bottom)
                self.ignoreScrolling = false
            }

            if layout.containerLayout.lockScrollingAtTop {
                self.scrollView.isScrollEnabled = false

                self.ignoreScrolling = true
                self.scrollView.setContentOffset(CGPoint(x: 0.0, y: 0.0), animated: false)
                self.ignoreScrolling = false
            } else {
                self.scrollView.isScrollEnabled = true
                if let (y, index) = restoreScrollPosition {
                    let itemFrame = layout.frame(at: index)
                    var contentOffset = itemFrame.minY - y
                    if contentOffset > self.scrollView.contentSize.height - self.scrollView.bounds.height {
                        contentOffset = self.scrollView.contentSize.height - self.scrollView.bounds.height
                    }
                    if contentOffset < 0.0 {
                        contentOffset = 0.0
                    }

                    self.ignoreScrolling = true
                    self.scrollView.setContentOffset(CGPoint(x: 0.0, y: contentOffset), animated: false)
                    self.ignoreScrolling = false
                }
            }

            let visibleBounds = self.scrollView.bounds

            var validIds = Set<AnyHashable>()
            var usedPlaceholderCount = 0
            if !items.items.isEmpty {
                var bindItems: [Item] = []
                var bindLayers: [SparseItemGridDisplayItem] = []
                var updateLayers: [SparseItemGridDisplayItem] = []

                let visibleRange = layout.visibleItemRange(for: visibleBounds, count: items.count)
                for index in visibleRange.minIndex ... visibleRange.maxIndex {
                    if let item = items.item(at: index) {
                        let itemLayer: VisibleItem
                        if let current = self.visibleItems[item.id] {
                            itemLayer = current
                            updateLayers.append(itemLayer)
                        } else {
                            itemLayer = VisibleItem(layer: items.itemBinding.createLayer(), view: items.itemBinding.createView())
                            self.visibleItems[item.id] = itemLayer

                            bindItems.append(item)
                            bindLayers.append(itemLayer)

                            if let layer = itemLayer.layer {
                                self.scrollView.layer.addSublayer(layer)
                            } else if let view = itemLayer.view {
                                self.scrollView.addSubview(view)
                            }
                        }

                        validIds.insert(item.id)

                        itemLayer.frame = layout.frame(at: index)
                    } else if layout.containerLayout.fixedItemHeight == nil {
                        let placeholderLayer: Shimmer.Layer
                        if self.visiblePlaceholders.count > usedPlaceholderCount {
                            placeholderLayer = self.visiblePlaceholders[usedPlaceholderCount]
                        } else {
                            placeholderLayer = Shimmer.Layer()
                            self.scrollView.layer.addSublayer(placeholderLayer)
                            self.visiblePlaceholders.append(placeholderLayer)
                        }
                        let itemFrame = layout.frame(at: index)
                        placeholderLayer.frame = itemFrame
                        self.shimmer.update(colors: shimmerColors, layer: placeholderLayer, containerSize: layout.containerLayout.size, frame: itemFrame.offsetBy(dx: 0.0, dy: -visibleBounds.minY))
                        usedPlaceholderCount += 1
                    }
                }

                if !bindItems.isEmpty {
                    items.itemBinding.bindLayers(items: bindItems, layers: bindLayers)
                }

                for item in updateLayers {
                    let item = item as! VisibleItem
                    if let layer = item.layer {
                        layer.update(size: layer.frame.size)
                    } else if let view = item.view {
                        view.update(size: layer.frame.size)
                    }

                    if item.needsShimmer {
                        let itemFrame = layer.frame
                        self.shimmer.update(colors: shimmerColors, layer: item.displayLayer, containerSize: layout.containerLayout.size, frame: itemFrame.offsetBy(dx: 0.0, dy: -visibleBounds.minY))
                    }
                }
            }

            var removeIds: [AnyHashable] = []
            for (id, _) in self.visibleItems {
                if !validIds.contains(id) {
                    removeIds.append(id)
                }
            }
            for id in removeIds {
                if let item = self.visibleItems.removeValue(forKey: id) {
                    if let layer = item.layer {
                        items.itemBinding.unbindLayer(layer: layer)
                        layer.removeFromSuperlayer()
                    } else if let view = item.view {
                        view.removeFromSuperview()
                    }
                }
            }

            if self.visiblePlaceholders.count > usedPlaceholderCount {
                for i in usedPlaceholderCount ..< self.visiblePlaceholders.count {
                    self.visiblePlaceholders[i].removeFromSuperlayer()
                }
                self.visiblePlaceholders.removeSubrange(usedPlaceholderCount...)
            }

            self.updateScrollingArea()
            self.updateHoleToLoad()
        }

        func updateHoleToLoad() {
            guard let layout = self.layout, let items = self.items else {
                return
            }

            if !items.items.isEmpty {
                let visibleBounds = self.scrollView.bounds
                let visibleRange = layout.visibleItemRange(for: visibleBounds, count: items.count)
                for index in visibleRange.minIndex ... visibleRange.maxIndex {
                    if items.item(at: index) == nil {
                        if let holeAnchor = items.closestHole(to: index) {
                            let location: HoleLocation
                            if index < holeAnchor.index {
                                location = .toLower
                            } else {
                                location = .toUpper
                            }
                            self.maybeLoadHoleAnchor(holeAnchor, location)
                        }
                        break
                    }
                }
            }
        }

        func setScrollingArea(scrollingArea: SparseItemGridScrollingArea?) {
            if self.scrollingArea === scrollingArea {
                return
            }
            self.scrollingArea = scrollingArea

            if let scrollingArea = self.scrollingArea {
                scrollingArea.beginScrolling = { [weak self] in
                    guard let strongSelf = self else {
                        return nil
                    }
                    strongSelf.items?.itemBinding.onBeginFastScrolling()
                    return strongSelf.scrollView
                }
                scrollingArea.setContentOffset = { [weak self] offset in
                    guard let strongSelf = self else {
                        return
                    }
                    strongSelf.isFastScrolling = true
                    strongSelf.scrollView.setContentOffset(offset, animated: false)
                    strongSelf.isFastScrolling = false
                }
                self.updateScrollingArea()
            }
        }

        private func updateScrollingArea() {
            guard let layout = self.layout, let items = self.items, !items.items.isEmpty else {
                return
            }

            let contentHeight = layout.contentHeight(count: items.count)

            var tag: Int32?
            let visibleBounds = self.scrollView.bounds
            let visibleRange = layout.visibleItemRange(for: visibleBounds, count: items.count)
            for index in visibleRange.minIndex ... visibleRange.maxIndex {
                if let tagValue = items.tag(atIndexOrLower: index) {
                    tag = tagValue
                    break
                }
            }

            if let scrollingArea = self.scrollingArea {
                let dateString = tag.flatMap { items.itemBinding.scrollerTextForTag(tag: $0) }
                if self.currentScrollingTag != tag {
                    self.currentScrollingTag = tag
                    if scrollingArea.isDragging {
                        scrollingArea.feedbackTap()
                    }
                }
                scrollingArea.update(
                    containerSize: layout.containerLayout.size,
                    containerInsets: layout.containerLayout.insets,
                    contentHeight: contentHeight,
                    contentOffset: self.scrollView.bounds.minY,
                    isScrolling: self.scrollView.isDragging || self.scrollView.isDecelerating,
                    dateString: dateString ?? "",
                    transition: .immediate
                )
            }
        }
    }

    private final class ViewportTransition: ASDisplayNode {
        struct InteractiveState {
            var initialScale: CGFloat
            var targetScale: CGFloat
        }

        let interactiveState: InteractiveState?
        let layout: ContainerLayout
        let anchorItemIndex: Int
        let fromViewport: Viewport
        let toViewport: Viewport

        var currentProgress: CGFloat = 0.0

        init(interactiveState: InteractiveState?, layout: ContainerLayout, anchorItemIndex: Int, from fromViewport: Viewport, to toViewport: Viewport) {
            self.interactiveState = interactiveState
            self.layout = layout
            self.anchorItemIndex = anchorItemIndex
            self.fromViewport = fromViewport
            self.toViewport = toViewport

            super.init()

            self.addSubnode(fromViewport)
            self.addSubnode(toViewport)
        }

        func update(progress: CGFloat, transition: ContainedViewLayoutTransition, completion: @escaping () -> Void) {
            guard var fromAnchorFrame = self.fromViewport.frameForItem(at: self.anchorItemIndex) else {
                return
            }
            guard var toAnchorFrame = self.toViewport.frameForItem(at: self.anchorItemIndex) else {
                return
            }

            let previousProgress = self.currentProgress
            self.currentProgress = progress

            if let fromItem = self.fromViewport.anchorItem(at: fromAnchorFrame.center), let fromFrame = self.fromViewport.frameForItem(at: fromItem.index) {
                fromAnchorFrame.origin.x = fromFrame.midX
                fromAnchorFrame.size.width = 0.0
            }

            if let toItem = self.toViewport.anchorItem(at: fromAnchorFrame.center), let toFrame = self.toViewport.frameForItem(at: toItem.index) {
                toAnchorFrame.origin.x = toFrame.midX
                toAnchorFrame.size.width = 0.0
            }

            let fromAnchorPoint = CGPoint(x: fromAnchorFrame.midX, y: fromAnchorFrame.midY)
            let toAnchorPoint = CGPoint(x: toAnchorFrame.midX, y: toAnchorFrame.midY)

            let initialFromViewportScale: CGFloat = 1.0
            let targetFromViewportScale: CGFloat = toAnchorFrame.height / fromAnchorFrame.height

            let initialToViewportScale: CGFloat = fromAnchorFrame.height / toAnchorFrame.height
            let targetToViewportScale: CGFloat = 1.0

            let fromScale = initialFromViewportScale * (1.0 - progress) + targetFromViewportScale * progress
            let toScale = initialToViewportScale * (1.0 - progress) + targetToViewportScale * progress

            let fromDeltaOffset = CGPoint(x: toAnchorPoint.x - fromAnchorPoint.x, y: toAnchorPoint.y - fromAnchorPoint.y)
            let toDeltaOffset = CGPoint(x: -fromDeltaOffset.x, y: -fromDeltaOffset.y)

            let fromOffset = CGPoint(x: 0.0 * (1.0 - progress) + fromDeltaOffset.x * progress, y: 0.0 * (1.0 - progress) + fromDeltaOffset.y * progress)
            let toOffset = CGPoint(x: toDeltaOffset.x * (1.0 - progress) + 0.0 * progress, y: toDeltaOffset.y * (1.0 - progress) + 0.0 * progress)

            var fromTransform = CGAffineTransform.identity
            fromTransform = fromTransform.translatedBy(x: fromAnchorPoint.x, y: fromAnchorPoint.y)
            fromTransform = fromTransform.translatedBy(x: fromOffset.x, y: fromOffset.y)
            fromTransform = fromTransform.scaledBy(x: fromScale, y: fromScale)
            fromTransform = fromTransform.translatedBy(x: -fromAnchorPoint.x, y: -fromAnchorPoint.y)


            var toTransform = CGAffineTransform.identity
            toTransform = toTransform.translatedBy(x: toAnchorPoint.x, y: toAnchorPoint.y)
            toTransform = toTransform.translatedBy(x: toOffset.x, y: toOffset.y)
            toTransform = toTransform.scaledBy(x: toScale, y: toScale)
            toTransform = toTransform.translatedBy(x: -toAnchorPoint.x, y: -toAnchorPoint.y)

            transition.updateTransform(node: self.fromViewport, transform: fromTransform)
            transition.updateTransform(node: self.toViewport, transform: toTransform)
            
            transition.updateAlpha(node: self.toViewport, alpha: progress, completion: { _ in
                completion()
            })

            let fromAlphaStartProgress: CGFloat = 0.6
            let fromAlphaEndProgress: CGFloat = 1.0
            let fromAlphaProgress = max(0.0, progress - fromAlphaStartProgress) / (fromAlphaEndProgress - fromAlphaStartProgress)

            if previousProgress < fromAlphaStartProgress, progress == 1.0, case let .animated(duration, _) = transition {
                transition.updateAlpha(node: self.fromViewport, alpha: 1.0 - fromAlphaProgress, delay: duration * 0.5)
            } else {
                transition.updateAlpha(node: self.fromViewport, alpha: 1.0 - fromAlphaProgress)
            }
        }
    }

    private struct ContainerLayout: Equatable {
        var size: CGSize
        var insets: UIEdgeInsets
        var scrollIndicatorInsets: UIEdgeInsets
        var lockScrollingAtTop: Bool
        var fixedItemHeight: CGFloat?
    }

    private var tapRecognizer: UITapGestureRecognizer?
    private var pinchRecognizer: UIPinchGestureRecognizer?

    private var containerLayout: ContainerLayout?
    private var items: Items?

    private var currentViewport: Viewport?
    private var currentViewportTransition: ViewportTransition?
    private let scrollingArea: SparseItemGridScrollingArea

    private var isLoadingHole: Bool = false
    private let loadingHoleDisposable = MetaDisposable()

    public var coveringInsetOffset: CGFloat {
        if let currentViewport = self.currentViewport {
            return currentViewport.coveringInsetOffset
        }
        return 0.0
    }

    override public init() {
        self.scrollingArea = SparseItemGridScrollingArea()

        super.init()

        self.clipsToBounds = true

        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.tapGesture(_:)))
        self.tapRecognizer = tapRecognizer
        self.view.addGestureRecognizer(tapRecognizer)

        let pinchRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(self.pinchGesture(_:)))
        self.pinchRecognizer = pinchRecognizer
        self.view.addGestureRecognizer(pinchRecognizer)

        self.addSubnode(self.scrollingArea)
        self.scrollingArea.openCurrentDate = { [weak self] in
            guard let strongSelf = self, let items = strongSelf.items else {
                return
            }
            items.itemBinding.onTagTap()
        }
    }

    @objc private func tapGesture(_ recognizer: UITapGestureRecognizer) {
        guard let currentViewport = self.currentViewport, let items = self.items else {
            return
        }
        if self.currentViewportTransition != nil {
            return
        }
        if case .ended = recognizer.state {
            let location = recognizer.location(in: self.view)
            if let item = currentViewport.item(at: self.view.convert(location, to: currentViewport.view)) {
                items.itemBinding.onTap(item: item)
            }
        }
    }

    @objc private func pinchGesture(_ recognizer: UIPinchGestureRecognizer) {
        guard let containerLayout = self.containerLayout, let items = self.items else {
            return
        }

        switch recognizer.state {
        case .began:
            break
        case .changed:
            let scale = recognizer.scale
            if let currentViewportTransition = self.currentViewportTransition, let interactiveState = currentViewportTransition.interactiveState {

                let progress = (scale - interactiveState.initialScale) / (interactiveState.targetScale - interactiveState.initialScale)
                var replacedTransition = false
                //print("progress: \(progress), scale: \(scale), initial: \(interactiveState.initialScale), target: \(interactiveState.targetScale)")
                if progress < 0.0 || progress > 1.0 {
                    let boundaryViewport = progress > 1.0 ? currentViewportTransition.toViewport : currentViewportTransition.fromViewport
                    let zoomLevels = self.availableZoomLevels(startingAt: boundaryViewport.zoomLevel)

                    let isZoomingIn = interactiveState.targetScale > interactiveState.initialScale
                    var nextZoomLevel: ZoomLevel?
                    let startScale = progress > 1.0 ? interactiveState.targetScale : interactiveState.initialScale
                    let nextScale: CGFloat
                    if isZoomingIn {
                        if progress > 1.0 {
                            nextZoomLevel = zoomLevels.increment
                            nextScale = startScale * 2.0
                        } else {
                            nextZoomLevel = zoomLevels.decrement
                            nextScale = startScale * 0.5
                        }
                    } else {
                        if progress > 1.0 {
                            nextZoomLevel = zoomLevels.decrement
                            nextScale = startScale * 0.5
                        } else {
                            nextZoomLevel = zoomLevels.increment
                            nextScale = startScale * 2.0
                        }
                    }

                    if let nextZoomLevel = nextZoomLevel, let anchorItemFrame = boundaryViewport.frameForItem(at: currentViewportTransition.anchorItemIndex) {
                        replacedTransition = true

                        let restoreScrollPosition: (y: CGFloat, index: Int)? = (anchorItemFrame.minY, currentViewportTransition.anchorItemIndex)

                        let nextViewport = Viewport(zoomLevel: nextZoomLevel, maybeLoadHoleAnchor: { [weak self] holeAnchor, location in
                            guard let strongSelf = self else {
                                return
                            }
                            strongSelf.maybeLoadHoleAnchor(holeAnchor: holeAnchor, location: location)
                        })

                        nextViewport.frame = CGRect(origin: CGPoint(), size: containerLayout.size)
                        nextViewport.update(containerLayout: containerLayout, items: items, restoreScrollPosition: restoreScrollPosition)

                        self.currentViewportTransition?.removeFromSupernode()

                        let currentViewportTransition = ViewportTransition(interactiveState: ViewportTransition.InteractiveState(initialScale: startScale, targetScale: nextScale), layout: containerLayout, anchorItemIndex: currentViewportTransition.anchorItemIndex, from: boundaryViewport, to: nextViewport)
                        currentViewportTransition.frame = CGRect(origin: CGPoint(), size: containerLayout.size)
                        self.insertSubnode(currentViewportTransition, belowSubnode: self.scrollingArea)
                        self.currentViewportTransition = currentViewportTransition
                        currentViewportTransition.update(progress: progress, transition: .immediate, completion: {})
                    }
                }

                if !replacedTransition {
                    currentViewportTransition.update(progress: min(1.0, max(0.0, progress)), transition: .immediate, completion: {})
                }
            } else if scale != 1.0 {
                let zoomLevels = self.availableZoomLevels()
                var nextZoomLevel: ZoomLevel?
                if scale > 1.0 {
                    nextZoomLevel = zoomLevels.increment
                } else {
                    nextZoomLevel = zoomLevels.decrement
                }
                if let previousViewport = self.currentViewport, let nextZoomLevel = nextZoomLevel {
                    let interactiveState = ViewportTransition.InteractiveState(initialScale: 1.0, targetScale: scale > 1.0 ? 2.0 : 0.5)

                    var progress = (scale - interactiveState.initialScale) / (interactiveState.targetScale - interactiveState.initialScale)
                    progress = max(0.0, min(1.0, progress))

                    let anchorLocation = recognizer.location(in: self.view)

                    if let anchorItem = previousViewport.anchorItem(at: anchorLocation), let anchorItemFrame = previousViewport.frameForItem(at: anchorItem.index) {
                        let restoreScrollPosition: (y: CGFloat, index: Int)? = (anchorItemFrame.minY, anchorItem.index)
                        let anchorItemIndex = anchorItem.index

                        let nextViewport = Viewport(zoomLevel: nextZoomLevel, maybeLoadHoleAnchor: { [weak self] holeAnchor, location in
                            guard let strongSelf = self else {
                                return
                            }
                            strongSelf.maybeLoadHoleAnchor(holeAnchor: holeAnchor, location: location)
                        })

                        nextViewport.frame = CGRect(origin: CGPoint(), size: containerLayout.size)
                        nextViewport.update(containerLayout: containerLayout, items: items, restoreScrollPosition: restoreScrollPosition)

                        let currentViewportTransition = ViewportTransition(interactiveState: interactiveState, layout: containerLayout, anchorItemIndex: anchorItemIndex, from: previousViewport, to: nextViewport)
                        currentViewportTransition.frame = CGRect(origin: CGPoint(), size: containerLayout.size)
                        self.insertSubnode(currentViewportTransition, belowSubnode: self.scrollingArea)
                        self.currentViewportTransition = currentViewportTransition
                        currentViewportTransition.update(progress: progress, transition: .immediate, completion: {})
                    }
                }
            }
        case .ended, .cancelled:
            if let currentViewportTransition = self.currentViewportTransition, let interactiveState = currentViewportTransition.interactiveState {
                let scale = recognizer.scale
                var currentProgress = (scale - interactiveState.initialScale) / (interactiveState.targetScale - interactiveState.initialScale)
                currentProgress = max(0.0, min(1.0, currentProgress))
                let progress = currentProgress < 0.3 ? 0.0 : 1.0

                currentViewportTransition.update(progress: progress, transition: .animated(duration: 0.2, curve: .easeInOut), completion: { [weak self, weak currentViewportTransition] in
                    guard let strongSelf = self, let currentViewportTransition = currentViewportTransition else {
                        return
                    }

                    let previousViewport = strongSelf.currentViewport

                    strongSelf.currentViewport = progress < 0.5 ? currentViewportTransition.fromViewport : currentViewportTransition.toViewport

                    if let previousViewport = previousViewport, previousViewport !== strongSelf.currentViewport {
                        previousViewport.removeFromSupernode()
                    }

                    if let containerLayout = strongSelf.containerLayout, let currentViewport = strongSelf.currentViewport, let items = strongSelf.items {
                        strongSelf.insertSubnode(currentViewport, belowSubnode: strongSelf.scrollingArea)
                        strongSelf.scrollingArea.frame = CGRect(origin: CGPoint(), size: containerLayout.size)
                        currentViewport.setScrollingArea(scrollingArea: strongSelf.scrollingArea)
                        currentViewport.frame = CGRect(origin: CGPoint(), size: containerLayout.size)
                        currentViewport.update(containerLayout: containerLayout, items: items, restoreScrollPosition: nil)
                    }

                    strongSelf.currentViewportTransition = nil
                    currentViewportTransition.removeFromSupernode()
                })
            }
        default:
            break
        }
    }

    public func update(size: CGSize, insets: UIEdgeInsets, scrollIndicatorInsets: UIEdgeInsets, lockScrollingAtTop: Bool, fixedItemHeight: CGFloat?, items: Items) {
        let containerLayout = ContainerLayout(size: size, insets: insets, scrollIndicatorInsets: scrollIndicatorInsets, lockScrollingAtTop: lockScrollingAtTop, fixedItemHeight: fixedItemHeight)
        self.containerLayout = containerLayout
        self.items = items
        self.scrollingArea.isHidden = lockScrollingAtTop

        self.tapRecognizer?.isEnabled = fixedItemHeight == nil
        self.pinchRecognizer?.isEnabled = fixedItemHeight == nil

        if self.currentViewport == nil {
            let currentViewport = Viewport(zoomLevel: ZoomLevel(rawValue: 100), maybeLoadHoleAnchor: { [weak self] holeAnchor, location in
                guard let strongSelf = self else {
                    return
                }
                strongSelf.maybeLoadHoleAnchor(holeAnchor: holeAnchor, location: location)
            })
            self.currentViewport = currentViewport
            self.insertSubnode(currentViewport, belowSubnode: self.scrollingArea)

            currentViewport.setScrollingArea(scrollingArea: self.scrollingArea)
        }

        if let _ = self.currentViewportTransition {
        } else if let currentViewport = self.currentViewport {
            self.scrollingArea.frame = CGRect(origin: CGPoint(), size: size)
            currentViewport.frame = CGRect(origin: CGPoint(), size: size)
            currentViewport.update(containerLayout: containerLayout, items: items, restoreScrollPosition: nil)
        }
    }

    private func maybeLoadHoleAnchor(holeAnchor: HoleAnchor, location: HoleLocation) {
        if self.isLoadingHole {
            return
        }
        guard let items = self.items else {
            return
        }

        self.isLoadingHole = true
        self.loadingHoleDisposable.set((items.itemBinding.loadHole(anchor: holeAnchor, at: location)
        |> deliverOnMainQueue).start(completed: { [weak self] in
            guard let strongSelf = self else {
                return
            }
            strongSelf.isLoadingHole = false
            if let currentViewport = strongSelf.currentViewport {
                currentViewport.updateHoleToLoad()
            }
        }))
    }

    public func availableZoomLevels() -> (decrement: ZoomLevel?, increment: ZoomLevel?) {
        guard let currentViewport = self.currentViewport else {
            return (nil, nil)
        }
        return self.availableZoomLevels(startingAt: currentViewport.zoomLevel)
    }

    private func availableZoomLevels(startingAt zoomLevel: ZoomLevel) -> (decrement: ZoomLevel?, increment: ZoomLevel?) {
        let zoomLevels: [ZoomLevel] = [
            ZoomLevel(rawValue: 25),
            ZoomLevel(rawValue: 40),
            ZoomLevel(rawValue: 75),
            ZoomLevel(rawValue: 100),
            ZoomLevel(rawValue: 150)
        ]
        if let index = zoomLevels.firstIndex(of: zoomLevel) {
            return (index == 0 ? nil : zoomLevels[index - 1], index == (zoomLevels.count - 1) ? nil : zoomLevels[index + 1])
        } else {
            return (nil, nil)
        }
    }

    public func setZoomLevel(level: ZoomLevel) {
        guard let previousViewport = self.currentViewport else {
            return
        }
        if self.currentViewportTransition != nil {
            return
        }
        self.currentViewport = nil
        previousViewport.removeFromSupernode()

        let currentViewport = Viewport(zoomLevel: level, maybeLoadHoleAnchor: { [weak self] holeAnchor, location in
            guard let strongSelf = self else {
                return
            }
            strongSelf.maybeLoadHoleAnchor(holeAnchor: holeAnchor, location: location)
        })
        self.currentViewport = currentViewport
        self.insertSubnode(currentViewport, belowSubnode: self.scrollingArea)

        if let containerLayout = self.containerLayout, let items = self.items {
            let anchorLocation = CGPoint(x: 0.0, y: 10.0)
            if let anchorItem = previousViewport.anchorItem(at: anchorLocation), let anchorItemFrame = previousViewport.frameForItem(at: anchorItem.index) {
                let restoreScrollPosition: (y: CGFloat, index: Int)? = (anchorItemFrame.minY, anchorItem.index)
                let anchorItemIndex = anchorItem.index

                self.scrollingArea.frame = CGRect(origin: CGPoint(), size: containerLayout.size)
                currentViewport.frame = CGRect(origin: CGPoint(), size: containerLayout.size)
                currentViewport.update(containerLayout: containerLayout, items: items, restoreScrollPosition: restoreScrollPosition)

                let currentViewportTransition = ViewportTransition(interactiveState: nil, layout: containerLayout, anchorItemIndex: anchorItemIndex, from: previousViewport, to: currentViewport)
                currentViewportTransition.frame = CGRect(origin: CGPoint(), size: containerLayout.size)
                self.insertSubnode(currentViewportTransition, belowSubnode: self.scrollingArea)
                self.currentViewportTransition = currentViewportTransition
                currentViewportTransition.update(progress: 0.0, transition: .immediate, completion: {})
                currentViewportTransition.update(progress: 1.0, transition: .animated(duration: 0.25, curve: .easeInOut), completion: { [weak self] in
                    guard let strongSelf = self else {
                        return
                    }

                    if let containerLayout = strongSelf.containerLayout, let currentViewport = strongSelf.currentViewport, let items = strongSelf.items {
                        strongSelf.insertSubnode(currentViewport, belowSubnode: strongSelf.scrollingArea)
                        strongSelf.scrollingArea.frame = CGRect(origin: CGPoint(), size: containerLayout.size)
                        currentViewport.frame = CGRect(origin: CGPoint(), size: containerLayout.size)
                        currentViewport.update(containerLayout: containerLayout, items: items, restoreScrollPosition: nil)
                    }

                    strongSelf.currentViewport?.setScrollingArea(scrollingArea: strongSelf.scrollingArea)

                    if let currentViewportTransition = strongSelf.currentViewportTransition {
                        strongSelf.currentViewportTransition = nil
                        currentViewportTransition.removeFromSupernode()
                    }
                })
            }
        }
    }

    public func forEachVisibleItem(_ f: (SparseItemGridDisplayItem) -> Void) {
        guard let currentViewport = self.currentViewport else {
            return
        }
        for (_, itemLayer) in currentViewport.visibleItems {
            f(itemLayer)
        }
    }

    public func frameForItem(layer: SparseItemGridLayer) -> CGRect {
        guard let currentViewport = self.currentViewport else {
            return layer.bounds
        }
        return self.view.convert(currentViewport.frameForItem(layer: layer), from: currentViewport.view)
    }

    public func scrollToItem(at index: Int) {
        guard let currentViewport = self.currentViewport else {
            return
        }
        currentViewport.scrollToItem(at: index)
    }

    public func scrollToTop() -> Bool {
        guard let currentViewport = self.currentViewport else {
            return false
        }
        return currentViewport.scrollToTop()
    }

    public func addToTransitionSurface(view: UIView) {
        self.view.insertSubview(view, belowSubview: self.scrollingArea.view)
    }

    public func updateScrollingAreaTooltip(tooltip: SparseItemGridScrollingArea.DisplayTooltip) {
        self.scrollingArea.displayTooltip = tooltip
    }
}
