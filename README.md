# FytcAgentBase

The foundation package for the FytcAgents framework. Defines the shared
abstract type hierarchy, the LLM/tool/memory/event interfaces, error types,
and configuration helpers.

**Dependencies:** Julia stdlib only (`Dates`, `Logging`, `UUIDs`) — no
third-party packages, by design.

## Key types

| Type | Purpose |
|------|---------|
| `AbstractLLMProvider` | Supertype for all LLM providers |
| `AbstractLLMResponse` | Supertype for all LLM responses |
| `LLMResponse` | Default response (Chat Completions shape) |
| `AbstractTool` | Supertype for callable tools |
| `ToolSpec` | Provider-facing tool description (JSON schema) |
| `Message` | Chat message (`:system`, `:user`, `:assistant`, `:tool`) |
| `ToolCall` | A tool invocation request from an LLM |
| `TokenUsage` | Token accounting (prompt, completion, total) |
| `EventBus` | Synchronous event bus with failure isolation |
| `AbstractMemory` | Supertype for memory backends |
| `MockLLM` | Scripted LLM for tests and examples |

## Interface functions

**LLM:** `call(llm, messages; tools)`, `stream(llm, messages; kwargs...)`

**Response accessors:** `content(r)`, `tool_calls(r)`, `usage(r)`,
`finish_reason(r)`, `raw(r)`

**Tools:** `spec(tool)`, `execute(tools, call)`, `@tool "desc" function f(x::T) ... end`

**Memory:** `remember!(mem, content; key)`, `recall(mem, query; limit)`, `reset!(mem)`

**Events:** `subscribe!(bus, listener)`, `emit!(bus, event)`

**Config:** `getconfig("key")` reads `FYTC_KEY` environment variables

## Quick example

```julia
using FytcAgentBase

# Define a tool
greet = @tool "Greet someone." function greet(name::String)
    "Hello, $name!"
end

# Use MockLLM to test without network
llm = MockLLM([
    LLMResponse(; tool_calls = [ToolCall("c1", "greet", Dict("name" => "World"))]),
    LLMResponse("Hello, World!"),
])

# Tool round-trip
response = call(llm, [Message(:user, "Say hi")]; tools = map(spec, [greet]))
for tc in tool_calls(response)
    println(execute([greet], tc))  # "Hello, World!"
end
```
