//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Foundation Models Playground open source project
//
// Copyright (c) 2025 Amazon.com, Inc. or its affiliates
//                    and the Swift Foundation Models Playground project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Swift Foundation Models Playground project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

@preconcurrency import AWSBedrockRuntime
import AwsCommonRuntimeKit
import BedrockTypes
import Foundation

extension BedrockService {

    /// Converse with a model using the Bedrock Converse API
    /// - Parameters:
    ///   - model: The BedrockModel to converse with
    ///   - conversation: Array of previous messages in the conversation
    ///   - maxTokens: Optional maximum number of tokens to generate
    ///   - temperature: Optional temperature parameter for controlling randomness
    ///   - topP: Optional top-p parameter for nucleus sampling
    ///   - stopSequences: Optional array of sequences where generation should stop
    ///   - systemPrompts: Optional array of system prompts to guide the conversation
    ///   - tools: Optional array of tools the model can use
    /// - Throws: BedrockServiceError.notSupported for parameters or functionalities that are not supported
    ///           BedrockServiceError.invalidParameter for invalid parameters
    ///           BedrockServiceError.invalidPrompt if the prompt is empty or too long
    ///           BedrockServiceError.invalidModality for invalid modality from the selected model
    ///           BedrockServiceError.invalidSDKResponse if the response body is missing
    /// - Returns: A Message containing the model's response
    public func converse(
        with model: BedrockModel,
        conversation: [Message],
        maxTokens: Int? = nil,
        temperature: Double? = nil,
        topP: Double? = nil,
        stopSequences: [String]? = nil,
        systemPrompts: [String]? = nil,
        tools: [Tool]? = nil
    ) async throws -> Message {
        do {
            let modality: ConverseModality = try model.getConverseModality()
            try validateConverseParams(
                modality: modality,
                maxTokens: maxTokens,
                temperature: temperature,
                topP: topP,
                stopSequences: stopSequences
            )

            logger.trace(
                "Creating ConverseRequest",
                metadata: [
                    "model.name": "\(model.name)",
                    "model.id": "\(model.id)",
                    "conversation.count": "\(conversation.count)",
                    "maxToken": "\(String(describing: maxTokens))",
                    "temperature": "\(String(describing: temperature))",
                    "topP": "\(String(describing: topP))",
                    "stopSequences": "\(String(describing: stopSequences))",
                    "systemPrompts": "\(String(describing: systemPrompts))",
                    "tools": "\(String(describing: tools))",
                ]
            )
            let converseRequest = ConverseRequest(
                model: model,
                messages: conversation,
                maxTokens: maxTokens,
                temperature: temperature,
                topP: topP,
                stopSequences: stopSequences,
                systemPrompts: systemPrompts,
                tools: tools
            )

            logger.trace("Creating ConverseInput")
            let input = try converseRequest.getConverseInput()
            logger.trace(
                "Created ConverseInput",
                metadata: [
                    "input.messages.count": "\(String(describing:input.messages!.count))",
                    "input.modelId": "\(String(describing:input.modelId!))",
                ]
            )

            let response = try await self.bedrockRuntimeClient.converse(input: input)
            logger.trace("Received response", metadata: ["response": "\(response)"])

            guard let converseOutput = response.output else {
                logger.trace(
                    "Invalid response",
                    metadata: [
                        "response": .string(String(describing: response)),
                        "hasOutput": .stringConvertible(response.output != nil),
                    ]
                )
                throw BedrockServiceError.invalidSDKResponse(
                    "Something went wrong while extracting ConverseOutput from response."
                )
            }
            let converseResponse = try ConverseResponse(converseOutput)
            return converseResponse.message
        } catch {
            try handleCommonError(error, context: "listing foundation models")
            throw BedrockServiceError.unknownError("\(error)")  // FIXME: handleCommonError will always throw
        }
    }

