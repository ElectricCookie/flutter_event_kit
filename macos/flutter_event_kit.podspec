#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_event_kit.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_event_kit'
  s.version          = '0.0.1'
  s.summary          = 'Type-safe access to the EventKit API on iOS and macOS.'
  s.description      = <<-DESC
Type-safe access to the EventKit API on iOS and macOS.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }

  s.source           = { :path => '.' }
  s.source_files = 'flutter_event_kit/Sources/flutter_event_kit/**/*.swift'
  s.resource_bundles = {'flutter_event_kit_privacy' => ['flutter_event_kit/Sources/flutter_event_kit/PrivacyInfo.xcprivacy']}

  s.dependency 'FlutterMacOS'

  s.platform = :osx, '10.15'
  s.frameworks = 'EventKit', 'CoreLocation'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
