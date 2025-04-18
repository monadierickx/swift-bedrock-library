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
import Foundation

public enum Content: Codable {
    case text(String)
    case image(ImageBlock)
    case toolUse(ToolUseBlock)
    case toolResult(ToolResultBlock)
    case document(DocumentBlock)
    case video(VideoBlock)
    // case reasoningcontent(ReasoningBlock)

    public init(from sdkContentBlock: BedrockRuntimeClientTypes.ContentBlock) throws {
        switch sdkContentBlock {
        case .text(let text):
            self = .text(text)
        case .image(let sdkImage):
            self = .image(try ImageBlock(from: sdkImage))
        case .document(let sdkDocumentBlock):
            self = .document(try DocumentBlock(from: sdkDocumentBlock))
        case .tooluse(let sdkToolUseBlock):
            self = .toolUse(try ToolUseBlock(from: sdkToolUseBlock))
        case .toolresult(let sdkToolResultBlock):
            self = .toolResult(try ToolResultBlock(from: sdkToolResultBlock))
        case .video(let sdkVideoBlock):
            self = .video(try VideoBlock(from: sdkVideoBlock))
        case .sdkUnknown(let unknownContentBlock):
            throw BedrockServiceError.notImplemented(
                "ContentBlock \(unknownContentBlock) is not implemented by BedrockRuntimeClientTypes"
            )
        default:
            throw BedrockServiceError.notImplemented(
                "\(sdkContentBlock.self) is not implemented by this library"
            )
        }
    }

    public func getSDKContentBlock() throws -> BedrockRuntimeClientTypes.ContentBlock {
        switch self {
        case .text(let text):
            return BedrockRuntimeClientTypes.ContentBlock.text(text)
        case .image(let imageBlock):
            return BedrockRuntimeClientTypes.ContentBlock.image(try imageBlock.getSDKImageBlock())
        case .document(let documentBlock):
            return BedrockRuntimeClientTypes.ContentBlock.document(try documentBlock.getSDKDocumentBlock())
        case .toolResult(let toolResultBlock):
            return BedrockRuntimeClientTypes.ContentBlock.toolresult(try toolResultBlock.getSDKToolResultBlock())
        case .toolUse(let toolUseBlock):
            return BedrockRuntimeClientTypes.ContentBlock.tooluse(try toolUseBlock.getSDKToolUseBlock())
        case .video(let videoBlock):
            return BedrockRuntimeClientTypes.ContentBlock.video(try videoBlock.getSDKVideoBlock())
        // default:
        //     print("TODO")
        //     return BedrockRuntimeClientTypes.ContentBlock.text("TODO")
        }
    }
}
