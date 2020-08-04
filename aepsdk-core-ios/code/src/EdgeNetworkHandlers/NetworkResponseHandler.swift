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

import ACPCore
import Foundation

/// This class is used to process the ExEdge network responses when the ResponseCallback is invoked with a response or error message. The response processing consists in parsing
/// the server response message and dispatching response content and/or error response content events and storing the response payload (if needed).
/// - See also: `EdgeResponse` and  `NetworkResponseCallback`
class NetworkResponseHandler {
    private let logTag = "NetworkResponseHandler"
    private let serialQueue = DispatchQueue(label: "com.adobe.experiencePlatform.eventsDictionary") // serial queue for atomic operations

    // the order of the request events matter for matching them with the response events
    private var sentEventsWaitingResponse = ThreadSafeDictionary<String, [String]>()

    /// Adds the requestId in the internal `sentEventsWaitingResponse` with the associated list of events.
    /// This list should maintain the order of the received events for matching with the response event index.
    /// If the same requestId was stored before, the new list will replace the existing events.
    /// - Parameters:
    ///   - requestId: batch request id
    ///   - batchedEvents: batched events sent to ExEdge
    func addWaitingEvents(requestId: String, batchedEvents: [ACPExtensionEvent]) {
        guard !requestId.isEmpty, !batchedEvents.isEmpty else { return }

        let eventIds = batchedEvents.map { $0.eventUniqueIdentifier }
        serialQueue.sync {
            if self.sentEventsWaitingResponse[requestId] != nil {
                ACPCore.log(ACPMobileLogLevel.warning, tag: self.logTag, message: "Name collision for requestId \(requestId), events list is overwritten.")
            }

            self.sentEventsWaitingResponse[requestId] = eventIds
        }
    }

    /// Remove the requestId in the internal `sentEventsWaitingResponse` along with the associated list of events.
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

    /// Decodes the response as `EdgeResponse` and handles the event handles, errors and warnings received from the server
    /// - Parameters:
    ///   - jsonResponse: JSON formatted response received from the server
    ///   - requestId: request id associated with current response
    func processResponseOnSuccess(jsonResponse: String, requestId: String) {
        guard let data = jsonResponse.data(using: .utf8) else { return }

        if let edgeResponse = try? JSONDecoder().decode(EdgeResponse.self, from: data) {
            ACPCore.log(ACPMobileLogLevel.debug, tag: logTag, message: "processResponseOnSuccess - Received server response:\n \(jsonResponse), request id \(requestId)")

            // handle the event handles, errors and warnings coming from server
            dispatchEventHandles(handlesArray: edgeResponse.handle, requestId: requestId)
            dispatchEventErrors(errorsArray: edgeResponse.errors, requestId: requestId, isError: true)
            dispatchEventErrors(errorsArray: edgeResponse.warnings, requestId: requestId, isError: false)
        } else {
            ACPCore.log(ACPMobileLogLevel.warning, tag: logTag,
                        message: "processResponseOnSuccess - The conversion to JSON failed for server response: \(jsonResponse), request id \(requestId)")
        }
    }

    /// Decodes the response as `EdgeResponse` and extracts the errors if possible, otherwise decodes it as `EdgeEventError` and dispatches error events for the errors/warnings
    /// received from the server.
    /// - Parameters:
    ///   - jsonError: JSON formatted error response received from the server
    ///   - requestId: request id associated with current response
    func processResponseOnError(jsonError: String, requestId: String) {
        guard let data = jsonError.data(using: .utf8) else { return }

        guard let edgeErrorResponse = try? JSONDecoder().decode(EdgeResponse.self, from: data) else {
            ACPCore.log(ACPMobileLogLevel.warning, tag: logTag,
                        message: "processResponseOnError - The conversion to JSON failed for server error response: \(jsonError), request id \(requestId)")
            return
        }

        ACPCore.log(ACPMobileLogLevel.debug, tag: logTag, message: "processResponseOnError - Processing server error response:\n \(jsonError), request id \(requestId)")

        // Note: if the Konductor error doesn't have an eventIndex it means that this error is a generic request error,
        // otherwise it is an event specific error. There can be multiple errors returned for the same event
        if let _ = edgeErrorResponse.errors {
            // this is an error coming from Konductor, read the error from the errors node
            dispatchEventErrors(errorsArray: edgeErrorResponse.errors, requestId: requestId, isError: true)
        } else {
            // generic server error, return the error as is
            guard let genericErrorResponse = try? JSONDecoder().decode(EdgeEventError.self, from: data) else {
                ACPCore.log(ACPMobileLogLevel.warning, tag: logTag,
                            message: "processResponseOnError - The conversion to JSON failed for generic error response: \(jsonError), request id \(requestId)")
                return
            }

            dispatchEventErrors(errorsArray: [genericErrorResponse], requestId: requestId, isError: true)
        }
    }

