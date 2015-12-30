//
//  TitleHeader.swift
//  DataVisualization
//
//  Created by Roberto Previdi on 30/12/15.
//  Copyright © 2015 CocoaPods. All rights reserved.
//

import UIKit

class TitleHeader: UITableViewHeaderFooterView {
	@IBOutlet weak var title: UILabel!
}
class TTitleHeader: UITableViewHeaderFooterView {
	override init(reuseIdentifier: String?) {
		super.init(reuseIdentifier: reuseIdentifier)
		_init()
	}
	required init?(coder aDecoder: NSCoder) {
		super.init(coder:aDecoder)
		_init()
	}
	func _init()
	{
		contentView.addSubview(title)
		contentView.backgroundColor=UIColor.redColor()
		self.frame=CGRectMake(0, 0, 300, 100)
		contentView.frame=self.frame
	}

	var title=UILabel()
}