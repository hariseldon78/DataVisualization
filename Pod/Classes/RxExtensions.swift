//
//  RxViewController.swift
//  Pods
//
//  Created by Roberto Previdi on 02/01/16.
//
//

import Foundation
import RxSwift
import RxCocoa

extension Array {
	subscript (safe index: Int) -> Element? {
		return indices ~= index ? self[index] : nil
	}
}

extension UIViewController
{
	var rx_raw_viewDidLoad:Observable<[Any]> {return rx.sentMessage("viewDidLoad")}
	
	var rx_raw_viewWillAppear:Observable<[Any]> {return rx.sentMessage("viewWillAppear:")}
	var rx_raw_viewDidAppear:Observable<[Any]> {return rx.sentMessage("viewDidAppear:")}
	var rx_raw_viewWillDisappear:Observable<[Any]> {return rx.sentMessage("viewWillDisappear:")}
	var rx_raw_viewDidDisappear:Observable<[Any]> {return rx.sentMessage("viewDidDisappear:")}

	var rx_raw_prepareForSegue:Observable<[Any]> {return rx.sentMessage("prepareForSegue:sender:")}
	
	var rx_viewWillAppear:Observable<Bool> {
		return rx_raw_viewWillAppear.map{ (args)in
			return args[0] as! Bool
		}
	}
	var rx_viewDidAppear:Observable<Bool> {
		return rx_raw_viewDidAppear.map{ (args)in
			return args[0] as! Bool
		}
	}
	var rx_viewWillDisappear:Observable<Bool> {
		return rx_raw_viewWillDisappear.map{ (args)in
			return args[0] as! Bool
		}
	}
	var rx_viewDidDisappear:Observable<Bool> {
		return rx_raw_viewDidDisappear.map{ (args)in
			return args[0] as! Bool
		}
	}
	
	var rx_viewDidLoad:Observable<Void> {
		return rx_raw_viewDidLoad.map{ (_) -> Void in
			_=0
		}
	}
	
	var rx_prepareForSegue:Observable<(segue:UIStoryboardSegue,sender:AnyObject?)> {
		return rx_raw_prepareForSegue.map{ (args) in
			return (segue:args[0] as! UIStoryboardSegue,sender:args[safe:1] as AnyObject?)
		}
	}
}

public class Refresher<T>{
	public init(source:@escaping ()->Observable<T>) {
		self.source=source
		sourceContainer=Variable(Observable<T>.never())
		output=sourceContainer.asObservable().switchLatest()
		refreshTrigger.subscribe(onNext: { _ in
			self.sourceContainer.value=source()
		}).addDisposableTo(🗑)
	}
	public func refresh() {
		refreshTrigger.onNext()
	}
	public let output:Observable<T>
	
	let source:()->Observable<T>
	let 🗑=DisposeBag()
	let refreshTrigger=PublishSubject<Void>() // could be public if needed
	let sourceContainer:Variable<Observable<T>>
	
}
