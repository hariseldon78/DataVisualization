## DataVisualization

This framework allows you to link **easyly** your tableviews and collection views to your datasources, taking away from you the pain of delegates. It also separates clearly the view layer from the data layer, helping to keep your code clean. It handle sectioned tables, drag to refresh, automatic refresh (via rxswift observables), simple and complex detail segue or actions on select, in a short while the *peek and pop* behavior. All with few code lines.

This library works best in tandem with https://github.com/hariseldon78/RestEngine.
## Screenshots

<img src="https://raw.githubusercontent.com/hariseldon78/DataVisualization/master/DataVisualization/dv-screenshot-funky.png" width="200"> <img src="https://raw.githubusercontent.com/hariseldon78/DataVisualization/master/DataVisualization/dv-screenshot-sec.png" width="200"> <img src="https://raw.githubusercontent.com/hariseldon78/DataVisualization/master/DataVisualization/dv-screenshot-sea-sec.png" width="200"> <img src="https://raw.githubusercontent.com/hariseldon78/DataVisualization/master/DataVisualization/dv-screenshot-static.png" width="200">

## Usage

Here is an example of the conciseness you can achiave with this library:
```swift
import UIKit
import RxSwift
import DataVisualization
import APIUtils // this is the RestEngine library, in the process of changing name

class UsersViewController: UIViewController
{
	@IBOutlet weak var tableView: UITableView!

	override func viewDidLoad() {
		super.viewDidLoad()
		
		let tvManager=AutoSingleLevelTableViewManager(viewModel:User.defaultViewModel(),dataExtractor:ApiExtractor<User>(progress:progress))
		tvManager.setupTableView(tableView,vc:self)
		tvManager.setupOnSelect(
			.allTheSame(
				style:.detail,
				behaviour:.segue(name: "user", presentation: .push)))
	}
}
```
In this example the User class must implement the *WithApi* protocol, so the library can use its *api()* method to retrieve the list of Users.


## Installation

DataVisualization is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "DataVisualization", :git => 'https://github.com/hariseldon78/DataVisualization.git'
```

If for some reason CocoaPods is not working you can import the project directly into your workspace: import the project Pod/Classes/DataVisualization/DataVisualization.xcodeproj, and provide this dependencies:

```
github "ReactiveX/RxSwift"
github "ReactiveX/RxCocoa"
github "hariseldon78/RxDataSources" //or the original one, i forked some time ago for a little issue
github "robb/Cartography"
```

## Example project

To run the example project, clone the repo, and run `pod install` from the Example directory first.

```swift
// Swift

import UIKit
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
		tvManager.setupOnSelect(.Detail(segue:"detail"))
    }
}
```
## Author

DataVisualization is written by 

Roberto Previdi <hariseldon78@gmail.com>
for 
Municipium s.r.l., Verona, Italy

## License

DataVisualization is available under the MIT license. See the LICENSE file for more info.

**Copyright (c) 2015 Municipium s.r.l.**



