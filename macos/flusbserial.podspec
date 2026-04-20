#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flusbserial.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'flusbserial'
  s.version          = '0.5.0'
  s.summary          = 'A cross-platform USB serial plugin for Flutter desktop apps (Windows, Linux, macOS).'
  s.description      = <<-DESC
A cross-platform USB serial plugin for Flutter desktop apps (Windows, Linux, macOS).
                       DESC
  s.homepage         = 'https://github.com/AsCress/flusbserial'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Anashuman Singh' => 'anashumansingh@ascress.com' }

  s.source           = { :path => '.' }
  s.source_files = 'flusbserial/Sources/flusbserial/**/*.swift'

  # If your plugin requires a privacy manifest, for example if it collects user
  # data, update the PrivacyInfo.xcprivacy file to describe your plugin's
  # privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'flusbserial_privacy' => ['Resources/PrivacyInfo.xcprivacy']}

  s.dependency 'FlutterMacOS'

  s.platform = :osx, '10.15'
  s.swift_version = '5.0'

  libusb_prefix = `brew --prefix libusb 2>/dev/null`.strip
  libusb_prefix = '/usr/local' if libusb_prefix.empty?

  s.pod_target_xcconfig = {
    'DEFINES_MODULE'      => 'YES',
    'LIBRARY_SEARCH_PATHS' => "#{libusb_prefix}/lib",
    'HEADER_SEARCH_PATHS'  => "#{libusb_prefix}/include",
    'OTHER_LDFLAGS'        => '-lusb-1.0'
  }
end
