Pod::Spec.new do |s|
  s.name             = 'EventTracing-iOS-LogViewer'
  s.version          = '1.0.1'
  s.summary          = 'EventTracing-iOS-LogViewer.'

  s.description      = <<-DESC
    EventTracing-iOS-LogViewer
                       DESC

  s.homepage         = 'https://github.com/EventTracing/EventTracing-iOS-LogViewer'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'eventtracing' => 'eventtracing@service.netease.com' }
  s.source           = { :git => 'https://github.com/EventTracing/EventTracing-iOS-LogViewer.git', :tag => s.version.to_s }

  s.ios.deployment_target = '11.0'
  s.module_name = 'EventTracingLogViewer'

  s.source_files = [
    'EventTracing-iOS-LogViewer/Classes/**/*.{h,m,mm}'
  ]

  s.public_header_files = [
  'EventTracing-iOS-LogViewer/Classes/*.h',
  ]

  s.dependency 'SocketRocket', '~> 0.6.0'
end
