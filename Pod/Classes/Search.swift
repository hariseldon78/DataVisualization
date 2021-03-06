//
//  SearchUtils.swift
//  Pods
//
//  Created by Roberto Previdi on 13/04/16.
//
//

import Foundation
import RxSwift
import RxCocoa
import Cartography

public enum CancelButtonStyle {
	case neverShow
	case alwaysShow
	case showWhileEditing
	var allow:Bool { return self == .alwaysShow || self == .showWhileEditing }
}
public struct SearchControllerStyle {
	var position:SearchControllerPosition
	var showCancelButton:CancelButtonStyle
	var searchBarLayout:UISearchBarStyle
	var searchProgrammatically:Observable<String>?
	public typealias ConfigClosure=(UISearchBar,UISearchController)->Void
	var config:ConfigClosure?
	public init(position:SearchControllerPosition = .searchBarInTableHeader, showCancelButton:CancelButtonStyle = .showWhileEditing, searchBarLayout:UISearchBarStyle = .prominent, config:ConfigClosure? = nil,searchProgrammatically:Observable<String>?=nil) {
		self.position=position
		self.showCancelButton=showCancelButton
		self.searchBarLayout=searchBarLayout
		self.config=config
		self.searchProgrammatically=searchProgrammatically
	}
}

public enum SearchControllerPosition
{
	case searchBarInTableHeader
	case searchBarInNavigationBar
	case searchBarInView(view: UIView)
	case externalSearchBar(searchBar:UISearchBar)

}

// non dovrebbe essere pubblico
protocol Searchable:class,ControllerWithTableView,Disposer
{
	var searchController:CustomSearchController! {get set}
	func setupSearchController(_ style:SearchControllerStyle)
}
extension UIImage {
	class func imageWithColor(_ color: UIColor) -> UIImage {
		let rect = CGRect(x: 0.0, y: 0.0, width: 1.0, height: 1.0)
		UIGraphicsBeginImageContext(rect.size)
		let context = UIGraphicsGetCurrentContext()
		
		context?.setFillColor(color.cgColor)
		context?.fill(rect)
		
		let image = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		
		return image!
	}
}
extension UISearchBar {
	
