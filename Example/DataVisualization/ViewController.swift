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
	
	typealias Data=Worker
	typealias Cell=TitleCell
//	let disposeBag=DisposeBag()
	func data()->Observable<[Worker]>
	{
		return Worker.api()
	}

	func cellFactory(item: Data, cell: Cell) {
		cell.textLabel?.text=item.name
	}
	override func viewDidLoad() {
        super.viewDidLoad()
		setupTableView(tableView)
    }


}

