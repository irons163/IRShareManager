Pod::Spec.new do |spec|
  spec.name         = "IRShareManager"
  spec.version      = "0.1.0"
  spec.summary      = "A powerful share extension of iOS."
  spec.description  = "A powerful share extension of iOS."
  spec.homepage     = "https://github.com/irons163/IRShareManager.git"
  spec.license      = "MIT"
  spec.author       = "irons163"
  spec.platform     = :ios, "9.0"
  spec.source       = { :git => "https://github.com/irons163/IRShareManager.git", :tag => spec.version.to_s }
  spec.source_files  = "IRShareManager/**/*.{h,m}"
  #spec.exclude_files = "IRShare/**/info.plist"
  #spec.app_spec 'SampleApp' do |app_spec|
    #app_spec.source_files = "IRShare/**/*"
    # app_spec.exclude_files = "IRShare/**/info.plist"
  #end
end