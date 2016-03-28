import Foundation

extension NSDate: Comparable {}

public func == (lhs: NSDate, rhs: NSDate) -> Bool {
    return lhs.isEqualToDate(rhs)
}

public func <= (lhs: NSDate, rhs: NSDate) -> Bool {
    return lhs < rhs || lhs == rhs
}

public func >= (lhs: NSDate, rhs: NSDate) -> Bool {
    return rhs <= lhs
}

public func < (lhs: NSDate, rhs: NSDate) -> Bool {
    return lhs.compare(rhs) == NSComparisonResult.OrderedAscending
}

public func > (lhs: NSDate, rhs: NSDate) -> Bool {
    return rhs < lhs
}
