"""
    llm/LLM.jl

The language-model interface. Providers subtype [`AbstractLLMProvider`](@ref) and
specialize [`call`](@ref); the return value is an
[`AbstractLLMResponse`](@ref) whose standard accessors ([`content`](@ref),
[`tool_calls`](@ref), [`usage`](@ref), [`finish_reason`](@ref), [`raw`](@ref))
are defined here.
"""

"""
    TokenUsage(; prompt = 0, completion = 0)

Token accounting for one LLM call. `total` defaults to `prompt + completion`.
"""
struct TokenUsage
    prompt_tokens::Int
    completion_tokens::Int
    total_tokens::Int
end
TokenUsage(; prompt::Integer = 0, completion::Integer = 0) =
    TokenUsage(prompt, completion, prompt + completion)

# --------------------------------------------------------------------------
# AbstractLLMResponse accessor interface
# --------------------------------------------------------------------------

"""
    content(r::AbstractLLMResponse) -> String

The assistant text from an LLM response. **Required** accessor.
"""
content(r::AbstractLLMResponse) =
    throw(MethodError(content, (r,)))

"""
    tool_calls(r::AbstractLLMResponse) -> Vector{ToolCall}

The tool-call requests emitted by the model. **Required** accessor.
"""
tool_calls(r::AbstractLLMResponse) =
    throw(MethodError(tool_calls, (r,)))

"""
    usage(r::AbstractLLMResponse) -> TokenUsage

Token usage for this call. **Required** accessor.
"""
usage(r::AbstractLLMResponse) =
    throw(MethodError(usage, (r,)))

"""
    finish_reason(r::AbstractLLMResponse) -> Union{Nothing,String}

The provider's reason for stopping generation. **Optional** — returns
`nothing` by default. The vocabulary is provider-specific and intentionally
not normalized (e.g. Chat Completions: `"stop"`/`"length"`/`"tool_calls"`;
Responses API: `"completed"`/`"incomplete"`; Anthropic: `"end_turn"`).
"""
finish_reason(r::AbstractLLMResponse) = nothing

"""
    raw(r::AbstractLLMResponse) -> Any

The provider's original parsed payload, for debugging. **Optional** — returns
`nothing` by default.
"""
raw(r::AbstractLLMResponse) = nothing

# --------------------------------------------------------------------------
# LLMResponse — the default concrete response (Chat Completions shape)
# --------------------------------------------------------------------------

"""
    LLMResponse(content; tool_calls = ToolCall[], usage = TokenUsage(),
                raw = nothing, finish_reason = nothing) <: AbstractLLMResponse

The default concrete [`AbstractLLMResponse`](@ref), returned by providers
speaking the Chat Completions protocol. `content` is the assistant text
(possibly empty when the model only requests tools); `tool_calls` holds any
requested [`ToolCall`](@ref)s; `raw` may carry the provider's original payload;
`finish_reason` is the provider's reason for stopping (e.g. `"stop"`,
`"length"`, `"tool_calls"`) or `nothing` when unknown.
"""
struct LLMResponse <: AbstractLLMResponse
    content::String
    tool_calls::Vector{ToolCall}
    usage::TokenUsage
    raw::Any
    finish_reason::Union{Nothing,String}
end
LLMResponse(
    content::AbstractString = "";
    tool_calls::AbstractVector{ToolCall} = ToolCall[],
    usage::TokenUsage = TokenUsage(),
    raw = nothing,
    finish_reason::Union{Nothing,AbstractString} = nothing,
) = LLMResponse(
    String(content),
    collect(ToolCall, tool_calls),
    usage,
    raw,
    finish_reason === nothing ? nothing : String(finish_reason),
)

# LLMResponse accessor specializations (direct field passthrough).
content(r::LLMResponse) = r.content
tool_calls(r::LLMResponse) = r.tool_calls
usage(r::LLMResponse) = r.usage
finish_reason(r::LLMResponse) = r.finish_reason
raw(r::LLMResponse) = r.raw

# --------------------------------------------------------------------------
# AbstractLLMProvider interface: call / stream
# --------------------------------------------------------------------------

"""
    call(llm::AbstractLLMProvider, messages; tools = ToolSpec[], kwargs...) -> AbstractLLMResponse

Send `messages` to `llm` and return an [`AbstractLLMResponse`](@ref). `tools`
is the **provider-facing** description of the callable tools available for
function calling: a vector of [`ToolSpec`](@ref) (name + description + JSON
schema), *not* the executable [`AbstractTool`](@ref) objects. Callers derive
them with `map(spec, tools)` and keep the executable objects for
[`execute`](@ref). Providers specialize this method; the fallback throws
[`LLMError`](@ref).
"""
function call(llm::AbstractLLMProvider, messages; tools = ToolSpec[], kwargs...)
    throw(LLMError("call(::$(typeof(llm)), …) is not implemented"))
end

"""
    stream(llm::AbstractLLMProvider, messages; kwargs...)

Streaming variant of [`call`](@ref). Providers that support streaming
specialize this; the fallback throws [`LLMError`](@ref).
"""
function stream(llm::AbstractLLMProvider, messages; kwargs...)
    throw(LLMError("stream(::$(typeof(llm)), …) is not implemented"))
end
