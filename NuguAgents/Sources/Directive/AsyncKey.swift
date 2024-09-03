//
//  AsyncKey.swift
//  NuguAgents
//
//  Created by jaycesub on 2020/07/10.
//  Copyright (c) 2024 SK Telecom Co., Ltd. All rights reserved.
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

public struct AsyncKey: Decodable {
    public let eventDialogRequestId: String
    public let state: State
    public let routing: String
    
    public enum State: String, Decodable {
        case start = "START"
        case ongoing = "ONGOING"
        case end = "END"
    }
}
