//
// Copyright 2020 Adobe. All rights reserved.
// This file is licensed to you under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License. You may obtain a copy
// of the License at http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software distributed under
// the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
// OF ANY KIND, either express or implied. See the License for the specific language
// governing permissions and limitations under the License.
//

import Foundation
import ACPCore

class NetworkResponseHandler {
    private let LOG_TAG = "NetworkResponseHandler"
    private let queue = DispatchQueue(label: "com.adobe.experiencePlatform.eventsDictionary")
    
    // the order of the request events matter for matching them with the response events
    private var sentEventsWaitingResponse = ThreadSafeDictionary<String, [String]>()
    
    /// Adds the requestId in the internal `sentEventsWaitingResponse` with the associated list of events.
    /// This list should maintain the order of the received events for matching with the response event index.
    /// If the same requestId was stored before, the new list will replace the existing events.
    /// - Parameters:
    ///   - requestId: batch request id
    ///   - batchedEvents: batched events sent to ExEdge
    func addWaitingEvents(requestId:String, batchedEvents: [ACPExtensionEvent]) {
        guard !requestId.isEmpty, !batchedEvents.isEmpty else { return }
        
        let eventIds = batchedEvents.map { $0.eventUniqueIdentifier }
        queue.sync {
            if sentEventsWaitingResponse[requestId] != nil {
                ACPCore.log(ACPMobileLogLevel.warning, tag:LOG_TAG, message:"Name collision for requestId \(requestId), events list is overwritten.")
            }
            
            sentEventsWaitingResponse[requestId] = eventIds
        }
    }
    
    /// Remove the requestId in the internal {@code sentEventsWaitingResponse} along with the associated list of events.
    /// - Parameter requestId: batch request id
    /// - Returns: the list of unique event ids associated with the requestId that were removed
    func removeWaitingEvents(requestId: String) -> [String]? {
        guard !requestId.isEmpty else { return nil }
        return sentEventsWaitingResponse.removeValue(forKey: requestId)
    }
    
    /// Returns the list of unique event ids associated with the provided requestId or empty if not found.
    /// - Parameter requestId: batch request id
    /// - Returns: the list of unique event ids associated with the requestId or nil if none found
    func getWaitingEvents(requestId: String) -> [String]? {
        guard !requestId.isEmpty else { return nil }
        return sentEventsWaitingResponse[requestId]
    }
    
    func processResponseOnSuccess(jsonResponse:String, requestId:String) {
        guard let data = jsonResponse.data(using: .utf8) else { return }
        
        if let edgeResponse = try? JSONDecoder().decode(EdgeResponse.self, from: data) {
            ACPCore.log(ACPMobileLogLevel.debug, tag:LOG_TAG, message:"processResponseOnSuccess - Received server response:\n \(jsonResponse), request id \(requestId)")
            
            // handle the event handles, errors and warnings coming from server
            dispatchEventHandles(handlesArray: edgeResponse.handle, requestId: requestId)
            dispatchEventErrors(errorsArray: edgeResponse.errors, requestId: requestId, isError: true)
            dispatchEventErrors(errorsArray: edgeResponse.warnings, requestId: requestId, isError: false)
        } else {
            ACPCore.log(ACPMobileLogLevel.warning, tag:LOG_TAG,
                        message:"processResponseOnSuccess - The conversion to JSON failed for server response: \(jsonResponse), request id \(requestId)")
        }
    }
    
