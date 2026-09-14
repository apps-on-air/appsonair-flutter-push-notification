#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint appsonair_flutter_push_notification.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'appsonair_flutter_push_notification'
  s.version          = '0.0.1-alpha'
  s.summary          = 'AppsOnAir push notifications for Flutter.'
  s.description      = <<-DESC
Flutter plugin wrapping the native AppsOnAir push notification SDKs (Android/iOS).
                       DESC
  s.homepage         = 'https://appsonair.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'AppsOnAir' => 'dev@appsonair.com' }
  s.source           = { :path => '.' }
  s.source_files = 'appsonair_flutter_push_notification/Sources/appsonair_flutter_push_notification/**/*'
  s.dependency 'Flutter'
  # Not resolvable from a public spec repo — AppsOnAir-AppPush's own podspec still
  # declares `s.source = { :path => '.' }` as of 0.0.2-alpha (not yet switched to a
  # git source), so CocoaPods can't fetch it from a bare version constraint either.
  # For CocoaPods-based consumers, add an override to your app's Podfile:
  #   pod 'AppsOnAir-AppPush', :git => 'https://github.com/apps-on-air/appsonair-ios-push-notification.git', :tag => '0.0.2-alpha'
  s.dependency 'AppsOnAir-AppPush', '0.0.2-alpha'
  s.platform = :ios, '15.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.9'

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'appsonair_flutter_push_notification_privacy' => ['appsonair_flutter_push_notification/Sources/appsonair_flutter_push_notification/PrivacyInfo.xcprivacy']}
end
