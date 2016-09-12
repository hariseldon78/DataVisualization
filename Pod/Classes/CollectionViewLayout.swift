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
	enum CollectionViewLayoutEvent {
		case None
		
		case InvalidateLayout
	}
	
	let 🗑=DisposeBag()
	var contentWidth:CGFloat {
		let insets=collectionView!.contentInset
		return collectionView!.bounds.size.width-insets.left-insets.right
	}

	var contentHeight=CGFloat(0)
	public override func collectionViewContentSize() -> CGSize {
		return CGSize(width: contentWidth, height: contentHeight)
	}
	let spacings:CellSpacings
	var cellSizes:Driver<[CGSize]>
	init(cellSizes:Driver<[CGSize]>,spacings:CellSpacings) {
		self.spacings=spacings
		self.cellSizes=cellSizes
		super.init()
		
		let yOffsets:Driver<[CGFloat]>=cellSizes.map {
			(sizes:[CGSize]) in
			var offsets=[CGFloat]()
			offsets.append(spacings.verticalBorder/*+(self.collectionView?.contentInset.top ?? 0) pare che sia già calcolato...*/)
			for i in 0 ..< sizes.count-1 {
				offsets.append(offsets.last!+self.spacings.verticalSpacing+sizes[i].height)
			}
			self.contentHeight=offsets.last!+(sizes.last?.height ?? 0)+self.spacings.verticalBorder+(self.collectionView?.contentInset.bottom ?? 0)
			return offsets
		}
		
		let cellsInfo:Driver<[(Int,CGSize,CGFloat)]>=Driver
			.combineLatest(cellSizes, yOffsets) {
				(size,y) in
				let zipped=Array(zip(GeneratorSequence(IntGenerator()),b:size,c:y))
				return zipped
		}
		
		cellsInfo
			.asObservable()
			.observeOn(MainScheduler.instance)
			.subscribeOn(MainScheduler.instance)
			.subscribeNext { (cellInfo) in
				self.attributesCache=cellInfo.map { (index,size,y) in
					let origin=CGPoint(x:(self.collectionView?.contentInset.left ?? 0) + self.spacings.horizontalBorder, y:y)
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
		guard collectionView?.numberOfSections()>0 else { return [UICollectionViewLayoutAttributes]() }
		let count=collectionView?.dataSource?.collectionView(collectionView!, numberOfItemsInSection: 0) ?? 0
		let subset=attributesCache[0..<min(count,attributesCache.count)]
		let ret=subset.filter{ CGRectIntersectsRect($0.frame, rect)	}
//		print("layoutAttributesForElementsInRect(rect:\(rect))->\(ret)")
		return ret
	}
}