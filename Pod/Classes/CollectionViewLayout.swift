//
//  CollectionViewLayout.swift
//  Pods
//
//  Created by Roberto Previdi on 24/08/16.
//
//

import Foundation

extension Array {
	mutating func extend(toSize:Int,fillValue:Element)
	{
		if count<toSize
		{
			reserveCapacity(toSize)
			appendContentsOf(Array<Element>(count: toSize-count, repeatedValue: fillValue))
		}
	}
}

public struct CachedSequence<T>
{
	var values=[T]()
	public var dirty=[Bool]()
	let calculateValue:(index:Int)->T
	let dummyValue:T
	init(calculateValue:(index:Int)->T,dummyValue:T)
	{
		self.calculateValue=calculateValue
		self.dummyValue=dummyValue
	}
	mutating func setDirty(index:Int,value:Bool)
	{
		dirty.extend(index+1, fillValue: true)
		dirty[index]=value
	}
	func isDirty(index:Int)->Bool
	{
		return dirty.count>index && dirty[index] || dirty.count<=index
	}
	mutating public func get(index:Int)->T
	{
		if isDirty(index) {
			values.extend(index+1, fillValue: dummyValue)
			values[index]=calculateValue(index:index)
			setDirty(index, value: false)
		}
		return values[index]
	}
	mutating func invalidate()
	{
		dirty=[Bool]()
	}
	mutating func invalidate(index:Int)
	{
		setDirty(index, value: true)
	}
	mutating func invalidate(range:Range<Int>)
	{
		dirty.extend(range.endIndex, fillValue: true)
		for index in range
		{
			dirty[index]=true
		}
	}
}


public class DynamicCollectionViewLayout: UICollectionViewLayout
{
	var contentWidth:CGFloat {
		let insets=collectionView!.contentInset
		return collectionView!.bounds.size.width-insets.left-insets.right
	}
	var contentHeight=CGFloat(0)
	public override func collectionViewContentSize() -> CGSize {
		return CGSize(width: contentWidth, height: contentHeight)
	}
	let ySpacing:CGFloat
	var cellSizes:CachedSequence<CGSize>!
	
	init(ySpacing:CGFloat=8) {
		self.ySpacing=ySpacing
		super.init()
		cellSizes=CachedSequence<CGSize>(calculateValue: {
			index in
			let indexPath=NSIndexPath(forItem: index, inSection: 0)
			guard let cell=self.collectionView!.cellForItemAtIndexPath(indexPath) else {return CGSizeZero }
			
//			cell.bounds = CGRectMake(0, 0, self.contentWidth, cell.bounds.height)
//			cell.contentView.bounds = cell.bounds
//			
//			// Layout subviews, this will let labels on this cell to set preferredMaxLayoutWidth
//			cell.setNeedsLayout()
//			cell.layoutIfNeeded()
			
			var size = cell.contentView.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize)
			// Still need to force the width, since width can be smalled due to break mode of labels
			size.width = self.contentWidth
			return size
		},dummyValue: CGSizeZero)
	}
	
	required public init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	var attributesCache=[UICollectionViewLayoutAttributes]()
	public override func prepareLayout() {
		var y=CGFloat(0)
		attributesCache.removeAll()
		for item in 0..<collectionView!.numberOfItemsInSection(0)
		{
			let origin=CGPoint(x:collectionView!.contentInset.left, y:y)
			let frame=CGRect(origin: origin, size: cellSizes.get(item))
			y += ySpacing+frame.size.height
			let attr=UICollectionViewLayoutAttributes(forCellWithIndexPath: NSIndexPath(forItem: item, inSection: 0))
			attr.frame=frame
			attributesCache.append(attr)
		}
		contentHeight=y
	}
	
	public override func layoutAttributesForElementsInRect(rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
		
		var layoutAttributes = [UICollectionViewLayoutAttributes]()
		
		for attributes in attributesCache {
			if CGRectIntersectsRect(attributes.frame, rect) {
				layoutAttributes.append(attributes)
			}
		}
		return layoutAttributes
	}

	public override func invalidateLayout() {
		cellSizes.invalidate()
		super.invalidateLayout()
	}
	
	public override func invalidateLayoutWithContext(context: UICollectionViewLayoutInvalidationContext) {
		cellSizes.invalidate()
//		context.invalidatedItemIndexPaths?.forEach{ (ip) in
//			cellSizes.invalidate(ip.item)
//		}
		super.invalidateLayoutWithContext(context)
	}
	
	
}