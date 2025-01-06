//
//  RingBuffer.swift
//  JadeMarble
//
//  Created by jaycesub on 1/6/25.
//  Copyright (c) 2025 SK Telecom Co., Ltd. All rights reserved.
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

struct RingBuffer<T> {
    private var buffer: [T?]
    private var head: Int = 0
    private var tail: Int = 0
    private let capacity: Int

    init(capacity: Int) {
        self.capacity = capacity
        self.buffer = Array(repeating: nil, count: capacity)
    }

    mutating func enqueue(_ element: T) {
        buffer[tail] = element
        
        tail = (tail + 1) % capacity
        if tail == head {
            head = (head + 1) % capacity
        }
    }

    mutating func dequeue() -> T? {
        guard head != tail, head < capacity else { return nil }

        let element = buffer[head]
        head = (head + 1) % capacity
        return element
    }

    func isEmpty() -> Bool {
        return head == tail
    }

    func isFull() -> Bool {
        return (tail + 1) % capacity == head
    }

    func peek() -> T? {
        return buffer[head]
    }
    
    mutating func moveHead(to index: Int) {
        head = index % capacity
    }

    #if DEBUG
    func printBuffer() {
        var elements = [T]()
        var index = head
        while index != tail {
            elements.append(buffer[index]!)
            index = (index + 1) % capacity
        }
        log.debug("Buffer: \(elements)")
    }
    #endif
}
