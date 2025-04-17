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

import Testing

@testable import BedrockService
@testable import BedrockTypes

// Converse text

extension BedrockServiceTests {

    // Prompt
    @Test(
        "Continue conversation using a valid prompt",
        arguments: NovaTestConstants.TextGeneration.validPrompts
    )
    func converseWithValidPrompt(prompt: String) async throws {
        let builder = try ConverseBuilder(model: BedrockModel.nova_micro)
            .withPrompt(prompt)
        let output = try await bedrock.converse(with: builder)
        #expect(output.textReply == "Your prompt was: \(prompt)")
    }

    @Test(
        "Continue conversation using a valid prompt and inout builder",
        arguments: NovaTestConstants.TextGeneration.validPrompts
    )
    func converseWithValidPromptAndInOutBuilder(prompt: String) async throws {
        var builder = try ConverseBuilder(model: BedrockModel.nova_micro)
            .withPrompt(prompt)
        #expect(builder.prompt == prompt)
        var output = try await bedrock.converse(with: &builder)
        #expect(output.textReply == "Your prompt was: \(prompt)")
        #expect(builder.prompt == nil)

        try builder.setPrompt("New prompt")
        #expect(builder.prompt == "New prompt")

        output = try await bedrock.converse(with: &builder)
        #expect(output.textReply == "Your prompt was: New prompt")
    }

    @Test("Continue conversation using inout builder")
    func converseWithInOutBuilder() async throws {
        var builder = try ConverseBuilder(model: BedrockModel.nova_micro)
            .withPrompt("First prompt")
            .withMaxTokens(100)
            .withTemperature(0.5)
            .withTopP(0.5)
            .withStopSequence("\n\nHuman:")
            .withSystemPrompt("You are a helpful assistant.")

        #expect(builder.prompt == "First prompt")
        #expect(builder.maxTokens == 100)
        #expect(builder.temperature == 0.5)
        #expect(builder.topP == 0.5)
        #expect(builder.stopSequences == ["\n\nHuman:"])
        #expect(builder.systemPrompts == ["You are a helpful assistant."])

        var output = try await bedrock.converse(with: &builder)
        #expect(output.textReply == "Your prompt was: First prompt")
        #expect(builder.prompt == nil)
        #expect(builder.maxTokens == 100)
        #expect(builder.temperature == 0.5)
        #expect(builder.topP == 0.5)
        #expect(builder.stopSequences == ["\n\nHuman:"])
        #expect(builder.systemPrompts == ["You are a helpful assistant."])
        #expect(builder.history.count == 2)

        try builder.setPrompt("Second prompt")
        #expect(builder.prompt == "Second prompt")

        output = try await bedrock.converse(with: &builder)
        #expect(output.textReply == "Your prompt was: Second prompt")
        #expect(builder.prompt == nil)
        #expect(builder.maxTokens == 100)
        #expect(builder.temperature == 0.5)
        #expect(builder.topP == 0.5)
        #expect(builder.stopSequences == ["\n\nHuman:"])
        #expect(builder.systemPrompts == ["You are a helpful assistant."])
        #expect(builder.history.count == 4)

        try builder.setPrompt("Second prompt")
        try builder.setTemperature(1)
        #expect(builder.prompt == "Second prompt")
        #expect(builder.temperature == 1)

        output = try await bedrock.converse(with: &builder)
        #expect(output.textReply == "Your prompt was: Second prompt")
        #expect(builder.prompt == nil)
        #expect(builder.maxTokens == 100)
        #expect(builder.temperature == 1)
        #expect(builder.topP == 0.5)
        #expect(builder.stopSequences == ["\n\nHuman:"])
        #expect(builder.systemPrompts == ["You are a helpful assistant."])
        #expect(builder.history.count == 6)
    }

