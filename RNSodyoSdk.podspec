require 'json'

package = JSON.parse(File.read(File.join(__dir__, 'package.json')))


Pod::Spec.new do |s|
  s.name         = "RNSodyoSdk"
  s.version        = package['version']
  s.summary        = package['description']
  s.description    = package['description']
  s.license        = package['license']
  s.author         = package['author']
  s.homepage       = package['homepage']
  s.platform     = :ios, "11.0"
  s.source       = { :git => "https://github.com/sodyo-ltd/SodyoSDKPod", :commit => "506be9c" }
  s.source_files  = "ios/**/*.{h,m}"
  s.requires_arc = true

  s.dependency "React"
  s.dependency "SodyoSDK", "3.60.03"
end