	public var rx_cancel:ControlEvent<Void> {
		return ControlEvent(events: rx.delegate.sentMessage(#selector(UISearchBarDelegate.searchBarCancelButtonClicked(_:))).map{_ in _=0})
	}
	
	public var rx_cancelOrX: ControlEvent<Void> {
		let emptyText=rx.text.filter {$0==""}
		let events = Observable.of(rx.delegate.sentMessage(#selector(UISearchBarDelegate.searchBarCancelButtonClicked(_:))).map{_ in _=0},emptyText.map{_ in  _=0}).merge()
		return ControlEvent(events: events)
	}
	
	public var rx_textOrCancel: ControlProperty<String> {
		
		func bindingErrorToInterface(_ error: Error) {
			let error = "Binding error to UI: \(error)"
			DataVisualization.nonFatalError(error)
		}
		
		let cancelMeansNoText=rx_cancelOrX.map{""}
		let txt:Observable<String>=rx.text.asObservable().filter{$0 != nil}.map {$0!}
		
		let source:Observable<String>=Observable.of(
			txt,
			cancelMeansNoText)
			.merge()
		return ControlProperty(values: source, valueSink: AnyObserver { [weak self] event in
			switch event {
			case .next(let value):
				self?.text = value
			case .error(let error):
				bindingErrorToInterface(error)
			case .completed:
				break
			}
		})
	}
}
final class BugFixedSearchBar:UISearchBar {
	override func setShowsCancelButton(_ showsCancelButton: Bool, animated: Bool) {
		// uisearchcontroller will insist to reset this flag
			super.setShowsCancelButton(showsCancelButton && cancelButtonStyle.allow, animated: animated)
	}
	var cancelButtonStyle=CancelButtonStyle.showWhileEditing
}
public class CustomSearchController: UISearchController {
	
	lazy var _searchBar: UISearchBar = {
		[unowned self] in
		let customSearchBar = BugFixedSearchBar(frame: CGRect.zero)
		return customSearchBar
		}()
	var externalSearchBar:UISearchBar?
	let 🗑=DisposeBag()
	override public var searchBar: UISearchBar {
		get {
			return externalSearchBar ?? _searchBar
		}
	}
	var searchProgrammatically=Observable.just("")
	override init(searchResultsController: UIViewController?) {
		super.init(searchResultsController: searchResultsController)
	}
	override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
		super.init(nibName:nibNameOrNil,bundle:nibBundleOrNil)
	}
	required public init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
	
	/// call this only once, after the searchBar has been assigned
	func showCancelButton(showIt:CancelButtonStyle) {
		(searchBar as? BugFixedSearchBar)?.cancelButtonStyle=showIt
		searchBar.showsCancelButton=(showIt == .alwaysShow)
		if showIt == .showWhileEditing {
			searchBar.rx.textDidBeginEditing.subscribe(onNext: {
				self.searchBar.showsCancelButton=true
			}).addDisposableTo(🗑)
			searchBar.rx.textDidEndEditing.subscribe(onNext: {
				self.searchBar.showsCancelButton=false
			}).addDisposableTo(🗑)
		}
	}
}
extension Searchable
{
	
	/// To be called in viewDidLoad
	func setupSearchController(_ style:SearchControllerStyle)
	{
		searchController=({
			
			let sc=CustomSearchController(searchResultsController: nil)
			sc.hidesNavigationBarDuringPresentation=false
			sc.dimsBackgroundDuringPresentation=false
			switch style.position{
			case .searchBarInTableHeader,.searchBarInView(_):
				sc.searchBar.backgroundColor=UIColor(white: 1.0, alpha: 0.95)
				sc.searchBar.sizeToFit()
			case .searchBarInNavigationBar:
				sc.searchBar.sizeToFit()
			case .externalSearchBar(let searchBar):
				sc.externalSearchBar=searchBar
				
			}
			sc.searchBar.searchBarStyle=style.searchBarLayout
			sc.showCancelButton(showIt: style.showCancelButton)
			if let sp=style.searchProgrammatically {
				sc.searchProgrammatically=sp
				sp.asObservable().shareReplay(1).subscribe(onNext:{ [weak sc] in
					sc?.searchBar.text=$0
				})
			}
			return sc
			
			}())
		let searchBar=searchController.searchBar
		searchBar.rx_cancel.subscribe(onNext:{ _ in
			searchBar.text=""
			searchBar.resignFirstResponder()
		}).addDisposableTo(self.🗑)
		searchBar.returnKeyType=UIReturnKeyType.search
		

		switch style.position{
		case .searchBarInTableHeader:
			self.tableView.tableHeaderView=self.searchController.searchBar
		case .searchBarInView(let view):
			view.addSubview(self.searchController.searchBar)
		case .externalSearchBar(let searchBar):
			_=0
		case .searchBarInNavigationBar:
			var buttons=self.vc.navigationItem.rightBarButtonItems ?? [UIBarButtonItem]()
			let searchButton=UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.search, target: nil, action: nil)
			searchButton.rx.tap.subscribe(onNext:{
				if self.vc.navigationItem.titleView==nil
				{
					guard let navBar=self.vc.navigationController?.navigationBar else {return}
					let buttonFrames = navBar.subviews.filter({
						$0 is UIControl
					}).sorted(by: {
						$0.frame.origin.x < $1.frame.origin.x
					}).map({
						$0.convert($0.bounds, to:nil)
					})
					let btnFrame=buttonFrames[buttonFrames.count-1]
					let containerFrame=CGRect(x:0, y:0, width:navBar.frame.size.width, height:btnFrame.size.height)
					let superview=UIView(frame:containerFrame)
					superview.backgroundColor=UIColor.clear
					superview.clipsToBounds=true
					
					//					searchBar.backgroundColor=UIColor.redColor()
					//					searchBar.barTintColor=UIColor.whiteColor()
					let searchBar=self.searchController.searchBar
					var textFieldInsideSearchBar = searchBar.value(forKey: "searchField") as? UITextField
					textFieldInsideSearchBar?.textColor = UIColor.black
					searchBar.tintColor=UIColor.black // colora il cursore e testo cancel
					
					searchBar.backgroundImage=UIImage.imageWithColor(UIColor.clear)
					//					searchBar.showsCancelButton=false
					self.vc.navigationItem.titleView=superview
					superview.addSubview(searchBar)
					// deve stare alla stessa altezza dei pulsanti
					
					//					print(NSStringFromCGRect(btnFrame))
					constrain(searchBar){
						//						$0.top 		== $0.superview!.top+btnFrame.origin.y
						//						$0.height 	== btnFrame.size.height
						$0.top 		== $0.superview!.top
						$0.bottom 	== $0.superview!.bottom
						$0.leading	== $0.superview!.leading
						$0.trailing	== $0.superview!.trailing
					}
					
				}
				else
				{
					self.searchController.searchBar.text=""
					self.vc.navigationItem.titleView=nil
				}
			}).addDisposableTo(self.🗑)
			buttons.append(searchButton)
			self.vc.navigationItem.rightBarButtonItems=buttons
			self.vc.definesPresentationContext=true
		}
		
		if let config=style.config {
			OperationQueue.main.addOperation {
				config(self.searchController.searchBar,self.searchController)
			}
		}

		vc.rx_viewWillDisappear.subscribe(onNext:{ _ in
			switch style{
			default:
				self.searchController.isActive=false
				self.searchController.searchBar.endEditing(true)
				if self.isSearching
				{
					// senno si comportava male...
					self.searchController.searchBar.removeFromSuperview()
				}
			}
		}).addDisposableTo(🗑)
	}
	
	var isSearching:Bool {
		return (searchController.searchBar.text ?? "") != ""
	}
}
