Pod::Spec.new do |spec|
  spec.name         = "IRShareManager"
  spec.version      = "0.1.0"
  spec.summary      = "A powerful share extension of iOS."
  spec.description  = "A powerful share extension of iOS."
  spec.homepage     = "https://github.com/irons163/IRShareManager.git"
  spec.license      = "MIT"
  spec.author       = "irons163"
  spec.platform     = :ios, "9.0"
  spec.source       = { :git => "https://github.com/irons163/IRPasscode.git", :tag => spec.version.to_s }
  spec.source_files  = "IRShareManager/**/*.{h,m}"
 
  spec.app_spec 'ToastCatalog' do |app_spec|
    app_spec.info_plist = {
      'CFBundleIdentifier' => 'com.bakery.ToastCatalog',
      'UISupportedInterfaceOrientations' => [
        'UIInterfaceOrientationPortrait',
        'UIInterfaceOrientationLandscapeLeft',
        'UIInterfaceOrientationLandscapeRight',
      ],
      'UILaunchStoryboardName' => 'LaunchScreen',
      'UIMainStoryboardFile' => 'AppStoryboard',
      'NSLocationWhenInUseUsageDescription' => 'ToastCatalog uses your location to find nearby Toast!'
    }
  end
end