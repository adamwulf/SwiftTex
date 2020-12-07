# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

target 'Formulas' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!
  inhibit_all_warnings!
  platform :macos, '10.9'

  # Pods for Formulas
  pod "iosMath"
end

target 'SwiftTex' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!
  inhibit_all_warnings!
  platform :ios

  # Pods for SwiftTex

  target 'SwiftTexTests' do
    # Pods for testing
  end

end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['MACOSX_DEPLOYMENT_TARGET'] = '10.9'
    end
  end
end
