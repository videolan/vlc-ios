/*****************************************************************************
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015-2021 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Ben Sidhom <bsidhom # gmail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import Foundation

class SortedMediaFiles: NSObject {
    private var files: NSMutableArray

    @objc override init() {
        files = []
    }

    @objc static func fromArray(_ paths: [NSString]) -> SortedMediaFiles {
        let result = SortedMediaFiles()
        for path in paths {
            result.add(path)
        }
        return result
    }

    @objc func add(_ path: NSString) {
        let idx = index(of: path)
        if idx == files.count || files.object(at:idx) as! NSString != path {
            // Only insert if we don't already have this path.
            files.insert(path, at: idx)
        }
    }

    @objc var count: Int { files.count }

    @objc subscript(_ index: Int) -> NSString {
        if index < 0 {
            fatalError("index out of bounds: \(index) < 0")
        }
        if index >= files.count {
            fatalError("index out of bounds: \(index) > \(files.count)")
        }
        return files.object(at: index) as! NSString
    }

    @objc func remove(_ path: NSString) {
        files.remove(path)
    }

    @objc var readonlycopy: NSArray { files.copy() as! NSArray }

    // Gets the index of the given path or an appropriate insertion index to
    // maintain sorted order.
    private func index(of path: NSString) -> Int {
        files.index(of: path,
                    inSortedRange: NSRange(location: 0, length: files.count),
                    options: [NSBinarySearchingOptions.insertionIndex, NSBinarySearchingOptions.firstEqual],
                    usingComparator: SortedMediaFiles.comparePaths)
    }

    private static func comparePaths(lhs: Any, rhs: Any) -> ComparisonResult {
        let left = lhs as! NSString
        let right = rhs as! NSString
        let leftBase = left.lastPathComponent
        let rightBase = right.lastPathComponent
        let baseCmp = leftBase.compare(rightBase)
        if baseCmp != ComparisonResult.orderedSame {
            return baseCmp
        }
        return left.compare(right as String)
    }
}
