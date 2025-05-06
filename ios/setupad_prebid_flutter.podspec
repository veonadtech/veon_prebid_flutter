Pod::Spec.new do |s|
  s.name             = 'setupad_prebid_flutter'
  s.version          = '0.0.1'
  s.summary          = 'Prebid Mobile SDK integration for Flutter apps'
  s.description      = <<-DESC
A Flutter plugin that integrates Prebid Mobile SDK for both Android and iOS platforms.
                       DESC
  s.homepage         = 'https://veon.com/'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'VEON' => 'info@veon.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.dependency 'Google-Mobile-Ads-SDK', '12.3.0'
  s.dependency 'PrebidMobile', '3.0.0'
  s.static_framework = true
  s.platform = :ios, '10.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
  s.module_name = 'setupad_prebid_flutter'
end