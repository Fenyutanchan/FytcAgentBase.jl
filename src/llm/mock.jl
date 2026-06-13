"""
    llm/mock.jl

[`MockLLM`](@ref): a scripted, zero-dependency [`AbstractLLM`](@ref) for tests
and examples. It returns pre-built [`LLMResponse`]s in order and records the
messages it received, so agent/tool logic is testable without network access.
"""

"""
    MockLLM(responses)

A scripted LLM. Each [`call`](@ref) returns the next [`LLMResponse`] from
`responses` (strings are coerced to text responses) and appends the received
messages to `received`. Throws [`LLMError`](@ref) once the script is exhausted.

# Example
```julia
llm = MockLLM([
    LLMResponse(; tool_calls = [ToolCall("call_1", "add", Dict{String,Any}("x"=>2,"y"=>3))]),
    LLMResponse("The sum is 5."),
])
```
"""
mutable struct MockLLM <: AbstractLLM
    responses::Vector{LLMResponse}
    received::Vector{Vector{Message}}
    index::Int
end

_as_response(r::LLMResponse) = r
_as_response(s::AbstractString) = LLMResponse(s)

MockLLM(responses::AbstractVector) =
    MockLLM(LLMResponse[_as_response(r) for r in responses], Vector{Message}[], 0)

function call(llm::MockLLM, messages; tools = ToolSpec[], kwargs...)
    push!(llm.received, collect(Message, messages))
    llm.index += 1
    llm.index <= length(llm.responses) ||
        throw(LLMError("MockLLM exhausted: no scripted response #$(llm.index)"))
    return llm.responses[llm.index]
end