    func processResponseOnError(jsonError:String, requestId:String) {
        guard let data = jsonError.data(using: .utf8) else { return }
        
        guard let edgeErrorResponse = try? JSONDecoder().decode(EdgeResponse.self, from: data) else {
            ACPCore.log(ACPMobileLogLevel.warning, tag:LOG_TAG,
                        message:"processResponseOnError - The conversion to JSON failed for server error response: \(jsonError), request id \(requestId)")
            return
        }
        
        ACPCore.log(ACPMobileLogLevel.debug, tag:LOG_TAG, message:"processResponseOnError - Processing server error response:\n \(jsonError), request id \(requestId)")
        
        // Note: if the Konductor error doesn't have an eventIndex it means that this error is a generic request error,
        // otherwise it is an event specific error. There can be multiple errors returned for the same event
        if let _ = edgeErrorResponse.errors {
            // this is an error coming from Konductor, read the error from the errors node
            dispatchEventErrors(errorsArray: edgeErrorResponse.errors, requestId: requestId, isError: true)
        } else {
            guard
                let responseEventData = try? JSONDecoder().decode([String:AnyCodable].self, from: data),
                let responseEvent: ACPExtensionEvent = try? ACPExtensionEvent(name: ExperiencePlatformConstants.eventNameErrorResponseContent,
                                                                              type: ExperiencePlatformConstants.eventTypeExperiencePlatform,
                                                                              source: ExperiencePlatformConstants.eventSourceExtensionErrorResponseContent,
                                                                              data: responseEventData),
                let _ = try? ACPCore.dispatchEvent(responseEvent) else {
                    ACPCore.log(ACPMobileLogLevel.warning, tag:LOG_TAG,
                                message:"processResponseOnError - An error occurred while dispatching platform response event with data: \(jsonError), request id \(requestId)")
                    return
            }
        }
    }
    
    
    /// Dispatches each event handle in the provided `handlesArray` as a separate event through the Event Hub
    /// - Parameters:
    ///   - handlesArray: `[EdgeEventHandle]` containing all the event handles to be processed
    ///   - requestId: the request identifier, used for logging and to identify the request events associated with this response
    private func dispatchEventHandles(handlesArray: [EdgeEventHandle]?, requestId: String) {
        guard let unwrappedEventHandles = handlesArray, !unwrappedEventHandles.isEmpty else {
            ACPCore.log(ACPMobileLogLevel.verbose, tag:LOG_TAG, message:"dispatchEventHandles - Received nil/empty event handle array, nothing to handle")
            return
        }
        
        let requestEventIdsList = getWaitingEvents(requestId: requestId)
        ACPCore.log(ACPMobileLogLevel.verbose, tag:LOG_TAG, message:"dispatchEventHandles - Processing \(unwrappedEventHandles.count) event handle(s) for request id: \(requestId)")
        for eventHandle in unwrappedEventHandles {
            handleStoreEventHandle(handle: eventHandle)
            
            guard let eventHandleAsDictionary = try? eventHandle.asDictionary() else { return }
            // set eventRequestId and edge requestId on the response event and dispatch data
            let eventData = addEventAndRequestIdToDictionary(eventHandleAsDictionary, requestEventIdsList: requestEventIdsList, index: eventHandle.eventIndex, requestId: requestId)
            guard !eventData.isEmpty else { return }
            dispatchResponseEventWithData(eventData, requestId: requestId, isErrorResponseEvent: false)
        }
    }
    
    private func dispatchEventErrors(errorsArray : [EdgeEventError]?, requestId: String, isError:Bool) {
        guard let unwrappedErrors = errorsArray, !unwrappedErrors.isEmpty else {
            ACPCore.log(ACPMobileLogLevel.verbose, tag:LOG_TAG, message:"dispatchEventErrors - Received nil/empty errors array, nothing to handle")
            return
        }
        
        let requestEventIdsList = getWaitingEvents(requestId: requestId)
        ACPCore.log(ACPMobileLogLevel.verbose, tag:LOG_TAG, message:"dispatchEventErrors - Processing \(unwrappedErrors.count) errors(s) for request id: \(requestId)")
        for error in unwrappedErrors {
            logErrorMessage(error, isError: isError, requestId: requestId)
            
            if let errorAsDictionary = try? error.asDictionary() {
                
                // set eventRequestId and edge requestId on the response event and dispatch data
                let eventData = addEventAndRequestIdToDictionary(errorAsDictionary, requestEventIdsList: requestEventIdsList, index: error.eventIndex, requestId: requestId)
                guard !eventData.isEmpty else { return }
                dispatchResponseEventWithData(eventData, requestId: requestId, isErrorResponseEvent: true)
                
            }
        }
    }
    
