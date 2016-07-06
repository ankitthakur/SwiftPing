Pod::Spec.new do |s|
  s.name             = "SwiftPing"
  s.summary          = "A short description of SwiftPing."
  s.version          = "0.1.0"
  s.homepage         = "https://github.com/ankitthakur/SwiftPing"
  s.license          = 'MIT'
  s.author           = { "Ankit Thakur" => "ankitthakur85@icloud.com" }
  s.source           = {
    :git => "https://github.com/ankitthakur/SwiftPing.git",
    :tag => s.version.to_s
  }
  s.social_media_url = 'https://twitter.com/ankitthakur85'

  s.ios.deployment_target = '8.0'
  s.osx.deployment_target = '10.9'
  s.tvos.deployment_target = '9.2'

  s.requires_arc = true
  s.ios.source_files = 'Sources/{iOS,Shared}/**/*'
  s.tvos.source_files = 'Sources/{iOS,Shared}/**/*'
  s.osx.source_files = 'Sources/{Mac,Shared}/**/*'

  # s.ios.frameworks = 'UIKit', 'Foundation'
  # s.osx.frameworks = 'Cocoa', 'Foundation'

  # s.dependency 'Whisper', '~> 1.0'
end
