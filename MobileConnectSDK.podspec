Pod::Spec.new do |s|

  s.name         = "MobileConnectSDK"
  s.version      = "0.0.1"
  s.summary      = "MobileConnectSDK is the framework for using Mobile Connect services on the iOS platform."

  s.description  = "MobileConnectSDK is providing authorization through mobile operators, allowing a easy and secure authentication."

  s.homepage     = "http://developer.mobileconnect.io"

  s.license      = { :type => "MIT", :file => "Metadata/LICENSE" }

  s.author             = { "Dan Andoni" => "dan.andoni@bjss.com" }

  s.platform     = :ios
  s.platform     = :ios, "8.0"

  s.source       = { :git => "https://github.com/Dan-Andoni-BJSS/GSMA-iOS-SDK.git", :tag => "#{s.version}" }

  s.source_files  = "Sources", "Sources/**/*.{h,m}"
  # s.exclude_files = "Classes/Exclude"

  # s.public_header_files = "Classes/**/*.h"

  s.resources = "**/*.{png,jpeg,jpg,storyboard,xib}"

  s.framework  = "UIKit"
  s.dependency 'AFNetworking', '~> 3.1.0'
  s.dependency 'JSONModel', '~> 1.2.0'

end