    private func dispatchResponseEventWithData(_ eventData: [String: Any], requestId: String, isErrorResponseEvent: Bool) {
        var responseEvent:ACPExtensionEvent? = nil
        if isErrorResponseEvent {
            responseEvent = try? ACPExtensionEvent(name: ExperiencePlatformConstants.eventNameErrorResponseContent,
                                                   type: ExperiencePlatformConstants.eventTypeExperiencePlatform,
                                                   source: ExperiencePlatformConstants.eventSourceExtensionErrorResponseContent,
                                                   data: eventData as [AnyHashable : Any])
        } else {
            responseEvent = try? ACPExtensionEvent(name: ExperiencePlatformConstants.eventNameResponseContent,
                                                   type: ExperiencePlatformConstants.eventTypeExperiencePlatform,
                                                   source: ExperiencePlatformConstants.eventSourceExtensionResponseContent,
                                                   data: eventData as [AnyHashable : Any])
        }
        
        guard let unwrappedResponseEvent = responseEvent else { return }
        guard let _ = try? ACPCore.dispatchEvent(unwrappedResponseEvent) else {
            ACPCore.log(ACPMobileLogLevel.warning, tag:LOG_TAG, message:"dispatchResponseEvent - An error occurred while dispatching platform response event for request id: \(requestId)")
            return
        }
    }
    
    /// Extracts the event unique id corresponding to the eventIndex from `EventHandle` and returns the corresponding event data
    /// - Parameters:
    ///   - dictionary: data coming from server (an event handle or error or warning), which will be enhanced with eventUniqueId
    ///   - requestEventIdsList: waiting events list for current `requestId`
    ///   - index: the request event index associated with this event handle/error
    ///   - requestId: current request id to be added to data
    private func addEventAndRequestIdToDictionary(_ dictionary: [String: Any], requestEventIdsList: [String]?, index: Int?, requestId: String) -> [String: Any] {
        var eventData : [String: Any] = dictionary
        eventData[ExperiencePlatformConstants.EventDataKeys.edgeRequesId] = requestId
        
        guard let unwrappedEventIds = requestEventIdsList, let unwrappedIndex = index, unwrappedIndex > 0, unwrappedIndex < unwrappedEventIds.count else { return eventData }
        eventData[ExperiencePlatformConstants.EventDataKeys.requestEventId] = unwrappedEventIds[unwrappedIndex]
        return eventData
    }
    
    /// If handle is of type "state:store" persist it to Data Store
    /// - Parameter handle: current `EventHandle` to store
    private func handleStoreEventHandle(handle: EdgeEventHandle) {
        guard let type = handle.type, ExperiencePlatformConstants.JsonKeys.Response.eventHandleStoreType == type.lowercased() else { return }
        guard let payload: [[String: AnyCodable]] = handle.payload else { return }
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        var storeResponsePayloads : [StoreResponsePayload] = []
        for storeElement in payload {
            if let data = try? encoder.encode(storeElement), let storePayload = try? JSONDecoder().decode(StorePayload.self, from: data) {
                storeResponsePayloads.append(StoreResponsePayload(payload: storePayload))
            }
        }
        
        let dataStore = NamedUserDefaultsStore(name: ExperiencePlatformConstants.DataStoreKeys.storeName)
        let storeResponsePayloadManager = StoreResponsePayloadManager(dataStore)
        storeResponsePayloadManager.saveStorePayloads(storeResponsePayloads)
    }
    
    private func logErrorMessage(_ error: EdgeEventError, isError: Bool, requestId: String) {
        // todo
    }
}
