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

class PlainViewController: UIViewController,AutoSingleLevelTableView {

	@IBOutlet weak var tableView: UITableView!
	
	let disposeBag=DisposeBag()
	typealias Data=Worker

	let data=Worker.api()

	override func viewDidLoad() {
        super.viewDidLoad()
		setupTableView(tableView)
    }
}

class FunkyViewController: UIViewController,AutoSingleLevelTableView {
	
	@IBOutlet weak var tableView: UITableView!
	
	let disposeBag=DisposeBag()
	typealias Data=Worker
	func viewModel()->ViewModel {
		return ConcreteViewModel<Worker,FunkyCell>(cellName: "FunkyCell") { (index, item, cell) -> Void in
			cell.title.text=item.name
			cell.subtitle.text="salary: €\(item.salary)"
		}
	}
	let data=Worker.api()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		setupTableView(tableView)
	}
}