    /// Dispatches each event handle in the provided `handlesArray` as a separate event through the Event Hub and processes
    /// the store event handles (if any).
    /// - Parameters:
    ///   - handlesArray: `[EdgeEventHandle]` containing all the event handles to be processed
    ///   - requestId: the request identifier, used for logging and to identify the request events associated with this response
    /// - See also: handleStoreEventHandle(handle: EdgeEventHandle)
    private func dispatchEventHandles(handlesArray: [EdgeEventHandle]?, requestId: String) {
        guard let unwrappedEventHandles = handlesArray, !unwrappedEventHandles.isEmpty else {
            ACPCore.log(ACPMobileLogLevel.verbose, tag: logTag, message: "dispatchEventHandles - Received nil/empty event handle array, nothing to handle")
            return
        }

        let requestEventIdsList = getWaitingEvents(requestId: requestId)
        ACPCore.log(ACPMobileLogLevel.verbose, tag: logTag, message: "dispatchEventHandles - Processing \(unwrappedEventHandles.count) event handle(s) for request id: \(requestId)")
        for eventHandle in unwrappedEventHandles {
            handleStoreEventHandle(handle: eventHandle)

            guard let eventHandleAsDictionary = try? eventHandle.asDictionary() else { return }
            // set eventRequestId and edge requestId on the response event and dispatch data
            let eventData = addEventAndRequestIdToDictionary(eventHandleAsDictionary, requestEventIdsList: requestEventIdsList, index: eventHandle.eventIndex, requestId: requestId)
            guard !eventData.isEmpty else { return }
            dispatchResponseEventWithData(eventData, requestId: requestId, isErrorResponseEvent: false)
        }
    }

    /// Iterates over the provided `errorsArray` and dispatches a new error event to the Event Hub.
    /// It also logs each error/warning json with the log level set based of `isError`
    /// - Parameters:
    ///   - errorsArray: `EdgeEventError` array containing all the event errors to be processed
    ///   - requestId: the event request identifier, used for logging
    ///   - isError: boolean indicating if this is an error message
    /// - See Also: `logErrorMessage(_ error: [String: Any], isError: Bool, requestId: String)`
    private func dispatchEventErrors(errorsArray: [EdgeEventError]?, requestId: String, isError: Bool) {
        guard let unwrappedErrors = errorsArray, !unwrappedErrors.isEmpty else {
            ACPCore.log(ACPMobileLogLevel.verbose, tag: logTag, message: "dispatchEventErrors - Received nil/empty errors array, nothing to handle")
            return
        }

        let requestEventIdsList = getWaitingEvents(requestId: requestId)
        ACPCore.log(ACPMobileLogLevel.verbose, tag: logTag, message: "dispatchEventErrors - Processing \(unwrappedErrors.count) errors(s) for request id: \(requestId)")
        for error in unwrappedErrors {

            if let errorAsDictionary = try? error.asDictionary() {
                logErrorMessage(errorAsDictionary, isError: isError, requestId: requestId)

                // set eventRequestId and edge requestId on the response event and dispatch data
                let eventData = addEventAndRequestIdToDictionary(errorAsDictionary, requestEventIdsList: requestEventIdsList, index: error.eventIndex, requestId: requestId)
                guard !eventData.isEmpty else { return }
                dispatchResponseEventWithData(eventData, requestId: requestId, isErrorResponseEvent: true)
            }
        }
    }

