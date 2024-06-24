//
//  BlockingPolicy.swift
//  NuguCore
//
//  Created by MinChul Lee on 2020/03/20.
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

public struct BlockingPolicy {
    public let blockedBy: Set<Medium>?
    public let blocking: Set<Medium>?
    
    public init(blockedBy: Set<Medium>? = nil, blocking: Set<Medium>? = nil) {
        self.blockedBy = blockedBy
        self.blocking = blocking
    }
    
    public enum Medium: CaseIterable {
        case audio
        case visual
        case any
    }
}

public extension Set where Element == BlockingPolicy.Medium {
    static let all: Set<Element> = [.audio, .visual, .any]
    static let any: Set<Element> = [.any]
    static let audio: Set<Element> = [.audio, .any]
    static let audioOnly: Set<Element> = [.audio]
    static let visual: Set<Element> = [.visual, .any]
    static let visualOnly: Set<Element> = [.visual]
    static let audioAndVisual: Set<Element> = [.audio, .visual]
}
