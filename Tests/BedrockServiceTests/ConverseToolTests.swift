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

// Converse tools

extension BedrockServiceTests {

    @Test("Request tool usage")
    func converseRequestTool() async throws {
        let tool = try Tool(name: "toolName", inputSchema: JSON(["code": "string"]), description: "toolDescription")
        let reply = try await bedrock.converse(
            with: BedrockModel.nova_lite,
            prompt: "Use tool",
            tools: [tool]
        )
        #expect(reply.textReply == nil)
        let id: String
        let name: String
        let input: JSON
        if let toolUse = reply.toolUse {
            id = toolUse.id
            name = toolUse.name
            input = toolUse.input
        } else {
            id = ""
            name = ""
            input = JSON(["code": "wrong"])
        }
        #expect(id == "toolId")
        #expect(name == "toolName")
        #expect(input.getValue("code") == "abc")
    }

    @Test("Request tool usage with invalid model")
    func converseRequestToolWrongModel() async throws {
        let tool = try Tool(name: "toolName", inputSchema: JSON(["code": "string"]), description: "toolDescription")
        await #expect(throws: BedrockServiceError.self) {
            let _ = try await bedrock.converse(
                with: BedrockModel.titan_text_g1_express,
                prompt: "Use tool",
                tools: [tool]
            )
        }
    }

    @Test("No tool request without tools")
    func converseRequestToolWithoutTools() async throws {
        let reply = try await bedrock.converse(
            with: BedrockModel.nova_lite,
            prompt: "Use tool"
        )
        #expect(reply.textReply != nil)
        #expect(reply.toolUse == nil)
    }

    @Test("Tool result")
    func converseToolResult() async throws {
        let tool = try Tool(name: "toolName", inputSchema: JSON(["code": "string"]), description: "toolDescription")
        let id = "toolId"
        let toolUse = ToolUseBlock(id: id, name: "toolName", input: JSON(["code": "abc"]))
        var history = [Message("Use tool"), Message(toolUse)]

        let reply = try await bedrock.converse(
            with: BedrockModel.nova_lite,
            history: &history,
            tools: [tool],
            toolResult: ToolResultBlock("Information from tool", id: id)
        )
        #expect(reply.toolUse == nil)
        #expect(reply.textReply == "Tool result received")
    }

    @Test("Tool result without toolUse")
    func converseToolResultWithoutToolUse() async throws {
        let tool = try Tool(name: "toolName", inputSchema: JSON(["code": "string"]), description: "toolDescription")
        let id = "toolId"
        var history = [Message("Use tool"), Message(from: .assistant, content: [.text("No need for a tool")])]
        await #expect(throws: BedrockServiceError.self) {
            let _ = try await bedrock.converse(
                with: BedrockModel.nova_lite,
                history: &history,
                tools: [tool],
                toolResult: ToolResultBlock("Information from tool", id: id)
            )
        }
    }

    @Test("Tool result without tools")
    func converseToolResultWithoutTools() async throws {
        let id = "toolId"
        let toolUse = ToolUseBlock(id: id, name: "toolName", input: JSON(["code": "abc"]))
        var history = [Message("Use tool"), Message(toolUse)]
        await #expect(throws: BedrockServiceError.self) {
            let _ = try await bedrock.converse(
                with: BedrockModel.nova_lite,
                history: &history,
                toolResult: ToolResultBlock("Information from tool", id: id)
            )
        }
    }

    @Test("Tool result with invalid model")
    func converseToolResultInvalidModel() async throws {
        let tool = try Tool(name: "toolName", inputSchema: JSON(["code": "string"]), description: "toolDescription")
        let id = "toolId"
        let toolUse = ToolUseBlock(id: id, name: "toolName", input: JSON(["code": "abc"]))
        var history = [Message("Use tool"), Message(toolUse)]

        await #expect(throws: BedrockServiceError.self) {
            let _ = try await bedrock.converse(
                with: BedrockModel.titan_text_g1_express,
                history: &history,
                tools: [tool],
                toolResult: ToolResultBlock("Information from tool", id: id)
            )
        }
    }

    @Test("Tool result with invalid model without tools")
    func converseToolResultInvalidModelWithoutTools() async throws {
        let id = "toolId"
        let toolUse = ToolUseBlock(id: id, name: "toolName", input: JSON(["code": "abc"]))
        var history = [Message("Use tool"), Message(toolUse)]

        await #expect(throws: BedrockServiceError.self) {
            let _ = try await bedrock.converse(
                with: BedrockModel.titan_text_g1_express,
                history: &history,
                toolResult: ToolResultBlock("Information from tool", id: id)
            )
        }
    }

    @Test("Tool result with invalid model without toolUse")
    func converseToolResultInvalidModelWithoutToolUse() async throws {
        let tool = try Tool(name: "toolName", inputSchema: JSON(["code": "string"]), description: "toolDescription")
        let id = "toolId"
        var history = [Message("Use tool"), Message(from: .assistant, content: [.text("No need for a tool")])]

        await #expect(throws: BedrockServiceError.self) {
            let _ = try await bedrock.converse(
                with: BedrockModel.titan_text_g1_express,
                history: &history,
                tools: [tool],
                toolResult: ToolResultBlock("Information from tool", id: id)
            )
        }
    }

    @Test("Tool result with invalid model without toolUse and without tools")
    func converseToolResultInvalidModelWithoutToolUseAndTools() async throws {
        var history = [Message("Use tool"), Message(from: .assistant, content: [.text("No need for a tool")])]
        await #expect(throws: BedrockServiceError.self) {
            let _ = try await bedrock.converse(
                with: BedrockModel.titan_text_g1_express,
                history: &history,
                toolResult: ToolResultBlock("Information from tool", id: "toolId")
            )
        }
    }
}
