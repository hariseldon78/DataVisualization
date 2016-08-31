//
//  CollectionViewLayout.swift
//  Pods
//
//  Created by Roberto Previdi on 24/08/16.
//
//

import Foundation
import RxSwift
import RxCocoa

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
struct Zip3Generator
	<
	A: GeneratorType,
	B: GeneratorType,
	C: GeneratorType
>: GeneratorType {
	
	private var first: A
	private var second: B
	private var third: C
	
	private var index = 0
	
	init(_ first: A, _ second: B, _ third: C) {
		self.first = first
		self.second = second
		self.third = third
	}
	
	mutating func next() -> (A.Element, B.Element, C.Element)? {
		if let a = first.next(), b = second.next(), c = third.next() {
			return (a, b, c)
		}
		return nil
	}
}

func zip<A: SequenceType, B: SequenceType, C: SequenceType>(a: A, b: B, c: C) -> GeneratorSequence<Zip3Generator<A.Generator, B.Generator, C.Generator>> {
	return GeneratorSequence(Zip3Generator(a.generate(), b.generate(), c.generate()))
}

struct IntGenerator:GeneratorType {
	private var index = -1
	mutating func next() -> Int? {
		index+=1
		return index
	}
}

public class DynamicCollectionViewLayout: UICollectionViewLayout
{
	let 🗑=DisposeBag()
	var contentWidth:CGFloat {
		let insets=collectionView!.contentInset
		return collectionView!.bounds.size.width-insets.left-insets.right
	}
	var contentHeight=CGFloat(0)
	public override func collectionViewContentSize() -> CGSize {
		return CGSize(width: contentWidth, height: contentHeight)
	}
	let ySpacing:CGFloat
	var cellSizes:Driver<[CGSize]>
	init(cellSizes:Driver<[CGSize]>,ySpacing:CGFloat=8) {
		self.ySpacing=ySpacing
		self.cellSizes=cellSizes
		super.init()
		
		let yOffsets:Driver<[CGFloat]>=cellSizes.map {
			(sizes:[CGSize]) in
			var offsets=[CGFloat]()
			offsets.append(ySpacing)
			for i in 0 ..< sizes.count-1 {
				offsets.append(offsets.last!+ySpacing+sizes[i].height)
			}
			self.contentHeight=offsets.last!+ySpacing+(sizes.last?.height ?? 0)
			return offsets
		}
		
		let cellsInfo:Driver<[(Int,CGSize,CGFloat)]>=Driver
			.combineLatest(cellSizes, yOffsets) {
				let zipped=Array(zip(GeneratorSequence(IntGenerator()),b:$0,c:$1))
				return zipped
		}
		
		cellsInfo
			.asObservable()
			.subscribeNext { (cellInfo) in
				self.attributesCache=cellInfo.map { (index,size,y) in
					print(index,size,y)
					let origin=CGPoint(x:self.collectionView?.contentInset.left ?? 0, y:y)
					let frame=CGRect(origin: origin, size: size)
					let attr=UICollectionViewLayoutAttributes(forCellWithIndexPath: NSIndexPath(forItem: index, inSection: 0))
					attr.frame=frame
					return attr
				}
				self.invalidateLayout()
			}.addDisposableTo(🗑)
	}
	
	required public init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	var attributesCache=[UICollectionViewLayoutAttributes]()
	
	public override func layoutAttributesForElementsInRect(rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
		
		var layoutAttributes = [UICollectionViewLayoutAttributes]()
		
		for attributes in attributesCache {
			if CGRectIntersectsRect(attributes.frame, rect) {
				layoutAttributes.append(attributes)
			}
		}
		return layoutAttributes
	}
}