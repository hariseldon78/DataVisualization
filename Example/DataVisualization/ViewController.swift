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
		tvManager.setupTableView(tableView,vc:self)
		tvManager.setupDetail("detail")
	}
	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		tvManager.prepareForSegue(segue,sender:sender)
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
		
		tvManager.setupTableView(tableView,vc:self)
	}
}

class PlainSectionedViewController:UIViewController {
	@IBOutlet weak var tableView: UITableView!
	let tvManager=AutoSectionedTableViewManager<Worker,Department,WorkerSectioner>()
	override func viewDidLoad() {
		super.viewDidLoad()
		tvManager.setupTableView(tableView,vc:self)
	}
}

class WorkerDetail1:UIViewController,DetailView
{
	@IBOutlet weak var label1: UILabel!
	@IBOutlet weak var label2: UILabel!
	@IBOutlet weak var label3: UILabel!
	
	var detailManager:DetailManagerType=DetailManager<Worker>()
	
	override func viewDidLoad() {
		(detailManager as! DetailManager<Worker>).binder={ (obj:Observable<Worker>, disposeBag:DisposeBag) -> () in
			obj.map { $0.name }.bindTo(self.label1.rx_text).addDisposableTo(disposeBag)
			obj.map { "salary: €\($0.salary)" }.bindTo(self.label2.rx_text).addDisposableTo(disposeBag)
			obj.map { "dep: \($0.departmentId)" }.bindTo(self.label3.rx_text).addDisposableTo(disposeBag)
		}
		detailManager.viewDidLoad()
	}
}

class WorkerDetail2:UIViewController
{
	
}

class DepartmentDetail1:UIViewController
{
	
}





