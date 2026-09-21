#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint appsonair_flutter_apppush.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'appsonair_flutter_apppush'
  s.version          = '0.0.4-alpha'
  s.summary          = 'AppsOnAir push notifications for Flutter.'
  s.description      = <<-DESC
Flutter plugin wrapping the native AppsOnAir push notification SDKs (Android/iOS).
                       DESC
  s.homepage         = 'https://appsonair.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'AppsOnAir' => 'dev@appsonair.com' }
  s.source           = { :path => '.' }
  s.source_files = 'appsonair_flutter_apppush/Sources/appsonair_flutter_apppush/**/*'
  s.dependency 'Flutter'
  s.dependency 'AppsOnAir-AppPush', '0.0.4-alpha'
  s.platform = :ios, '15.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.9'

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'appsonair_flutter_apppush_privacy' => ['appsonair_flutter_apppush/Sources/appsonair_flutter_apppush/PrivacyInfo.xcprivacy']}
end
