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
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


extension Array {
	mutating func extend(_ toSize:Int,fillValue:Element)
	{
		if count<toSize
		{
			reserveCapacity(toSize)
			append(contentsOf: Array<Element>(repeating: fillValue, count: toSize-count))
		}
	}
}
struct Zip3Generator <
		A: IteratorProtocol,
		B: IteratorProtocol,
		C: IteratorProtocol
	>: IteratorProtocol {
	
	fileprivate var first: A
	fileprivate var second: B
	fileprivate var third: C
	
	fileprivate var index = 0
	
	init(_ first: A, _ second: B, _ third: C) {
		self.first = first
		self.second = second
		self.third = third
	}
	
	mutating func next() -> (A.Element, B.Element, C.Element)? {
		if let a = first.next(), let b = second.next(), let c = third.next() {
			return (a, b, c)
		}
		return nil
	}
}

func zip<A: Sequence, B: Sequence, C: Sequence>(_ a: A, b: B, c: C) -> IteratorSequence<Zip3Generator<A.Iterator, B.Iterator, C.Iterator>> {
	return IteratorSequence(Zip3Generator(a.makeIterator(), b.makeIterator(), c.makeIterator()))
}

struct IntGenerator:IteratorProtocol {
	fileprivate var index = -1
	mutating func next() -> Int? {
		index+=1
		return index
	}
}

open class DynamicCollectionViewLayout: UICollectionViewLayout
{
	enum CollectionViewLayoutEvent {
		case none
		
		case invalidateLayout
	}
	
	let 🗑=DisposeBag()
	var contentWidth:CGFloat {
		let insets=collectionView!.contentInset
		return collectionView!.bounds.size.width-insets.left-insets.right
	}

	var contentHeight=CGFloat(0)
	open override var collectionViewContentSize : CGSize {
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
			if sizes.count>0 {
				offsets.append(spacings.verticalBorder/*+(self.collectionView?.contentInset.top ?? 0) pare che sia già calcolato...*/)
				for i in 0 ..< sizes.count-1 {
					offsets.append(offsets.last!+self.spacings.verticalSpacing+sizes[i].height)
				}
			}
			self.contentHeight=(offsets.last ?? 0)+(sizes.last?.height ?? 0)+self.spacings.verticalBorder+(self.collectionView?.contentInset.bottom ?? 0)
			return offsets
		}
		
		let cellsInfo:Driver<[(Int,CGSize,CGFloat)]>=Driver
			.combineLatest(cellSizes, yOffsets) {
				(size,y) in
				let zipped=Array(zip(IteratorSequence(IntGenerator()),b:size,c:y))
				return zipped
		}
		
		cellsInfo
			.asObservable()
			.observeOn(MainScheduler.instance)
			.subscribeOn(MainScheduler.instance)
			.subscribe(onNext: { (cellInfo) in
				let newCache:[UICollectionViewLayoutAttributes]=cellInfo.map { (index,size,y) in
					let origin=CGPoint(x:(self.collectionView?.contentInset.left ?? 0) + self.spacings.horizontalBorder, y:y)
					let frame=CGRect(origin: origin, size: size)
					let attr=UICollectionViewLayoutAttributes(forCellWith: IndexPath(item: index, section: 0))
					attr.frame=frame
					return attr
				}
				self.attributesCache=newCache
				self.invalidateLayout()
			}).addDisposableTo(🗑)
	}
	
	required public init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	var attributesCache=[UICollectionViewLayoutAttributes]()
	
	open override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
		guard collectionView?.numberOfSections>0 else { return [UICollectionViewLayoutAttributes]() }
		let count=collectionView?.dataSource?.collectionView(collectionView!, numberOfItemsInSection: 0) ?? 0
		let subset=attributesCache[0..<min(count,attributesCache.count)]
		let ret=subset.filter{ $0.frame.intersects(rect)	}
		return ret
	}
	open override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
		return attributesCache[indexPath.row]
	}
}
