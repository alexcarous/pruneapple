import Foundation

extension FileItem {
    mutating func sort(using comparators: [KeyPathComparator<FileItem>]) {
        if var kids = children {
            kids.sort(using: comparators)
            for i in kids.indices {
                kids[i].sort(using: comparators)
            }
            children = kids
        }
    }
}
