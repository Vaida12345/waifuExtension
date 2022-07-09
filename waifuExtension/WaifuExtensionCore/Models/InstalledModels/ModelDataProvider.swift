//
//  ModelDataProvider.swift
//  waifuExtension
//
//  Created by Vaida on 6/13/22.
//

import Foundation
import Support

final class ModelDataProvider: DataProvider {
    
    typealias Container = _ModelDataProvider
    
    @Published var container: Container
    
    /// The main ``DataProvider`` to work with.
    static var main = ModelDataProvider()
    
    /// Load contents from disk, otherwise initialize with the default parameters.
    init() {
        if let container = ModelDataProvider.decoded() {
            self.container = container
        } else {
            self.container = Container()
            save()
        }
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


public struct _ModelDataProvider: Codable, Hashable {
    
    public var location: [String: String] = [:]
    
    
}
