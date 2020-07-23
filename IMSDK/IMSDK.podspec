#
# Be sure to run `pod lib lint IMSDK.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'IMSDK'
  s.version          = '2.6.0'
  s.summary          = 'Short IMSDK.'
  s.swift_version    = '5'
# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = 'IMSDK试用版'

  s.homepage         = 'https://gitlab.33.cn/Laughing_Wu/IMSDK/'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Laughing' => 'wwp@disanbo.com' }
  s.source           = { :git => 'https://gitlab.33.cn/Laughing_Wu/IMSDK.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '9.0'

  s.source_files = 'IMSDK/Classes/**/*', 'IMSDK/Classes/ThirdParty/*.{h}'
  s.vendored_frameworks = [
  'IMSDK/Classes/ThirdParty/TCWebCodesSDK.framework',
  'IMSDK/Classes/ThirdParty/Chatapi.framework']
  
  s.frameworks = 'SystemConfiguration', 'CoreTelephony', 'Security', 'ExternalAccessory'
  s.libraries = 'c++', 'z'
  
  s.resource_bundles = {
    'IMSDK' => ['IMSDK/Assets/*']
  }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'

  s.dependency 'AliyunOSSiOS'
  s.dependency 'pop'
  s.dependency 'YYText'
  s.dependency 'BHURLHelper'
  s.dependency 'YYWebImage'
  s.dependency 'YYImage/WebP'
  s.dependency 'Starscream'
  s.dependency 'Moya'
  s.dependency 'SwiftyJSON'
  s.dependency 'RxSwift'
  s.dependency 'RxCocoa'
  s.dependency 'RxDataSources'
  s.dependency 'SnapKit'
  s.dependency 'WCDB.swift'
  s.dependency 'MJRefresh'
  s.dependency 'MBProgressHUD'
  s.dependency 'DeviceKit'
  s.dependency 'TSVoiceConverter'
  s.dependency 'IDMPhotoBrowser'
  s.dependency 'TZImagePickerController'
  s.dependency 'BMPlayer'
  s.dependency 'FSPagerView'
  s.dependency 'Masonry'
  s.dependency 'YYModel'
  s.dependency 'AFNetworking'
  s.dependency 'RTRootNavigationController'
  s.dependency 'IQKeyboardManager'
  s.dependency 'KeychainAccess'
  s.dependency 'CryptoSwift'
  s.dependency 'lottie-ios'

  #手动修复Bug WCDB -> WCDBTokenize.swift line 165
  #https://github.com/Tencent/wcdb/issues/367
  
  #手动修复Bug WCDB -> final class TimedQueue<Key: Hashable> line 45, 56
  # list.remove(at: map[index].value)
  # 增加 if map[index].value < list.count && map[index].value > 0 {} 判断
end
