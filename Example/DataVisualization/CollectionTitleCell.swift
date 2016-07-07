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
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
		
		Observable<Int>
			.timer(Double(random()%10), period: Double(random()%10), scheduler: MainScheduler.instance)
			.subscribeNext { _ in
				self.detailsWidth.constant=20.0+CGFloat(random()%300)
				self.collectionView?.collectionViewLayout.invalidateLayout()
		}.addDisposableTo(disposeBag)
    }

}
