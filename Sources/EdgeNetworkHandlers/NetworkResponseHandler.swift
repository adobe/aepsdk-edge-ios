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

import AEPCore
import AEPServices
import Foundation

/// This class is used to process the Experience Edge network responses when the ResponseCallback is invoked with a response or error message. The response processing
/// consists in parsing the server response message and dispatching response content and/or error response content events and storing the response payload (if needed).
/// - See also: `EdgeResponse` and  `NetworkResponseCallback`
class NetworkResponseHandler {
    private let LOG_TAG = "NetworkResponseHandler"
    private let serialQueue = DispatchQueue(label: "com.adobe.edge.eventsDictionary") // serial queue for atomic operations

    // the order of the request events matter for matching them with the response events
    private var sentEventsWaitingResponse = ThreadSafeDictionary<String, [String]>()

    /// Adds the requestId in the internal `sentEventsWaitingResponse` with the associated list of events.
    /// This list should maintain the order of the received events for matching with the response event index.
    /// If the same requestId was stored before, the new list will replace the existing events.
    /// - Parameters:
    ///   - requestId: batch request id
    ///   - batchedEvents: batched events sent to ExEdge
    func addWaitingEvents(requestId: String, batchedEvents: [Event]) {
        guard !requestId.isEmpty, !batchedEvents.isEmpty else { return }

        let eventIds = batchedEvents.map { $0.id.uuidString }
        serialQueue.sync {
            if self.sentEventsWaitingResponse[requestId] != nil {
                Log.warning(label: self.LOG_TAG, "Name collision for requestId \(requestId), events list is overwritten.")
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
            Log.debug(label: LOG_TAG,
                      "processResponseOnSuccess - Received server response:\n \(jsonResponse), request id \(requestId)")

            // handle the event handles, errors and warnings coming from server
            processEventHandles(handlesArray: edgeResponse.handle, requestId: requestId)
            dispatchEventErrors(errorsArray: edgeResponse.errors, requestId: requestId)
            dispatchEventWarnings(warningsArray: edgeResponse.warnings, requestId: requestId)
        } else {
            Log.warning(label: LOG_TAG,
                        "processResponseOnSuccess - The conversion to JSON failed for server response: \(jsonResponse), request id \(requestId)")
        }
    }

    /// Decodes the response as `EdgeResponse` and extracts the errors if possible, otherwise decodes it as `EdgeEventError` and dispatches error events for the errors/warnings
    /// received from the server.
    /// - Parameters:
    ///   - jsonError: JSON formatted error response received from the server
    ///   - requestId: request id associated with current response
    func processResponseOnError(jsonError: String, requestId: String) {
        guard let data = jsonError.data(using: .utf8) else { return }

        // Attempt to decode as an `EdgeResponse` first
        guard let edgeErrorResponse = try? JSONDecoder().decode(EdgeResponse.self, from: data) else {

            // If decoding as an `EdgeResponse` fails, attempt to decode as a generic `EdgeEventError`
            if let edgeErrorResponse = try? JSONDecoder().decode(EdgeEventError.self, from: data) {
                Log.debug(label: LOG_TAG, "processResponseOnError - Processing server error response:\n \(jsonError), request id \(requestId)")
                dispatchEventErrors(errorsArray: [edgeErrorResponse], requestId: requestId)
            } else {
                Log.warning(label: LOG_TAG,
                            "processResponseOnError - The conversion to JSON failed for server error response: \(jsonError), request id \(requestId)")
            }

            return
        }

        Log.debug(label: LOG_TAG, "processResponseOnError - Processing server error response:\n \(jsonError), request id \(requestId)")

        // Note: if the Edge error doesn't have an eventIndex it means that this error is a generic request error,
        // otherwise it is an event specific error. There can be multiple errors returned for the same event
        if edgeErrorResponse.errors != nil {
            // this is an error coming from Konductor, read the error from the errors node
            dispatchEventErrors(errorsArray: edgeErrorResponse.errors, requestId: requestId)
        } else {
            // generic server error, return the error as is
            guard let genericErrorResponse = try? JSONDecoder().decode(EdgeEventError.self, from: data) else {
                Log.warning(label: LOG_TAG,
                            "processResponseOnError - The conversion to JSON failed for generic error response: \(jsonError), " +
                                "request id \(requestId)")
                return
            }

            dispatchEventErrors(errorsArray: [genericErrorResponse], requestId: requestId)
        }
    }

    /// Dispatches each event handle in the provided `handlesArray` as a separate event through the Event Hub, processes
    /// the store event handles (if any) and invokes the response handlers if they were registered before.
    /// - Parameters:
    ///   - handlesArray: `[EdgeEventHandle]` containing all the event handles to be processed; this list should not be nil/empty
    ///   - requestId: the request identifier, used for logging and to identify the request events associated with this response
    /// - See also: handleStoreEventHandle(handle: EdgeEventHandle)
    private func processEventHandles(handlesArray: [EdgeEventHandle]?, requestId: String) {
        guard let unwrappedEventHandles = handlesArray, !unwrappedEventHandles.isEmpty else {
            Log.trace(label: LOG_TAG, "processEventHandles - Received nil/empty event handle array, nothing to handle")
            return
        }

        Log.trace(label: LOG_TAG, "processEventHandles - Processing \(unwrappedEventHandles.count) event handle(s) for request id: \(requestId)")

        for eventHandle in unwrappedEventHandles {
            let requestEventId = extractRequestEventId(forEventIndex: eventHandle.eventIndex, requestId: requestId)
            handleStoreEventHandle(handle: eventHandle)

            guard let eventHandleAsDictionary = eventHandle.asDictionary() else { continue }
            dispatchResponseEvent(handleAsDictionary: eventHandleAsDictionary,
                                  requestId: requestId,
                                  requestEventId: requestEventId,
                                  eventSource: eventHandle.type)
            CompletionHandlersManager.shared.eventHandleReceived(forRequestEventId: requestEventId, eventHandle)
        }
    }

    /// Extracts the request event identifiers paired with this event handle/error handle based on the index. If no matches are found or the event handle index is missing,
    /// this method returns nil
    ///
    /// - Parameters:
    ///   - forEventIndex: the `EdgeEventHandle`/ `EdgeEventError` event index
    ///   - requestId: edge request id used to fetch the waiting events associated with it (if any)
    /// - Returns: the request event unique identifier for which this event handle was received, nil if not found
    private func extractRequestEventId(forEventIndex: Int?, requestId: String) -> String? {
        guard let requestEventIdsList = getWaitingEvents(requestId: requestId) else { return nil }

        // Note: ExEdge does not return eventIndex when there is only one event in the request.
        // The event handles and errrors are associated to that request event, so defaulting to 0 here.
        let index = forEventIndex ?? 0
        guard index >= 0, index < requestEventIdsList.count else {
            return nil
        }

        return requestEventIdsList[index]
    }

    /// Dispatches a response event with the provided event handle as `[String: Any]`, including the request event id and request identifier
    /// - Parameters:
    ///   - handleAsDictionary: represents an `EdgeEventHandle` parsed as [String:Any]
    ///   - requestId: the edge request identifier associated with this response
    ///   - requestEventId: the request event identifier for which this response event handle was received
    ///   - eventSource type of the `EdgeEventHandle`
    private func dispatchResponseEvent(handleAsDictionary: [String: Any], requestId: String, requestEventId: String?, eventSource: String?) {
        guard !handleAsDictionary.isEmpty else { return }

        // set eventRequestId and edge requestId on the response event and dispatch data
        let eventData = addEventAndRequestIdToDictionary(handleAsDictionary, requestId: requestId, requestEventId: requestEventId)
        dispatchResponseEventWithData(eventData, requestId: requestId, isErrorResponseEvent: false, eventSource: eventSource)
    }

    /// Iterates over the provided `errorsArray` and dispatches a new error event to the Event Hub.
    /// It also logs each error json with the log level error.
    /// - Parameters:
    ///   - errorsArray: `EdgeEventError` array containing all the event errors to be processed
    ///   - requestId: the event request identifier, used for logging
    /// - See Also: `logErrorMessage(_ error: [String: Any], isError: Bool, requestId: String)`
    private func dispatchEventErrors(errorsArray: [EdgeEventError]?, requestId: String) {
        guard let unwrappedErrors = errorsArray, !unwrappedErrors.isEmpty else {
            Log.trace(label: LOG_TAG, "dispatchEventErrors - Received nil/empty errors array, nothing to handle")
            return
        }

        Log.trace(label: LOG_TAG, "dispatchEventErrors - Processing \(unwrappedErrors.count) errors(s) for request id: \(requestId)")
        for error in unwrappedErrors {

            if let errorAsDictionary = error.asDictionary() {
                logErrorMessage(errorAsDictionary, isError: true, requestId: requestId)

                let requestEventId = extractRequestEventId(forEventIndex: error.eventIndex, requestId: requestId)
                // set eventRequestId and Edge requestId on the response event and dispatch data
                let eventData = addEventAndRequestIdToDictionary(errorAsDictionary,
                                                                 requestId: requestId,
                                                                 requestEventId: requestEventId)
                guard !eventData.isEmpty else { continue }
                dispatchResponseEventWithData(eventData, requestId: requestId, isErrorResponseEvent: true, eventSource: nil)
            }
        }
    }

    /// Iterates over the provided `warningsArray` and dispatches a new warning event to the Event Hub.
    /// It also logs each warning json
    /// - Parameters:
    ///   - warningsArray: `EdgeEventWarning` array containing all the event warning to be processed
    ///   - requestId: the event request identifier, used for logging
    /// - See Also: `logErrorMessage(_ error: [String: Any], isError: Bool, requestId: String)`
    private func dispatchEventWarnings(warningsArray: [EdgeEventWarning]?, requestId: String) {
        guard let unwrappedWarnings = warningsArray, !unwrappedWarnings.isEmpty else {
            Log.trace(label: LOG_TAG, "dispatchEventWarnings - Received nil/empty warnings array, nothing to handle")
            return
        }

        Log.trace(label: LOG_TAG, "dispatchEventWarnings - Processing \(unwrappedWarnings.count) warning(s) for request id: \(requestId)")
        for warning in unwrappedWarnings {

            if let warningsAsDictionary = try? warning.asDictionary() {
                logErrorMessage(warningsAsDictionary, isError: false, requestId: requestId)

                let requestEventId = extractRequestEventId(forEventIndex: warning.eventIndex, requestId: requestId)
                // set eventRequestId and Edge requestId on the response event and dispatch data
                let eventData = addEventAndRequestIdToDictionary(warningsAsDictionary,
                                                                 requestId: requestId,
                                                                 requestEventId: requestEventId)
                guard !eventData.isEmpty else { return }
                dispatchResponseEventWithData(eventData, requestId: requestId, isErrorResponseEvent: true, eventSource: nil)
            }
        }
    }

    /// Dispatched a new event with the provided `eventData` as responseContent or as errorResponseContent based on the `isErrorResponseEvent` setting
    /// - Parameters:
    ///   - eventData: Event data to be dispatched, should not be empty
    ///   - requestId: The request identifier associated with this response event, used for logging
    ///   - isErrorResponseEvent: indicates if this should be dispatched as an error or regular response content event
    ///   - eventSource: an optional `String` to be used as the event source.
    ///   If `eventSource` is nil either Constants.EventSource.ERROR_RESPONSE_CONTENT or Constants.EventSource.RESPONSE_CONTENT will be used for the event source depending on `isErrorResponseEvent`
    private func dispatchResponseEventWithData(_ eventData: [String: Any], requestId: String, isErrorResponseEvent: Bool, eventSource: String?) {
        guard !eventData.isEmpty else { return }
        var source = isErrorResponseEvent ? EdgeConstants.EventSource.ERROR_RESPONSE_CONTENT : EventSource.responseContent
        if let eventSource = eventSource, !eventSource.isEmpty {
            source = eventSource
        }

        let responseEvent = Event(name: isErrorResponseEvent ? EdgeConstants.EventName.ERROR_RESPONSE_CONTENT : EdgeConstants.EventName.RESPONSE_CONTENT,
                                  type: EventType.edge,
                                  source: source,
                                  data: eventData)

        MobileCore.dispatch(event: responseEvent)
    }

    /// Attaches the provided `requestId` and `requestEventId` (if provided) to the `dictionary` and returns the result
    /// - Parameters:
    ///   - dictionary: data coming from server (an event handle or error or warning)
    ///   - requestId: current request id to be added to data
    ///   - requestEventId: the request event id associated with this data
    private func addEventAndRequestIdToDictionary(_ dictionary: [String: Any], requestId: String, requestEventId: String?) -> [String: Any] {
        var eventData: [String: Any] = dictionary
        eventData[EdgeConstants.EventDataKeys.EDGE_REQUEST_ID] = requestId
        eventData[EdgeConstants.EventDataKeys.REQUEST_EVENT_ID] = requestEventId
        return eventData
    }

    /// If handle is of type "state:store" persist it to Data Store
    /// - Parameter handle: current `EventHandle` to store
    private func handleStoreEventHandle(handle: EdgeEventHandle) {
        guard let type = handle.type, EdgeConstants.JsonKeys.Response.EVENT_HANDLE_TYPE_STORE == type.lowercased() else { return }
        guard let payload: [[String: Any]] = handle.payload else { return }

        var storeResponsePayloads: [StoreResponsePayload] = []
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let jsonDecoder = JSONDecoder()
        for storeElement in payload {
            if let storeElementAnyCodable = AnyCodable.from(dictionary: storeElement),
               let data = try? encoder.encode(storeElementAnyCodable),
               let storePayload = try? jsonDecoder.decode(StorePayload.self, from: data) {
                storeResponsePayloads.append(StoreResponsePayload(payload: storePayload))
            }
        }

        let storeResponsePayloadManager = StoreResponsePayloadManager(EdgeConstants.DataStoreKeys.STORE_NAME)
        storeResponsePayloadManager.saveStorePayloads(storeResponsePayloads)
        if !storeResponsePayloads.isEmpty {
            Log.debug(label: LOG_TAG, "Processed \(storeResponsePayloads.count) store response payload(s)")
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
        if isError {
            Log.error(label: LOG_TAG, "Received event error for request id (\(requestId)), error details:\n\(error as AnyObject)")
        } else {
            Log.warning(label: LOG_TAG, "Received event error for request id (\(requestId)), error details:\n\(error as AnyObject)")
        }
    }
}
