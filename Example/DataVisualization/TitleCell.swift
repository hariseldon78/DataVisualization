//
//  TitleCell.swift
//  DataVisualization
//
//  Created by Roberto Previdi on 27/12/15.
//  Copyright © 2015 CocoaPods. All rights reserved.
//

import UIKit

class TitleCell: UITableViewCell {

	@IBOutlet weak var title: UILabel!
	
	override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		print("init(style: style, reuseIdentifier: reuseIdentifier)")
	}
	
	init(){
		super.init(style: UITableViewCellStyle.Default, reuseIdentifier: "cell")
		print("init()")
	}
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		print("init?(coder aDecoder: NSCoder)")
	}
	
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
