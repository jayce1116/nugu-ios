//
//  ContextManager.swift
//  NuguCore
//
//  Created by MinChul Lee on 25/04/2019.
//  Copyright (c) 2019 SK Telecom Co., Ltd. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Foundation
import Combine

import NuguUtils

public class ContextManager: ContextManageable {
    @Atomic private var providers = [ContextInfoProviderType?]()

    public init() {}
}

// MARK: - ContextManageable

extension ContextManager {
    public func addProvider(_ provider: @escaping ContextInfoProviderType) {
        _providers.mutate {
            $0.append(provider)
        }
    }
    
    public func removeProvider(_ provider: @escaping ContextInfoProviderType) {
        _providers.mutate {
            $0 = $0.filter { $0 as AnyObject !== provider as AnyObject }
        }
    }
    
    public func getContexts(namespace: String, completion: @escaping ([ContextInfo]) -> Void) {
        getContexts { contextInfos in
            let filteredPayload = contextInfos.compactMap { contextInfo -> ContextInfo? in
                if contextInfo.contextType == .client || contextInfo.name == namespace {
                    return contextInfo
                } else {
                    // FIXME: 추후 서버에서 각 capability interface 정보를 저장하게 되면 제거해야 함.
                    if let payload = contextInfo.payload as? [String: AnyHashable] {
                        let versionPayload = payload.filter { $0.key == "version" }
                        return ContextInfo(contextType: contextInfo.contextType, name: contextInfo.name, payload: versionPayload)
                    } else {
                        return contextInfo
                    }
                }
            }

            completion(filteredPayload)
        }
    }
    
    public func getContexts(completion: @escaping ([ContextInfo]) -> Void) {
        Task {
            let contextInfos = await withTaskGroup(of: ContextInfo?.self) { group in
                providers.compactMap { $0 }.forEach { provider in
                    group.addTask {
                        await withCheckedContinuation { continuation in
                            provider { contextInfo in
                                continuation.resume(returning: contextInfo)
                            }
                        }
                    }
                }
                
                var results: [ContextInfo?] = []
                for await result in group {
                    results.append(result)
                }
                
                return results.compactMap { $0 }
            }
            completion(contextInfos)
        }
    }
}
