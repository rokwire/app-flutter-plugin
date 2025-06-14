#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint rokwire_plugin.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'rokwire_plugin'
  s.version          = '1.11.0'
  s.summary          = 'Rokwire Flutter plugin'
  s.description      = <<-DESC
Rokwire Flutter plugin
                       DESC
  s.homepage         = 'https://rokwire.org'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'University of Illinois at Urbana-Champaign' => 'rokwire@illinois.edu' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'
  s.platform = :ios, '9.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
end
