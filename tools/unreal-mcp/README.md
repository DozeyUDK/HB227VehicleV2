# Unreal MCP for HB227VehicleV2

The bundled server gives coding agents targeted access to UnrealScript, Core3D sources, logs and map exports in this checkout. It uses local STDIO and Python 3.12 with the standard library. The tools have read-only access to project files. The server starts without Unreal, an SDK, Python packages or an API token.

## Cursor

1. Open the HB227VehicleV2 clone as the workspace.
2. Merge the entry from [examples/cursor.mcp.json](examples/cursor.mcp.json) into the project's .cursor/mcp.json. In a new checkout, you can copy it as the entire file.
3. Replace __REPO_ROOT__ with the full path to the clone and __PYTHON_EXE__ with the full path to Python 3.12 or newer. Use forward slashes, for example D:/Projects/HB227VehicleV2. Keep the full script path as one JSON string, including any spaces in the path.
4. Restart or reload the MCP entry and check that unreal-dev-context lists six tools.

## Codex CLI

Merge [examples/codex.config.toml](examples/codex.config.toml) into .codex/config.toml in the project or into your user config at ~/.codex/config.toml. Replace both placeholders with the same absolute paths and start a fresh session. Check the configuration with codex mcp list.

Use forward slashes in both templates. For example, the Windows executable path might be C:/Python312/python.exe. Project-local configuration is intended for your working copy.

## Agent installation

Copy this prompt into Codex or Claude Code with the clone open:

> Install `unreal-dev-context` for this checkout using the steps below. Reuse a local Python 3.12 or later interpreter and the bundled script. Preserve my other MCP entries. Verify the direct STDIO response, then call `unreal.outline` from the configured client in a fresh session. Report which config and interpreter you used, the symbol and line returned by the client, and any step that still needs my input.

### 1. Locate and test the bundled server

From the clone root, locate an installed Python interpreter. Check `python` or `python3` on PATH, an existing virtual environment, or the Windows Python launcher if present. Resolve the interpreter to its actual executable and verify that it is Python 3.12 or newer. If none is available, report the missing prerequisite. The bundled server uses the standard library.

Run this preflight with the resolved Python path. Keep the script path as one argument, including when the clone path contains spaces.

```powershell
$python = 'C:/path/to/python.exe'
$server = (Resolve-Path 'tools/unreal-mcp/run.py').Path
& $python -c 'import sys; assert sys.version_info >= (3, 12); print(sys.executable)'
if ($LASTEXITCODE -ne 0) { throw 'Python 3.12 or later is required' }
$response = '{"jsonrpc":"2.0","id":1,"method":"tools/list"}' | & $python -B $server
if ($LASTEXITCODE -ne 0) { throw 'Unreal MCP process failed' }
$reply = $response | ConvertFrom-Json
if ($reply.id -ne 1 -or @($reply.result.tools).Count -ne 6) { throw 'Unexpected MCP response' }
$reply.result.tools.name
```

### 2. Register the server for the active client

Check for a server named `unreal-dev-context` first. Reuse it if its command and arguments already point to this interpreter and checkout. If the name points to another installation, report the conflict before replacing it.

- **Codex CLI.** Merge the `[mcp_servers.unreal-dev-context]` table from [the TOML template](examples/codex.config.toml) into `.codex/config.toml` at the clone root. Replace both placeholders with the resolved absolute paths, using forward slashes on Windows. Keep all existing tables. Run `codex mcp list` from the clone and start a fresh session. If Codex requires project trust to load the config, report that prompt. [Codex MCP configuration](https://developers.openai.com/codex/mcp)
- **Claude Code.** From the clone root, run `claude mcp add --transport stdio --scope local unreal-dev-context -- "$python" -B "$server"` using the variables above. Local scope binds the entry to this checkout. Check it with `claude mcp get unreal-dev-context` and start a fresh session. [Claude Code MCP configuration](https://code.claude.com/docs/en/mcp)

### 3. Verify the connection in the client

Use the newly registered MCP tool `unreal.outline` with the following arguments. The expected result contains `QueryWheelContact` and its current source line number.

```json
{"path":"HB227VehicleV2/Classes/HB2Body.uc","match":"QueryWheelContact"}
```

Report the direct STDIO preflight and the tool call through the client as separate results. If the CLI is unavailable or the current session cannot reload tools, report client verification as pending and give the exact command or action to finish it.

## Quick test

Run these two commands from the root of the repository in PowerShell.

    $python = "C:/Python312/python.exe"
    & $python --version
    '{"jsonrpc":"2.0","id":1,"method":"tools/list"}' | & $python -B tools/unreal-mcp/run.py

The second command returns a JSON-RPC result with six tool definitions. From your agent, ask it to use unreal.task_context with topic suspension, then unreal.outline on HB227VehicleV2/Classes/HB2Body.uc to locate QueryWheelContact.

| Tool | Input example |
| --- | --- |
| unreal.task_context | {"topic":"suspension"} |
| unreal.outline | {"path":"HB227VehicleV2/Classes/HB2Body.uc","match":"QueryWheelContact"} |
| unreal.excerpt | {"path":"HB227VehicleV2/Classes/HB2Body.uc","start_line":1005,"max_lines":20} |
| unreal.search_code | {"query":"NativeStepSuspended","root":"HB227VehicleV2","max_hits":12} |
| unreal.log_digest | {"path":"logs/hb2_spire.log","max_events":15} |
| unreal.map_summary | {"path":"Maps/SpireVillage.t3d","max_actors":8} |

## Optional game files

- For Unreal logs, copy the log into logs/ or use the corresponding System/ or System64/ directory within the clone. Pass architecture x86 or x64 when using its system directory. When path is omitted, the tool checks the selected system directory for recent HB2 runtime logs.
- For map inspection, export a text .t3d from UnrealEd and save it in Maps/. An .unr file provides size and timestamp metadata. The actor and brush summary uses the T3D export.
- With local .u or DLL builds in System/ or System64/, task_context can show their sizes and hash prefixes.

The tool paths are relative to the checkout; symbolic links, junctions and paths outside it are rejected. Use the build and launch commands in the [main README](../../README.md) for compilation and play-testing. The MCP server exposes source lookup, log digests and file summaries.
