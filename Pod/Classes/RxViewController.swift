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

extension UISearchBar
{
	public var rx_cancel: ControlEvent<Void> {
		let source=rx_delegate.observe("searchBarCancelButtonClicked:").map{_ in _=0}
		return ControlEvent(events: source)
	}
	
	public var rx_textOrCancel: ControlProperty<String> {
		
		func bindingErrorToInterface(error: ErrorType) {
			let error = "Binding error to UI: \(error)"
			#if DEBUG
    			rxFatalError(error)
			#else
    			print(error)
			#endif
		}
		
		let cancelMeansNoText=rx_cancel.map{""}
		let source:Observable<String>=Observable.of(
				rx_text.asObservable(),
				cancelMeansNoText)
			.merge()
		return ControlProperty(values: source, valueSink: AnyObserver { [weak self] event in
			switch event {
			case .Next(let value):
				self?.text = value
			case .Error(let error):
				bindingErrorToInterface(error)
			case .Completed:
				break
			}
		})
	}
}
extension UIViewController
{
	var rx_raw_viewDidLoad:Observable<[AnyObject]> {return rx_sentMessage("viewDidLoad")}
	
	var rx_raw_viewWillAppear:Observable<[AnyObject]> {return rx_sentMessage("viewWillAppear:")}
	var rx_raw_viewDidAppear:Observable<[AnyObject]> {return rx_sentMessage("viewDidAppear:")}
	var rx_raw_viewWillDisappear:Observable<[AnyObject]> {return rx_sentMessage("viewWillDisappear:")}
	var rx_raw_viewDidDisappear:Observable<[AnyObject]> {return rx_sentMessage("viewDidDisappear:")}

//	var rx_raw_performSegueWithIdentifier:Observable<[AnyObject]> {return rx_sentMessage("performSegueWithIdentifier:sender:")}
	var rx_raw_prepareForSegue:Observable<[AnyObject]> {return rx_sentMessage("prepareForSegue:sender:")}
	
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
