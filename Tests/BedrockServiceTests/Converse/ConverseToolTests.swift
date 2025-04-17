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
        let builder = try ConverseBuilder(model: BedrockModel.nova_lite)
            .withPrompt("Use tool")
            .withTool(tool)
        let reply = try await bedrock.converse(with: builder)
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

    @Test("Request tool usage with inout builder")
    func converseToolWithInOutBuilder() async throws {
        let tool = try Tool(name: "toolName", inputSchema: JSON(["code": "string"]), description: "toolDescription")
        var builder = try ConverseBuilder(model: BedrockModel.nova_lite)
            .withPrompt("Use tool")
            .withTool(tool)
        #expect(builder.prompt != nil)
        #expect(builder.prompt! == "Use tool")
        let reply = try await bedrock.converse(with: &builder)
        #expect(reply.textReply == nil)
        #expect(builder.prompt == nil)
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

    @Test("Add tool with invalid model")
    func converseToolWrongModel() async throws {
        #expect(throws: BedrockServiceError.self) {
            let tool = try Tool(name: "toolName", inputSchema: JSON(["code": "string"]), description: "toolDescription")
            let _ = try ConverseBuilder(model: BedrockModel.titan_text_g1_express)
                .withTool(tool)
        }
    }

    @Test("No tool request without tools")
    func converseToolWithoutTools() async throws {
        let builder = try ConverseBuilder(model: BedrockModel.nova_lite)
            .withPrompt("Use tool")
        let reply = try await bedrock.converse(with: builder)
        #expect(reply.textReply != nil)
        #expect(reply.toolUse == nil)
    }

    @Test("Tool result")
    func converseToolResult() async throws {
        let tool = try Tool(name: "toolName", inputSchema: JSON(["code": "string"]), description: "toolDescription")
        let id = "toolId"
        let toolUse = ToolUseBlock(id: id, name: "toolName", input: JSON(["code": "abc"]))
        let history = [Message("Use tool"), Message(toolUse)]

        let builder = try ConverseBuilder(model: BedrockModel.nova_lite)
            .withHistory(history)
            .withTool(tool)
            .withToolResult("Information from tool")

        let reply = try await bedrock.converse(with: builder)
        #expect(reply.toolUse == nil)
        #expect(reply.textReply == "Tool result received")
    }

    @Test("Tool result with inout builder")
    func converseToolResultWithInOutBuilder() async throws {
        let tool = try Tool(name: "toolName", inputSchema: JSON(["code": "string"]), description: "toolDescription")
        let id = "toolId"
        let toolUse = ToolUseBlock(id: id, name: "toolName", input: JSON(["code": "abc"]))
        let history = [Message("Use tool"), Message(toolUse)]

        var builder = try ConverseBuilder(model: BedrockModel.nova_lite)
            .withHistory(history)
            .withTool(tool)
            .withToolResult("Information from tool")
        #expect(builder.toolResult != nil)
        let reply = try await bedrock.converse(with: &builder)
        #expect(reply.toolUse == nil)
        #expect(reply.textReply == "Tool result received")
        #expect(builder.toolResult == nil)
    }

    @Test("Tool result without toolUse")
    func converseToolResultWithoutToolUse() async throws {
        let tool = try Tool(name: "toolName", inputSchema: JSON(["code": "string"]), description: "toolDescription")
        let id = "toolId"
        let history = [Message("Use tool"), Message(from: .assistant, content: [.text("No need for a tool")])]
        #expect(throws: BedrockServiceError.self) {
            let _ = try ConverseBuilder(model: BedrockModel.nova_lite)
                .withHistory(history)
                .withTool(tool)
                .withToolResult("Information from tool", id: id)
        }
    }

    @Test("Tool result without tools")
    func converseToolResultWithoutTools() async throws {
        let id = "toolId"
        let toolUse = ToolUseBlock(id: id, name: "toolName", input: JSON(["code": "abc"]))
        let history = [Message("Use tool"), Message(toolUse)]
        #expect(throws: BedrockServiceError.self) {
            let _ = try ConverseBuilder(model: BedrockModel.nova_lite)
                .withHistory(history)
                .withToolResult("Information from tool")
        }
    }

    @Test("Tool result with invalid model")
    func converseToolResultInvalidModel() async throws {
        let tool = try Tool(name: "toolName", inputSchema: JSON(["code": "string"]), description: "toolDescription")
        let id = "toolId"
        let toolUse = ToolUseBlock(id: id, name: "toolName", input: JSON(["code": "abc"]))
        let history = [Message("Use tool"), Message(toolUse)]
        #expect(throws: BedrockServiceError.self) {
            let _ = try ConverseBuilder(model: BedrockModel.titan_text_g1_express)
                .withHistory(history)
                .withTool(tool)
                .withToolResult("Information from tool")
        }
    }

    @Test("Tool result with invalid model without tools")
    func converseToolResultInvalidModelWithoutTools() async throws {
        let id = "toolId"
        let toolUse = ToolUseBlock(id: id, name: "toolName", input: JSON(["code": "abc"]))
        let history = [Message("Use tool"), Message(toolUse)]

        #expect(throws: BedrockServiceError.self) {
            let _ = try ConverseBuilder(model: BedrockModel.titan_text_g1_express)
                .withHistory(history)
                .withToolResult("Information from tool")
        }
    }

    @Test("Tool result with invalid model without toolUse")
    func converseToolResultInvalidModelWithoutToolUse() async throws {
        let tool = try Tool(name: "toolName", inputSchema: JSON(["code": "string"]), description: "toolDescription")
        let history = [Message("Use tool"), Message(from: .assistant, content: [.text("No need for a tool")])]

        #expect(throws: BedrockServiceError.self) {
            let _ = try ConverseBuilder(model: BedrockModel.titan_text_g1_express)
                .withHistory(history)
                .withTool(tool)
                .withToolResult("Information from tool")
        }
    }

    @Test("Tool result with invalid model without toolUse and without tools")
    func converseToolResultInvalidModelWithoutToolUseAndTools() async throws {
        let history = [Message("Use tool"), Message(from: .assistant, content: [.text("No need for a tool")])]
        #expect(throws: BedrockServiceError.self) {
            let _ = try ConverseBuilder(model: BedrockModel.titan_text_g1_express)
                .withHistory(history)
                .withToolResult("Information from tool")
        }
    }
}
