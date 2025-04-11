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

@Suite("BedrockService Tests")
struct BedrockServiceTests {
    let bedrock: BedrockService

    init() async throws {
        self.bedrock = try await BedrockService(
            bedrockClient: MockBedrockClient(),
            bedrockRuntimeClient: MockBedrockRuntimeClient()
        )
    }

    // MARK: listModels

    @Test("List all models")
    func listModels() async throws {
        let models: [ModelSummary] = try await bedrock.listModels()
        #expect(models.count == 3)
        #expect(models[0].modelId == "anthropic.claude-instant-v1")
        #expect(models[0].modelName == "Claude Instant")
        #expect(models[0].providerName == "Anthropic")
    }
}

//#if PRIMARY_TEST
//    @main
//    extension BedrockServiceTests {}
//#endif
