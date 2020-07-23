workspace 'Chat33.xcworkspace'
xcodeproj 'Chat33.xcodeproj'

source 'https://github.com/CocoaPods/Specs.git'
source 'https://github.com/aliyun/aliyun-specs.git'
source 'https://gitlab.33.cn/CloudMinerIOS/FZMCMSpecs.git'

platform :ios, '9.0'

targetsArray = ['Chat33', 'Chat33Test']
targetsArray.each do |t|
  target t do
    use_frameworks!
    pod 'Masonry'
    pod 'CrabCrashReporter', :inhibit_warnings => true
    pod 'UMCCommon'
    pod 'UMCPush'
    pod 'UMCSecurityPlugins'
    pod 'WechatOpenSDK', '1.8.4', :inhibit_warnings => true
    pod 'AFNetworking'
    pod 'MBProgressHUD'
    pod 'YYModel'
    pod 'XHLaunchAd'
    pod 'IMSDK', :path => './IMSDK/'
    
    
  end
end
