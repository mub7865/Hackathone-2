#!/usr/bin/env python
"""MCP Server runner for stdio transport.

This script runs the MCP Server using stdio transport, which allows
the OpenAI Agents SDK to connect via MCPServerStdio.

Usage:
    python run_mcp_server.py

The server reads from stdin and writes to stdout, following the
MCP protocol for tool discovery and invocation.
"""

import sys
import os

# Add the app directory to path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from app.services.mcp_server import mcp


if __name__ == "__main__":
    # Run MCP Server with stdio transport
    mcp.run(transport="stdio")
