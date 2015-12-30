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

class PlainViewController:UIViewController
{
	@IBOutlet weak var tableView: UITableView!
	let tvManager=AutoSingleLevelTableViewManager<Worker>()
	override func viewDidLoad() {
		super.viewDidLoad()
		tvManager.setupTableView(tableView)
	}
}

class FunkyViewController:UIViewController {
	@IBOutlet weak var tableView: UITableView!
	let tvManager=AutoSingleLevelTableViewManager<Worker>()
	override func viewDidLoad() {
		super.viewDidLoad()
		tvManager.viewModel=ConcreteViewModel<Worker,FunkyCell>(cellName: "FunkyCell") {
			(index, item, cell) -> Void in
			cell.title.text=item.name
			cell.subtitle.text="salary: €\(item.salary)"
		}
		
		tvManager.setupTableView(tableView)
	}
}

class PlainSectionedViewController:UIViewController {
	@IBOutlet weak var tableView: UITableView!
	let tvManager=AutoSectionedTableViewManager<Worker,Department,WorkerSectioner>()
	override func viewDidLoad() {
		super.viewDidLoad()
		tvManager.setupTableView(tableView)
		
	}
}