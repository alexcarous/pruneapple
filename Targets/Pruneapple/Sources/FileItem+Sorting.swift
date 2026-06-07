import Foundation

extension FileItem {
    mutating func sort(using comparators: [KeyPathComparator<FileItem>]) {
        if var kids = children {
            kids.sort(using: comparators)
            for index in kids.indices {
                kids[index].sort(using: comparators)
            }
            children = kids
        }
    }
}