    /// Use Converse API without needing to make Messages
    /// - Parameters:
    ///   - model: The BedrockModel to converse with
    ///   - prompt: Optional text prompt for the conversation
    ///   - image: ImageBlock to include in the message
    ///   - history: Optional array of previous messages
    ///   - maxTokens: Optional maximum number of tokens to generate
    ///   - temperature: Optional temperature parameter for controlling randomness
    ///   - topP: Optional top-p parameter for nucleus sampling
    ///   - stopSequences: Optional array of sequences where generation should stop
    ///   - systemPrompts: Optional array of system prompts to guide the conversation
    ///   - tools: Optional array of tools the model can use
    ///   - toolResult: Optional result from a previous tool invocation
    /// - Throws: BedrockServiceError.notSupported for parameters or functionalities that are not supported
    ///           BedrockServiceError.invalidParameter for invalid parameters
    ///           BedrockServiceError.invalidPrompt if the prompt is empty or too long
    ///           BedrockServiceError.invalidModality for invalid modality from the selected model
    ///           BedrockServiceError.invalidSDKResponse if the response body is missing
    /// - Returns: A ConverseReply object
    public func converse(
        with model: BedrockModel,
        prompt: String? = nil,
        image: ImageBlock? = nil,
        document: DocumentBlock? = nil,
        history: inout [Message],
        maxTokens: Int? = nil,
        temperature: Double? = nil,
        topP: Double? = nil,
        stopSequences: [String]? = nil,
        systemPrompts: [String]? = nil,
        tools: [Tool]? = nil,
        toolResult: ToolResultBlock? = nil
    ) async throws -> ConverseReply {
        logger.trace(
            "Conversing",
            metadata: [
                "model.id": .string(model.id),
                "model.modality": .string(model.modality.getName()),
                "prompt": .string(prompt ?? "No prompt"),
            ]
        )
        do {
            let modality: ConverseModality = try model.getConverseModality()

            try validateConverseParams(modality: modality, prompt: prompt)

            if tools != nil || toolResult != nil {
                guard model.hasConverseModality(.toolUse) else {
                    throw BedrockServiceError.invalidModality(
                        model,
                        modality,
                        "This model does not support converse tool."
                    )
                }
            }

            var content: [Content] = []

            // tool result
            if let toolResult {
                guard let _ = tools else {
                    throw BedrockServiceError.invalidPrompt("Tool result is defined but tools are not.")
                }
                guard case .toolUse(_) = history.last?.content.last else {
                    throw BedrockServiceError.invalidPrompt("Tool result is defined but last message is not tool use.")
                }
                content.append(.toolResult(toolResult))
            } else {
                // text prompt
                guard let prompt = prompt else {
                    throw BedrockServiceError.invalidPrompt("Prompt is not defined.")
                }
                content.append(.text(prompt))

                // image prompt
                if let image {
                    guard model.hasConverseModality(.vision) else {
                        throw BedrockServiceError.invalidModality(
                            model,
                            modality,
                            "This model does not support converse vision."
                        )
                    }
                    content.append(.image(image))
                }

                // document prompt
                if let document {
                    guard model.hasConverseModality(.document) else {
                        throw BedrockServiceError.invalidModality(
                            model,
                            modality,
                            "This model does not support converse document."
                        )
                    }
                    content.append(.document(document))
                }
            }

            history.append(Message(from: .user, content: content))

            let assistantMessage = try await converse(
                with: model,
                conversation: history,
                maxTokens: maxTokens,
                temperature: temperature,
                topP: topP,
                stopSequences: stopSequences,
                systemPrompts: systemPrompts,
                tools: tools
            )

            history.append(assistantMessage)

            logger.trace(
                "Received message",
                metadata: ["replyMessage": "\(assistantMessage)", "history.count": "\(history.count)"]
            )
            return try ConverseReply(history)
        } catch {
            logger.trace("Error while conversing", metadata: ["error": "\(error)"])
            throw error
        }
    }

