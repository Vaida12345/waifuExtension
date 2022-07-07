//
//  ModelDataProvider.swift
//  waifuExtension
//
//  Created by Vaida on 6/13/22.
//

import Foundation
import Support

public final class ModelDataProvider: DataProvider {
    
    @Published public var location: [String: String] = [:]
    
    public static var main: ModelDataProvider = .decode(from: .preferencesDirectory.with(subPath: "model.json"))
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.location)
    }
    
    required public init() { }
    
    public static func == (lhs: ModelDataProvider, rhs: ModelDataProvider) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
    
    enum CodingKeys: CodingKey {
        case location
    }
    
    
    required public init(from decoder: Decoder) throws {
        let container: KeyedDecodingContainer<ModelDataProvider.CodingKeys> = try decoder.container(keyedBy: ModelDataProvider.CodingKeys.self)
        
        self.location = try container.decode([String : String].self, forKey: ModelDataProvider.CodingKeys.location)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container: KeyedEncodingContainer<ModelDataProvider.CodingKeys> = encoder.container(keyedBy: ModelDataProvider.CodingKeys.self)
        
        try container.encode(self.location, forKey: ModelDataProvider.CodingKeys.location)
    }
    
    public func loadModels(from sources: [FinderItem], onNotReadable: @escaping (String) -> Void, onNonAdded: @escaping () -> Void) {
        let adderQueue = DispatchQueue.main
        var addedCounter = 0
        var isReadable = true
        for source in sources {
            for model in ModelCoordinator.allInstalledModels {
                checkModel(model: model, item: source, queue: adderQueue) { name in
                    isReadable = false
                    onNotReadable(name)
                } onSucceed: {
                    addedCounter += 1
                }
            }
        }
        
        adderQueue.async {
            guard addedCounter == 0 else { return }
            guard isReadable else { return }
            onNonAdded()
        }
    }
    
    private func checkModel(model: any InstalledModel.Type, item: FinderItem, queue: DispatchQueue, onNotReadable: @escaping (String) -> Void, onSucceed: @escaping () -> Void) {
        if item.name.contains(model.rawName) {
            guard let children = item.children(range: .contentsOfDirectory) else { return }
            guard children.contains(where: { $0.name == model.rawName }) else { return }
            let task = ShellManager()
            guard task.run(path: "\(item.path + "/\(model.rawName)")", arguments: "") else {
                queue.async { onNotReadable(model.name) }
                return
            }
            queue.async {
                self.location[model.rawName] = item.path
                onSucceed()
            }
        }
    }
    
}
