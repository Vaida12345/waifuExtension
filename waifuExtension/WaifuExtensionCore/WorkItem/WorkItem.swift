//
//  WorkItem Extensions.swift
//  waifuExtension
//
//  Created by Vaida on 6/16/22.
//

import Foundation
import Support

@dynamicMemberLookup public final class WorkItem: Equatable, Identifiable, Hashable {
    public var finderItem: FinderItem
    public var type: ItemType
    
    public enum ItemType: String {
        case video, image
    }
    
    init(at finderItem: FinderItem, type: ItemType) {
        self.finderItem = finderItem
        self.type = type
    }
    
    public static func == (lhs: WorkItem, rhs: WorkItem) -> Bool {
        lhs.finderItem == rhs.finderItem
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(finderItem)
        hasher.combine(type)
    }
    
    public subscript<Subject>(dynamicMember keyPath: WritableKeyPath<FinderItem, Subject>) -> Subject {
        get { finderItem[keyPath: keyPath] }
        set { finderItem[keyPath: keyPath] = newValue }
    }
    
    public subscript<Subject>(dynamicMember keyPath: KeyPath<FinderItem, Subject>) -> Subject {
        finderItem[keyPath: keyPath]
    }
}