    /// Dispatched a new event with the provided `eventData` as responseContent or as errorResponseContent based on the `isErrorResponseEvent` setting
    /// - Parameters:
    ///   - eventData: Event data to be dispatched, should not be empty
    ///   - requestId: The request identifier associated with this response event, used for logging
    ///   - isErrorResponseEvent: indicates if this should be dispatched as an error or regular response content event
    private func dispatchResponseEventWithData(_ eventData: [String: Any], requestId: String, isErrorResponseEvent: Bool) {
        guard !eventData.isEmpty else { return }
        var responseEvent: ACPExtensionEvent?
        if isErrorResponseEvent {
            responseEvent = try? ACPExtensionEvent(name: ExperiencePlatformConstants.eventNameErrorResponseContent,
                                                   type: ExperiencePlatformConstants.eventTypeExperiencePlatform,
                                                   source: ExperiencePlatformConstants.eventSourceExtensionErrorResponseContent,
                                                   data: eventData)
        } else {
            responseEvent = try? ACPExtensionEvent(name: ExperiencePlatformConstants.eventNameResponseContent,
                                                   type: ExperiencePlatformConstants.eventTypeExperiencePlatform,
                                                   source: ExperiencePlatformConstants.eventSourceExtensionResponseContent,
                                                   data: eventData)
        }

        guard let unwrappedResponseEvent = responseEvent else { return }
        guard let _ = try? ACPCore.dispatchEvent(unwrappedResponseEvent) else {
            ACPCore.log(ACPMobileLogLevel.warning, tag: logTag, message: "dispatchResponseEvent - An error occurred while dispatching platform response event for request id: \(requestId)")
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
        var eventData: [String: Any] = dictionary
        eventData[ExperiencePlatformConstants.EventDataKeys.edgeRequesId] = requestId

        guard let unwrappedEventIds = requestEventIdsList, let unwrappedIndex = index, unwrappedIndex >= 0, unwrappedIndex < unwrappedEventIds.count else { return eventData }
        eventData[ExperiencePlatformConstants.EventDataKeys.requestEventId] = unwrappedEventIds[unwrappedIndex]
        return eventData
    }

    /// If handle is of type "state:store" persist it to Data Store
    /// - Parameter handle: current `EventHandle` to store
    private func handleStoreEventHandle(handle: EdgeEventHandle) {
        guard let type = handle.type, ExperiencePlatformConstants.JsonKeys.Response.eventHandleStoreType == type.lowercased() else { return }
        guard let payload: [[String: AnyCodable]] = handle.payload else { return }

        var storeResponsePayloads: [StoreResponsePayload] = []
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let jsonDecoder = JSONDecoder()
        for storeElement in payload {
            if let data = try? encoder.encode(storeElement), let storePayload = try? jsonDecoder.decode(StorePayload.self, from: data) {
                storeResponsePayloads.append(StoreResponsePayload(payload: storePayload))
            }
        }

        let dataStore = NamedUserDefaultsStore(name: ExperiencePlatformConstants.DataStoreKeys.storeName)
        let storeResponsePayloadManager = StoreResponsePayloadManager(dataStore)
        storeResponsePayloadManager.saveStorePayloads(storeResponsePayloads)
        if !storeResponsePayloads.isEmpty {
            ACPCore.log(ACPMobileLogLevel.debug, tag: logTag, message: "Processed \(storeResponsePayloads.count) store response payload(s)")
        }
    }

    /// Logs the provided `error` message with the log level set based of `isError`, as follows:
    /// - If isError is true, the message is logged as error.
    /// - If isError is false, the message is logged as warning.
    /// - Parameters:
    ///   - error: `EdgeEventError` encoded as [String: Any] containing the event error/warning coming from server
    ///   - isError: boolean indicating if this is an error message
    ///   - requestId: the event request identifier, used for logging
    private func logErrorMessage(_ error: [String: Any], isError: Bool, requestId: String) {
        let loggingMode = isError ? ACPMobileLogLevel.error : ACPMobileLogLevel.warning
        ACPCore.log(loggingMode, tag: logTag, message: "Received event error for request id (\(requestId)), error details:\n\(error as AnyObject)")
    }
}
