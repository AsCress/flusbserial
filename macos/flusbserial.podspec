#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flusbserial.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'flusbserial'
  s.version          = '0.3.3'
  s.summary          = 'A cross-platform USB serial plugin for Flutter desktop apps (Windows, Linux, macOS).'
  s.description      = <<-DESC
A cross-platform USB serial plugin for Flutter desktop apps (Windows, Linux, macOS).
                       DESC
  s.homepage         = 'https://github.com/AsCress/flusbserial'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Anashuman Singh' => 'ascress7@gmail.com' }

  s.source           = { :path => '.' }
  s.source_files = 'flusbserial/Sources/flusbserial/**/*.swift'

  # If your plugin requires a privacy manifest, for example if it collects user
  # data, update the PrivacyInfo.xcprivacy file to describe your plugin's
  # privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'flusbserial_privacy' => ['Resources/PrivacyInfo.xcprivacy']}

  s.dependency 'FlutterMacOS'

  s.platform = :osx, '10.15'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