    @Test(
        "Continue conversation variation using an invalid prompt",
        arguments: NovaTestConstants.TextGeneration.invalidPrompts
    )
    func converseWithInvalidPrompt(prompt: String) async throws {
        await #expect(throws: BedrockServiceError.self) {
            let builder = try ConverseBuilder(model: BedrockModel.nova_micro)
                .withPrompt(prompt)
            let _ = try await bedrock.converse(with: builder)
        }
    }

    // Temperature
    @Test(
        "Continue conversation using a valid temperature",
        arguments: NovaTestConstants.TextGeneration.validTemperature
    )
    func converseWithValidTemperature(temperature: Double) async throws {
        let prompt = "This is a test"
        let builder = try ConverseBuilder(model: BedrockModel.nova_micro)
            .withPrompt(prompt)
            .withTemperature(temperature)
        let output = try await bedrock.converse(with: builder)
        #expect(output.textReply == "Your prompt was: \(prompt)")
    }

    @Test(
        "Continue conversation variation using an invalid temperature",
        arguments: NovaTestConstants.TextGeneration.invalidTemperature
    )
    func converseWithInvalidTemperature(temperature: Double) async throws {
        await #expect(throws: BedrockServiceError.self) {
            let prompt = "This is a test"
            let builder = try ConverseBuilder(model: BedrockModel.nova_micro)
                .withPrompt(prompt)
                .withTemperature(temperature)
            let _ = try await bedrock.converse(with: builder)
        }
    }

    // MaxTokens
    @Test(
        "Continue conversation using a valid maxTokens",
        arguments: NovaTestConstants.TextGeneration.validMaxTokens
    )
    func converseWithValidMaxTokens(maxTokens: Int) async throws {
        let prompt = "This is a test"
        let builder = try ConverseBuilder(model: BedrockModel.nova_micro)
            .withPrompt(prompt)
            .withMaxTokens(maxTokens)
        let output = try await bedrock.converse(with: builder)
        #expect(output.textReply == "Your prompt was: \(prompt)")
    }

    @Test(
        "Continue conversation variation using an invalid maxTokens",
        arguments: NovaTestConstants.TextGeneration.invalidMaxTokens
    )
    func converseWithInvalidMaxTokens(maxTokens: Int) async throws {
        await #expect(throws: BedrockServiceError.self) {
            let prompt = "This is a test"
            let builder = try ConverseBuilder(model: BedrockModel.nova_micro)
                .withPrompt(prompt)
                .withMaxTokens(maxTokens)
            let _ = try await bedrock.converse(with: builder)
        }
    }

    // TopP
    @Test(
        "Continue conversation using a valid temperature",
        arguments: NovaTestConstants.TextGeneration.validTopP
    )
    func converseWithValidTopP(topP: Double) async throws {
        let prompt = "This is a test"
        let builder = try ConverseBuilder(model: BedrockModel.nova_micro)
            .withPrompt(prompt)
            .withTopP(topP)
        let output = try await bedrock.converse(with: builder)
        #expect(output.textReply == "Your prompt was: \(prompt)")
    }

    @Test(
        "Continue conversation variation using an invalid temperature",
        arguments: NovaTestConstants.TextGeneration.invalidTopP
    )
    func converseWithInvalidTopP(topP: Double) async throws {
        await #expect(throws: BedrockServiceError.self) {
            let prompt = "This is a test"
            let builder = try ConverseBuilder(model: BedrockModel.nova_micro)
                .withPrompt(prompt)
                .withTopP(topP)
            let _ = try await bedrock.converse(with: builder)
        }
    }

    // StopSequences
    @Test(
        "Continue conversation using a valid stopSequences",
        arguments: NovaTestConstants.TextGeneration.validStopSequences
    )
    func converseWithValidTopK(stopSequences: [String]) async throws {
        let prompt = "This is a test"
        let builder = try ConverseBuilder(model: BedrockModel.nova_micro)
            .withPrompt(prompt)
            .withStopSequences(stopSequences)
        let output = try await bedrock.converse(with: builder)
        #expect(output.textReply == "Your prompt was: \(prompt)")
    }
}
