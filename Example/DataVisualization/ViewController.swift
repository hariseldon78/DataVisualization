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
import DataVisualization

class PlainViewController:UIViewController
{
	@IBOutlet weak var tableView: UITableView!
	var tvManager=AutoSearchableSingleLevelTableViewManager<Worker> (filteringClosure: { (d:Worker, s:String) -> Bool in
		return d.name.uppercaseString.containsString(s.uppercaseString)
	})
	override func viewDidLoad() {
		super.viewDidLoad()
		tvManager.setupTableView(tableView,vc:self)
		tvManager.setupDetail("detail")
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
		tvManager.setupDetail("detail")
	}

}

class PlainSectionedViewController:UIViewController {
	@IBOutlet weak var tableView: UITableView!
	let tvManager=AutoSectionedTableViewManager<Worker,Department,WorkerSectioner>()
	override func viewDidLoad() {
		super.viewDidLoad()
		tvManager.setupTableView(tableView,vc:self)
		tvManager.setupDataDetail("workerDetail")
		tvManager.setupSectionDetail("departmentDetail")
	}
}

class WorkerDetail1:UIViewController,DetailView
{
	@IBOutlet weak var label1: UILabel!
	@IBOutlet weak var label2: UILabel!
	@IBOutlet weak var label3: UILabel!
	
	var detailManager:DetailManagerType=DetailManager<Worker>()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		(detailManager as! DetailManager<Worker>).binder={ (obj:Observable<Worker>, disposeBag:DisposeBag) -> () in
			obj.map { $0.name }.bindTo(self.label1.rx_text).addDisposableTo(disposeBag)
			obj.map { "salary: €\($0.salary)" }.bindTo(self.label2.rx_text).addDisposableTo(disposeBag)
			obj.map { "dep: \($0.departmentId)" }.bindTo(self.label3.rx_text).addDisposableTo(disposeBag)
		}
		detailManager.viewDidLoad()
	}
}

class WorkerDetail2:UIViewController,DetailView
{
	@IBOutlet weak var label1: UILabel!
	@IBOutlet weak var slider1: UISlider!
	
	var detailManager:DetailManagerType=DetailManager<Worker>()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		(detailManager as! DetailManager<Worker>).binder={ (obj:Observable<Worker>, disposeBag:DisposeBag) -> () in
			obj.map { $0.name }.bindTo(self.label1.rx_text).addDisposableTo(disposeBag)
			obj.map { Float($0.salary) }.bindTo(self.slider1.rx_value).addDisposableTo(disposeBag)
		}
		detailManager.viewDidLoad()

	}
	
}

class DepartmentDetail1:UIViewController,DetailView
{
	@IBOutlet weak var label1: UILabel!
	@IBOutlet weak var label2: UILabel!
	
	var detailManager:DetailManagerType=DetailManager<Department>()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		(detailManager as! DetailManager<Department>).binder={ (obj:Observable<Department>, disposeBag:DisposeBag) -> () in
			obj.map { $0.name }.bindTo(self.label1.rx_text).addDisposableTo(disposeBag)
			obj.map { "\($0.id)" }.bindTo(self.label2.rx_text).addDisposableTo(disposeBag)
		}
		detailManager.viewDidLoad()
	}
}





