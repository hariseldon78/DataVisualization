//
//  ViewController.swift
//  DataVisualization
//
//  Created by Roberto Previdi on 12/27/2015.
//  Copyright (c) 2015 Roberto Previdi. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class ViewController: UIViewController,AutoSingleLevelTableView {

	@IBOutlet weak var tableView: UITableView!
	
	let disposeBag=DisposeBag()
	typealias Data=Worker
	typealias Cell=TitleCell

	func data()->Observable<[Worker]>
	{
		return Worker.api()
	}

	override func viewDidLoad() {
        super.viewDidLoad()
		setupTableView(tableView)
    }


}

