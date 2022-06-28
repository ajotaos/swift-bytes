func calculateGrownCapacity(for capacity: Int) -> Int {
    let (newCapacity, overflow) = capacity.addingReportingOverflow(max(capacity >> 1, 1))

    guard newCapacity < .max, !overflow else { return .max }

    return newCapacity + (newCapacity ^ 1 == newCapacity - 1 ? 1 : 0)
}
