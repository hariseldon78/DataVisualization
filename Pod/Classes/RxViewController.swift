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
	var rx_raw_viewDidLoad:Observable<[AnyObject]> {return rx.sentMessage("viewDidLoad")}
	
	var rx_raw_viewWillAppear:Observable<[AnyObject]> {return rx.sentMessage("viewWillAppear:")}
	var rx_raw_viewDidAppear:Observable<[AnyObject]> {return rx.sentMessage("viewDidAppear:")}
	var rx_raw_viewWillDisappear:Observable<[AnyObject]> {return rx.sentMessage("viewWillDisappear:")}
	var rx_raw_viewDidDisappear:Observable<[AnyObject]> {return rx.sentMessage("viewDidDisappear:")}

//	var rx_raw_performSegueWithIdentifier:Observable<[AnyObject]> {return rx_sentMessage("performSegueWithIdentifier:sender:")}
	var rx_raw_prepareForSegue:Observable<[AnyObject]> {return rx.sentMessage("prepareForSegue:sender:")}
	
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
