#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_device_info_plus.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_device_info_plus'
  s.version          = '0.0.5'
  s.summary          = 'Enhanced device information with detailed hardware specs and capabilities.'
  s.description      = <<-DESC
Enhanced device information with detailed hardware specs and capabilities. Get comprehensive device data including CPU, memory, storage, sensors, and system information.
                       DESC
  s.homepage         = 'https://github.com/Dhia-Bechattaoui/flutter_device_info_plus'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Flutter Team' => 'flutter-dev@googlegroups.com' }
  s.source           = { :path => '.' }
  s.source_files = 'flutter_device_info_plus/Sources/flutter_device_info_plus/**/*'
  s.dependency 'FlutterMacOS'
  s.platform = :osx, '10.14'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