    /// Use Converse API without needing to make Messages
    /// - Parameters:
    ///   - model: The BedrockModel to converse with
    ///   - prompt: Optional text prompt for the conversation
    ///   - image: ImageBlock to include in the message
    ///   - history: Array of previous messages that will be updated with the new conversation
    ///   - maxTokens: Optional maximum number of tokens to generate
    ///   - temperature: Optional temperature parameter for controlling randomness
    ///   - topP: Optional top-p parameter for nucleus sampling
    ///   - stopSequences: Optional array of sequences where generation should stop
    ///   - systemPrompts: Optional array of system prompts to guide the conversation
    ///   - tools: Optional array of tools the model can use
    ///   - toolResult: Optional result from a previous tool invocation
    /// - Throws: BedrockServiceError.notSupported for parameters or functionalities that are not supported
    ///           BedrockServiceError.invalidParameter for invalid parameters
    ///           BedrockServiceError.invalidPrompt if the prompt is empty or too long
    ///           BedrockServiceError.invalidModality for invalid modality from the selected model
    ///           BedrockServiceError.invalidSDKResponse if the response body is missing
    /// - Returns: A ConverseReply object
    public func converse(
        with model: BedrockModel,
        prompt: String? = nil,
        image: ImageBlock? = nil,
        document: DocumentBlock? = nil,
        history: [Message]? = [],
        maxTokens: Int? = nil,
        temperature: Double? = nil,
        topP: Double? = nil,
        stopSequences: [String]? = nil,
        systemPrompts: [String]? = nil,
        tools: [Tool]? = nil,
        toolResult: ToolResultBlock? = nil
    ) async throws -> ConverseReply {
        var history = history ?? []
        return try await converse(
            with: model,
            prompt: prompt,
            image: image,
            document: document,
            history: &history,
            maxTokens: maxTokens,
            temperature: temperature,
            topP: topP,
            stopSequences: stopSequences,
            systemPrompts: systemPrompts,
            tools: tools,
            toolResult: toolResult
        )
    }

    /// Use Converse API without needing to make Messages
    /// - Parameters:
    ///   - model: The BedrockModel to converse with
    ///   - prompt: Optional text prompt for the conversation
    ///   - imageFormat: Optional format for image input
    ///   - imageBytes: Optional base64 encoded image data
    ///   - history: Optional array of previous messages
    ///   - maxTokens: Optional maximum number of tokens to generate
    ///   - temperature: Optional temperature parameter for controlling randomness
    ///   - topP: Optional top-p parameter for nucleus sampling
    ///   - stopSequences: Optional array of sequences where generation should stop
    ///   - systemPrompts: Optional array of system prompts to guide the conversation
    ///   - tools: Optional array of tools the model can use
    ///   - toolResult: Optional result from a previous tool invocation
    /// - Throws: BedrockServiceError.notSupported for parameters or functionalities that are not supported
    ///           BedrockServiceError.invalidParameter for invalid parameters
    ///           BedrockServiceError.invalidPrompt if the prompt is empty or too long
    ///           BedrockServiceError.invalidModality for invalid modality from the selected model
    ///           BedrockServiceError.invalidSDKResponse if the response body is missing
    /// - Returns: A ConverseReply object
    public func converse(
        with model: BedrockModel,
        prompt: String? = nil,
        imageFormat: ImageBlock.Format,
        imageBytes: String,
        history: inout [Message],
        maxTokens: Int? = nil,
        temperature: Double? = nil,
        topP: Double? = nil,
        stopSequences: [String]? = nil,
        systemPrompts: [String]? = nil,
        tools: [Tool]? = nil,
        toolResult: ToolResultBlock? = nil
    ) async throws -> ConverseReply {
        try await converse(
            with: model,
            prompt: prompt,
            image: ImageBlock(format: imageFormat, source: imageBytes),
            history: &history,
            maxTokens: maxTokens,
            temperature: temperature,
            topP: topP,
            stopSequences: stopSequences,
            systemPrompts: systemPrompts,
            tools: tools,
            toolResult: toolResult
        )
    }
}
