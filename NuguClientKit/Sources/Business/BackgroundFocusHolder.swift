//
//  BackgroundFocusHolder.swift
//  NuguClientKit
//
//  Created by MinChul Lee on 2020/09/27.
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

import NuguCore
import NuguAgents

class BackgroundFocusHolder {
    private let focusManager: FocusManageable
    
    private let queue = DispatchQueue(label: "com.sktelecom.romaine.dummy_focus_requester")
    // Prevent releasing focus while these event are being processed.
    private let focusTargets = [
        "TTS.SpeechFinished",
        "AudioPlayer.PlaybackFinished",
        "MediaPlayer.PlaySuspended"
    ]
    
    private let pendingTargets = [
        "ASR.NotifyResult"
    ]
    
    private var handlingEvents = Set<String>()
    private var handlingSoundDirectives = Set<String>()
    private var handlingPendingDirectives = Set<String>()
    private var dialogState: DialogState = .idle
    
    // Observers
    private let notificationCenter = NotificationCenter.default
    private var eventWillSendObserver: Any?
    private var eventDidSendObserver: Any?
    private var dialogStateObserver: Any?
    private var directiveReceiveObserver: Any?
    private var directivePrefetchObserver: Any?
    private var directiveCompleteObserver: Any?
    
    init(
        focusManager: FocusManageable,
        directiveSequener: DirectiveSequenceable,
        streamDataRouter: StreamDataRoutable,
        dialogStateAggregator: DialogStateAggregator
    ) {
        self.focusManager = focusManager
        
        focusManager.add(channelDelegate: self)
        
        // Observers
        addStreamDataRouterObserver(streamDataRouter)
        addDialogStateObserver(dialogStateAggregator)
        addDirectiveSequencerObserver(directiveSequener)
    }
    
    deinit {
        if let eventWillSendObserver = eventWillSendObserver {
            notificationCenter.removeObserver(eventWillSendObserver)
        }

        if let eventDidSendObserver = eventDidSendObserver {
            notificationCenter.removeObserver(eventDidSendObserver)
        }
        
        if let dialogStateObserver = dialogStateObserver {
            notificationCenter.removeObserver(dialogStateObserver)
        }
        
        if let directivePrefetchObserver = directivePrefetchObserver {
            notificationCenter.removeObserver(directivePrefetchObserver)
        }
        
        if let directiveCompleteObserver = directiveCompleteObserver {
            notificationCenter.removeObserver(directiveCompleteObserver)
        }
        
        if let directiveReceiveObserver = directiveReceiveObserver {
            notificationCenter.removeObserver(directiveReceiveObserver)
        }
    }
}

// MARK: - FocusChannelDelegate

extension BackgroundFocusHolder: FocusChannelDelegate {
    func focusChannelPriority() -> FocusChannelPriority {
        .background
    }
    
    func focusChannelDidChange(focusState: FocusState) {
        log.debug(focusState)
    }
}

// MARK: - Private

private extension BackgroundFocusHolder {
    func requestFocus() {
        focusManager.requestFocus(channelDelegate: self)
    }
    
    func tryReleaseFocus() {
        guard handlingEvents.isEmpty,
              handlingSoundDirectives.isEmpty,
              handlingPendingDirectives.isEmpty,
              dialogState == .idle else { return }
        
        focusManager.releaseFocus(channelDelegate: self)
    }
}

// MARK: - Observers

private extension BackgroundFocusHolder {
    func addStreamDataRouterObserver(_ object: StreamDataRoutable) {
        eventWillSendObserver = object.observe(NuguCoreNotification.StreamDataRoute.ToBeSentEvent.self, queue: nil) { [weak self] (notification) in
            self?.queue.async { [weak self] in
                guard let self = self else { return }
                
                if self.focusTargets.contains(notification.event.header.type) {
                    self.handlingEvents.insert(notification.event.header.messageId)
                    self.requestFocus()
                }
            }
        }
        
        eventDidSendObserver = object.observe(NuguCoreNotification.StreamDataRoute.SentEvent.self, queue: nil) { [weak self] (notification) in
            self?.queue.async { [weak self] in
                guard let self = self else { return }
                
                if self.handlingEvents.remove(notification.event.header.messageId) != nil {
                    self.tryReleaseFocus()
                }
            }
        }
        
        directiveReceiveObserver = object.observe(NuguCoreNotification.StreamDataRoute.ReceivedDirective.self, queue: nil) { [weak self] notification in
            self?.queue.async { [weak self] in
                guard let self else { return }
                let dialogRequestId = notification.directive.header.dialogRequestId
                if pendingTargets.contains(notification.directive.header.type) {
                    handlingPendingDirectives.insert(dialogRequestId)
                    requestFocus()
                } else if handlingPendingDirectives.contains(dialogRequestId) {
                    // PendingTarget과 동일한 dialogRequestId를 수신할 경우 focus를 유지
                } else {
                    handlingPendingDirectives.removeAll()
                    tryReleaseFocus()
                }
            }
        }
    }
    
    func addDialogStateObserver(_ object: DialogStateAggregator) {
        dialogStateObserver = object.observe(NuguClientNotification.DialogState.State.self, queue: nil) { [weak self] (notification) in
            self?.queue.async { [weak self] in
                guard let self = self else { return }
                
                self.dialogState = notification.state
                if notification.state == .idle {
                    self.tryReleaseFocus()
                } else {
                    self.requestFocus()
                }
            }
        }
    }
    
    func addDirectiveSequencerObserver(_ object: DirectiveSequenceable) {
        directivePrefetchObserver = object.observe(NuguCoreNotification.DirectiveSquencer.Prefetch.self, queue: nil) { [weak self] notification in
            self?.queue.async { [weak self] in
                guard let self = self else { return }
                
                if notification.blockingPolicy.blockedBy == .audio, notification.blockingPolicy.blocking == .audioOnly {
                    self.handlingSoundDirectives.insert(notification.directive.header.messageId)
                    self.requestFocus()
                }
            }
        }
        
        directiveCompleteObserver = object.observe(NuguCoreNotification.DirectiveSquencer.Complete.self, queue: nil) { [weak self] notification in
            self?.queue.async { [weak self] in
                guard let self = self else { return }
                
                if self.handlingSoundDirectives.remove(notification.directive.header.messageId) != nil {
                    self.tryReleaseFocus()
                }
            }
        }
    }
}
