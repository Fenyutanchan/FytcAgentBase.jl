"""
    llm/LLM.jl

The language-model interface. Providers subtype [`AbstractLLM`](@ref) and
specialize [`call`](@ref); [`LLMResponse`] is the uniform return value carrying
text content, any [`ToolCall`](@ref)s, and token [`TokenUsage`].
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

"""
    LLMResponse(content; tool_calls = ToolCall[], usage = TokenUsage(), raw = nothing)

The uniform result of an LLM [`call`](@ref). `content` is the assistant text
(possibly empty when the model only requests tools); `tool_calls` holds any
requested [`ToolCall`](@ref)s; `raw` may carry the provider's original payload.
"""
struct LLMResponse
    content::String
    tool_calls::Vector{ToolCall}
    usage::TokenUsage
    raw::Any
end
LLMResponse(
    content::AbstractString = "";
    tool_calls::AbstractVector{ToolCall} = ToolCall[],
    usage::TokenUsage = TokenUsage(),
    raw = nothing,
) = LLMResponse(String(content), collect(ToolCall, tool_calls), usage, raw)

"""
    call(llm::AbstractLLM, messages; tools = ToolSpec[], kwargs...) -> LLMResponse

Send `messages` to `llm` and return an [`LLMResponse`]. `tools` is the
**provider-facing** description of the callable tools available for function
calling: a vector of [`ToolSpec`](@ref) (name + description + JSON schema), *not*
the executable [`AbstractTool`](@ref) objects. Callers derive them with
`map(spec, tools)` and keep the executable objects for [`execute`](@ref).
Providers specialize this method; the fallback throws [`LLMError`](@ref).
"""
function call(llm::AbstractLLM, messages; tools = ToolSpec[], kwargs...)
    throw(LLMError("call(::$(typeof(llm)), …) is not implemented"))
end

"""
    stream(llm::AbstractLLM, messages; kwargs...)

Streaming variant of [`call`](@ref). Providers that support streaming specialize
this; the fallback throws [`LLMError`](@ref).
"""
function stream(llm::AbstractLLM, messages; kwargs...)
    throw(LLMError("stream(::$(typeof(llm)), …) is not implemented"))
end
