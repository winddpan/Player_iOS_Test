Pod::Spec.new do |spec|
    spec.name = 'SuperPlayer'
    spec.version = '3.1.1'
    spec.license = { :type => 'MIT' }
    spec.homepage = 'https://cloud.tencent.com/product/player'
    spec.authors = { 'annidyfeng' => 'annidyfeng@tencent.com' }
    spec.summary = '超级播放器'
    spec.source = { :git => 'https://github.com/tencentyun/SuperPlayer_iOS.git', :tag => 'v3.1.1' }

    spec.ios.deployment_target = '8.0'
    spec.requires_arc = true

    spec.dependency 'AFNetworking'
    spec.dependency 'SDWebImage'
    spec.dependency 'Masonry'
    #spec.dependency 'MMLayout'

    spec.static_framework = true
    spec.default_subspec = 'Player'

    spec.ios.framework    = ['SystemConfiguration','CoreTelephony', 'VideoToolbox', 'CoreGraphics', 'AVFoundation', 'Accelerate']
    spec.ios.library = 'z', 'resolv', 'iconv', 'stdc++', 'c++', 'sqlite3'

    # spec.subspec "Core" do |s|
    #     s.source_files = 'SuperPlayer/**/*.{h,m}'
    #     s.resource = 'SuperPlayer/Resource/*'
    # end
#    spec.resource = 'SuperPlayer/Resource/*'
    
    spec.subspec "Player" do |s|
        s.source_files = 'SuperPlayer/**/*.{h,m}'
        s.private_header_files = 'SuperPlayer/Utils/TXBitrateItemHelper.h', 'SuperPlayer/Views/SuperPlayerView+Private.h'
        s.resource = 'SuperPlayer/Resource/*'
#如果要使用cocopods管理的TXLiteAVSDK_Player，就不注释这一行
        s.dependency 'TXLiteAVSDK_Player'
    end
    spec.subspec "Professional" do |s|
        s.source_files = 'SuperPlayer/**/*.{h,m}'
        s.private_header_files = 'SuperPlayer/Utils/TXBitrateItemHelper.h', 'SuperPlayer/Views/SuperPlayerView+Private.h'
        s.resource = 'SuperPlayer/Resource/*'
        s.dependency 'TXLiteAVSDK_Professional'
    end

    spec.frameworks = ["SystemConfiguration", "CoreTelephony", "VideoToolbox", "CoreGraphics", "AVFoundation", "Accelerate"]
    spec.libraries = [
      "z",
      "resolv",
      "iconv",
      "stdc++",
      "c++",
      "sqlite3"
    ]
end

# pod trunk push SuperPlayer.podspec --verbose --use-libraries --allow-warnings
