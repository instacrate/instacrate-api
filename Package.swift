import PackageDescription

let package = Package(
    name: "subber-api",
    dependencies: [
        .Package(url: "https://github.com/vapor/vapor.git", majorVersion: 1, minor: 3),
        .Package(url: "https://github.com/vapor/mysql-provider.git", majorVersion: 1, minor: 1),
        .Package(url: "https://github.com/instacrate/Stripe", majorVersion: 0, minor: 0),
        .Package(url: "https://github.com/SwiftyBeaver/SwiftyBeaver-Vapor.git", majorVersion: 1),
        .Package(url: "https://github.com/nodes-vapor/bugsnag", majorVersion: 0),
        .Package(url: "https://github.com/nodes-vapor/sanitized.git", majorVersion: 0)
    ],
    exclude: [
        "Config",
        "Database",
        "Localization",
        "Public",
        "Resources",
        "Tests",
    ]
)
