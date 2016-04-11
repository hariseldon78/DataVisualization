#
# Be sure to run `pod lib lint DataVisualization.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "DataVisualization"
  s.version          = "0.1.0"
  s.summary          = "Tools to automate and facilitate data visualizations in table/collection views."

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!  
  s.description      = <<-DESC
							"Tools to automate and facilitate data visualizations in table/collection views."
                       DESC

  s.homepage         = "https://bitbucket.org/municipiumteam/datavisualization"
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license          = 'private'
  s.author           = { "Roberto Previdi" => "hariseldon78@gmail.com" }
  s.source           = { :git => 
"https://robertoprevidi@bitbucket.org/municipiumteam/datavisualization.git", :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.platform     = :ios, '8.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes/**/*'
  s.resource_bundles = {
    'DataVisualization' => ['Pod/Assets/*.png']
  }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  s.dependency 'Cartography'
  s.dependency 'RxDataSources', '~> 0.6'
  s.dependency 'RxSwift', '~> 2.2'
  s.dependency 'RxCocoa', '~> 2.2'

end
