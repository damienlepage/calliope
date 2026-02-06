//
//  PathDisplayFormatter.swift
//  Calliope
//
//  Created on [Date]
//

import Foundation

struct PathDisplayFormatter {
    static func displayPath(
        _ url: URL,
        homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser
    ) -> String {
        displayPath(url.path, homeDirectory: homeDirectory)
    }

    static func displayPath(
        _ path: String,
        homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser
    ) -> String {
        let standardizedPath = URL(fileURLWithPath: path).standardizedFileURL.path
        let homePath = homeDirectory.standardizedFileURL.path

        guard standardizedPath.hasPrefix(homePath) else {
            return standardizedPath
        }

        if standardizedPath == homePath {
            return "~"
        }

        let suffix = standardizedPath.dropFirst(homePath.count)
        if suffix.first == "/" {
            return "~" + suffix
        }
        return "~/" + suffix
    }
}
