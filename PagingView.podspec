Pod::Spec.new do |s|
  s.name         = "PagingView"
  s.version      = "0.1.0"
  s.summary      = "Infinite paging, Smart auto layout, Interface of similar to UIKit."
  s.homepage     = "https://github.com/KyoheiG3/PagingView"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author       = { "Kyohei Ito" => "je.suis.kyohei@gmail.com" }
  s.platform     = :ios, "8.0"
  s.source       = { :git => "https://github.com/KyoheiG3/PagingView.git", :tag => s.version.to_s }
  s.source_files  = "PagingView/**/*.{h,swift}"
  s.requires_arc = true
  s.frameworks = "UIKit"
end
