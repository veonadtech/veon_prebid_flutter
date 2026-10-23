// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "setupad_prebid_flutter",
    platforms: [.iOS(.v13)],
    products: [
        .library(name: "setupad-prebid-flutter", targets: ["setupad_prebid_flutter"]),
    ],
    dependencies: [
        .package(url: "https://github.com/veonadtech/prebid-ios-sdk.git", exact: "0.5.2"),
        .package(url: "https://github.com/googleads/swift-package-manager-google-mobile-ads.git", from: "13.6.0"),
    ],
    targets: [
        .target(
            name: "setupad_prebid_flutter",
            dependencies: [
                .product(name: "VeonPrebidMobile", package: "prebid-ios-sdk"),
                .product(name: "VeonPrebidMobileGAMEventHandlers", package: "prebid-ios-sdk"),
                .product(name: "GoogleMobileAds", package: "swift-package-manager-google-mobile-ads"),
            ],
            path: "Sources/setupad_prebid_flutter"
        ),
    ]
)
