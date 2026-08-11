#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint rokwire_plugin.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'rokwire_plugin'
  s.version          = '1.13.5'
  s.summary          = 'Rokwire Flutter plugin'
  s.description      = <<-DESC
Rokwire Flutter plugin
                       DESC
  s.homepage         = 'https://rokwire.org'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'University of Illinois at Urbana-Champaign' => 'rokwire@illinois.edu' }
  s.source           = { :path => '.' }
  s.source_files = 'rokwire_plugin/Sources/rokwire_plugin/**/*.{h,m}'
  s.public_header_files = 'rokwire_plugin/Sources/rokwire_plugin/include/**/*.h'
  s.dependency 'Flutter'
  s.platform = :ios, '12.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
end
