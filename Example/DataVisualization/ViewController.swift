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
	var tvManager=AutoSearchableSingleLevelTableViewManager (viewModel: Worker.defaultViewModel(), filteringClosure: { (d:Worker, s:String) -> Bool in
		return d.name.uppercaseString.containsString(s.uppercaseString)
	})
	override func viewDidLoad() {
		super.viewDidLoad()
		tvManager.setupTableView(tableView,vc:self)
		tvManager.setupOnSelect(.Detail(segue:"detail"))
	}
}


class StaticViewController:UIViewController
{
	@IBOutlet weak var tableView: UITableView!
	@IBOutlet var staticHeaderView: UIView!
	var tvManager=AutoSearchableSingleLevelTableViewManager (viewModel: Worker.defaultViewModel(), filteringClosure: { (d:Worker, s:String) -> Bool in
		return d.name.uppercaseString.containsString(s.uppercaseString)
	})
	
	override func viewDidLoad() {
		super.viewDidLoad()
		tvManager.setupTableView(tableView,vc:self)
		tvManager.setupOnSelect(.Detail(segue:"detail"))
	}
	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)
		tableView.tableHeaderView=staticHeaderView
		
	}
}

class NoStoryboardViewController:UIViewController
{
	@IBOutlet weak var tableView: UITableView!
	var tvManager=AutoSearchableSingleLevelTableViewManager (viewModel: Worker.defaultViewModel(), filteringClosure: { (d:Worker, s:String) -> Bool in
		return d.name.uppercaseString.containsString(s.uppercaseString)
	})
	init(){
		super.init(nibName:"NibVC",bundle:NSBundle.mainBundle())
	}

	required init?(coder aDecoder: NSCoder) {
		super.init(coder:aDecoder)
	}
	override func viewDidLoad() {
		super.viewDidLoad()
		tvManager.setupTableView(tableView,vc:self)
	}
}

class PlainNoDetViewController:UIViewController
{
	
	@IBOutlet weak var tableView: UITableView!
	var tvManager=AutoSingleLevelTableViewManager(viewModel: Worker.defaultViewModel())
	override func viewDidLoad() {
		super.viewDidLoad()
		tvManager.setupTableView(tableView,vc:self)
		tvManager.setupOnSelect(.Action(action: { (d:Worker) -> () in
			dump(d)
			let vc=NoStoryboardViewController()
			self.presentViewController(vc, animated: true, completion: nil)
		}))
	}
}
class FunkyViewController:UIViewController {
	@IBOutlet weak var tableView: UITableView!
	typealias DataViewModel=ConcreteViewModel<Worker,FunkyCell>
	let tvManager=AutoSingleLevelTableViewManager(viewModel: DataViewModel(cellName: "FunkyCell") {
		(index:Int, item, cell:DataViewModel.Cell) -> Void in
		cell.title.text=item.name
		cell.subtitle.text="salary: €\(item.salary)"
		})
	override func viewDidLoad() {
		super.viewDidLoad()
		tvManager.setupTableView(tableView,vc:self)
		tvManager.setupOnSelect(.Detail(segue:"detail"))
	}

}

class PlainSectionedViewController:UIViewController {
	@IBOutlet weak var tableView: UITableView!
	let tvManager=AutoSectionedTableViewManager<Worker,Worker.DefaultViewModel,Department,Department.DefaultSectionViewModel,WorkerSectioner>(
		elementViewModel:Worker.defaultViewModel(),sectionViewModel:Department.defaultSectionViewModel(),sectioner:WorkerSectioner())
	override func viewDidLoad() {
		super.viewDidLoad()
		tvManager.setupTableView(tableView,vc:self)
		tvManager.setupDataOnSelect(.SectionDetail(segue:"departmentDetail"))
		tvManager.setupSectionOnSelect(.Detail(segue:"departmentDetail"))
	}
}


class SearchSectionedViewController:UIViewController {
	var disposeBag=DisposeBag()
	@IBOutlet weak var tableView: UITableView!
	let tvManager=AutoSearchableSectionedTableViewManager(
		elementViewModel: Worker.defaultViewModel(),
		sectionViewModel: Department.defaultSectionViewModel(),
		sectioner: CollapsableSectioner(original:WorkerSectioner()),
		dataFilteringClosure: { (d, s) -> Bool in
			return d.name.uppercaseString.containsString(s.uppercaseString)
		},
		sectionFilteringClosure: { (d, s) -> Bool in
			return d.name.uppercaseString.containsString(s.uppercaseString)
	})
	
	
	override func viewDidLoad() {
		super.viewDidLoad()
		tvManager.setupTableView(tableView,vc:self)
		tvManager.setupDataOnSelect(.SectionDetail(segue:"departmentDetail"))
		tvManager.setupSectionOnSelect(OnSelectBehaviour<Department>.Action(action: { (d) in
			// TODO: creare una behaviouraction ad hoc, o almeno un methodo in CollapsableSectionerProtocol
			if let s=self.tvManager.sectioner.selectedSection.value where s==d
			{
				self.tvManager.sectioner.selectedSection.value=nil
			}
			else
			{
				self.tvManager.sectioner.selectedSection.value=d
			}
		}))
		tvManager.search.asObservable()
			.map{!$0.isEmpty}
			.distinctUntilChanged()
			.subscribeNext {
				print("showAll=\($0)")
				self.tvManager.sectioner.showAll.value=$0
		}.addDisposableTo(disposeBag)
		
		
	}
}

class SearchSectionedFunkyViewController:UIViewController {
	var disposeBag=DisposeBag()
	@IBOutlet weak var tableView: UITableView!
	
	typealias DataViewModel=ConcreteViewModel<Worker,FunkyCell>

	let tvManager=AutoSearchableSectionedTableViewManager(
		elementViewModel: DataViewModel(cellName: "FunkyCell") {
			(index:Int, item, cell:DataViewModel.Cell) -> Void in
			cell.title.text=item.name
			cell.subtitle.text="salary: €\(item.salary)"
		},
		sectionViewModel: Department.defaultSectionViewModel(),
		sectioner: CollapsableSectioner(original:WorkerSectioner()),
		dataFilteringClosure: { (d, s) -> Bool in
			return d.name.uppercaseString.containsString(s.uppercaseString)
		},
		sectionFilteringClosure: { (d, s) -> Bool in
			return d.name.uppercaseString.containsString(s.uppercaseString)
	})
	
	
	override func viewDidLoad() {
		super.viewDidLoad()
		tvManager.setupTableView(tableView,vc:self)
		tvManager.setupDataOnSelect(.SectionDetail(segue:"departmentDetail"))
		tvManager.setupSectionOnSelect(OnSelectBehaviour<Department>.Action(action: { (d) in
			// TODO: creare una behaviouraction ad hoc, o almeno un methodo in CollapsableSectionerProtocol
			if let s=self.tvManager.sectioner.selectedSection.value where s==d
			{
				self.tvManager.sectioner.selectedSection.value=nil
			}
			else
			{
				self.tvManager.sectioner.selectedSection.value=d
			}
		}))
		tvManager.search.asObservable()
			.map{!$0.isEmpty}
			.distinctUntilChanged()
			.subscribeNext {
				print("showAll=\($0)")
				self.tvManager.sectioner.showAll.value=$0
			}.addDisposableTo(disposeBag)
		
		
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





