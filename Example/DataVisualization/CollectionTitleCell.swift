//
//  CollectionTitleCell.swift
//  DataVisualization
//
//  Created by Roberto Previdi on 22/06/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import UIKit
import RxSwift

extension UICollectionViewCell {
	var collectionView:UICollectionView? {
		while let sv=self.superview {
			if sv is UICollectionView {
				return (sv as! UICollectionView)
			}
		}
		return nil
	}
}

class CollectionTitleCell: UICollectionViewCell {

	@IBOutlet weak var title: UITextView!
	@IBOutlet weak var details: UITextView!
	let disposeBag=DisposeBag()
	
	@IBOutlet weak var detailsWidth: NSLayoutConstraint!
	@IBOutlet weak var detailsHeight: NSLayoutConstraint!
	
	var indexPath:IndexPath?
	var resizeSink:PublishSubject<Void>?
    override func awakeFromNib() {
        super.awakeFromNib()
		print("awakeFromNib")
        // Initialization code
		
		Observable<Int>
			.timer(Double(arc4random()%10+2), period: Double(arc4random()%10+2), scheduler: MainScheduler.instance)
			.subscribe(onNext: { _ in
				self.detailsWidth.constant=20.0+CGFloat(arc4random()%300)
				self.resizeSink?.onNext()
//				print("invalidateLayout")
//				self.collectionView?.collectionViewLayout.invalidateLayout()
//				
			}).addDisposableTo(disposeBag)
	}
	
}
