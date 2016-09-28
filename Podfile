# platform :ios, '9.0'
post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['SWIFT_VERSION'] = '3.0'
        end
    end
end

target 'Instasplitter' do

 use_frameworks!

 pod 'IQKeyboardManagerSwift', '4.0.6'
 
end
