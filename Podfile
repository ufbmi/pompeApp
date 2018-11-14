# Uncomment this line to define a global platform for your project
# platform :ios, '8.0'
# Uncomment this line if you're using Swift
platform :ios, '10.0'
use_frameworks!
source 'https://github.com/CocoaPods/Specs.git'

target 'diaFit' do

pod 'SwiftyJSON', :git => 'https://github.com/SwiftyJSON/SwiftyJSON.git'
pod 'AFNetworking', '~> 2.5'
pod 'OAuthSwift', '~> 1.2.0'
pod 'SwiftCharts', '~> 0.6.3'
pod 'AWSCore', '~> 2.4.7’
pod 'AWSLambda'
pod 'AWSSNS'
pod 'DLRadioButton', '~> 1.4'
pod 'ActionSheetPicker-3.0', '~> 2.2.0'
pod 'CorePlot', '~> 2.1'

post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['SWIFT_VERSION'] = '4.2'
        end
    end
end

end

