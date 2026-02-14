Pod::Spec.new do |s|
  s.name             = 'no_screen_mirror'
  s.version          = '0.1.0'
  s.summary          = 'Flutter plugin to detect screen mirroring and external display connections.'
  s.description      = <<-DESC
Flutter plugin to detect screen mirroring (AirPlay, Miracast) and external display connections (HDMI, USB-C).
                       DESC
  s.homepage         = 'https://github.com/FlutterPlaza/no_screen_mirror'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'FlutterPlaza' => 'dev@flutterplaza.com' }
  s.source           = { :path => '.' }
  s.source_files = 'no_screen_mirror/Sources/no_screen_mirror/**/*.swift'
  s.dependency 'Flutter'
  s.platform = :ios, '12.0'

  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version    = "5.0"
  s.resource_bundles = {
    'no_screen_mirror_privacy' => ['no_screen_mirror/Sources/no_screen_mirror/PrivacyInfo.xcprivacy']
  }
end
