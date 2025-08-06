//
//  MCPClient.swift
//  AafeeLib
//
//  Created by Peter Liddle on 6/23/25.
//

import MCP
import MCPHelpers

// This is to stop name conflicts with Error and Message which occur if you import the whole MCP package in other files
public typealias MCPClient = MCP.Client

typealias MCPTool = MCP.Tool

typealias MCPError = MCP.MCPError

public typealias Value = MCP.Value
