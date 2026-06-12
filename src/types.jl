"""
    types.jl

Shared abstract type hierarchy and the `Message` value type for the FytcAgents
framework. In Phase 0 these establish naming and dispatch points only; concrete
methods (e.g. LLM `call`, tool `run`) are implemented in later phases.
"""

"""
    AbstractLLM

Supertype for all language-model providers. Concrete providers (e.g. an
OpenAI-compatible backend) subtype this and specialize [`call`](@ref) /
[`stream`](@ref).
"""
abstract type AbstractLLM end

"""
    AbstractTool

Supertype for callable capabilities exposed to agents. Concrete tools specialize
`spec` (returning a JSON-schema description) and `run`.
"""
abstract type AbstractTool end

"""
    AbstractEvent

Supertype for events flowing through an [`EventBus`](@ref).
"""
abstract type AbstractEvent end

"""
    AbstractEventListener

Supertype for event listeners registered on an [`EventBus`](@ref). Concrete
listeners are *functors*: they implement `(listener::T)(event::AbstractEvent)`.

Raw callables (plain functions and closures) are not subtypes of this type; they
are wrapped automatically by [`subscribe!`](@ref) in a [`CallableListener`](@ref).
"""
abstract type AbstractEventListener end

"""
    AbstractMemory

Supertype for agent/crew memory backends (short-term, long-term, entity).
"""
abstract type AbstractMemory end

"""
    ToolCall(id, name, arguments)

A request, emitted by an [`AbstractLLM`](@ref), to invoke a tool. `arguments`
maps parameter names to decoded values. `id` correlates the call with the
[`Message`](@ref) (role `:tool`) that carries its result.
"""
struct ToolCall
    id::String
    name::String
    arguments::Dict{String,Any}
end
ToolCall(name::AbstractString, arguments::AbstractDict = Dict{String,Any}()) =
    ToolCall(string(name), string(name), Dict{String,Any}(arguments))

"""
    MessageRole

Allowed roles for a [`Message`](@ref): `:system`, `:user`, `:assistant`, `:tool`.
"""
const MESSAGE_ROLES = (:system, :user, :assistant, :tool)

"""
    Message(role::Symbol, content::AbstractString; name, tool_calls, tool_call_id)

A single chat message. `role` must be one of `$(MESSAGE_ROLES)`.

Optional fields support function calling:
- `name`: an optional speaker/tool name.
- `tool_calls`: tool-call requests attached to an `:assistant` message.
- `tool_call_id`: on a `:tool` message, the [`ToolCall`](@ref) `id` it answers.
"""
struct Message
    role::Symbol
    content::String
    name::Union{Nothing,String}
    tool_calls::Vector{ToolCall}
    tool_call_id::Union{Nothing,String}

    function Message(
        role::Symbol,
        content::AbstractString;
        name::Union{Nothing,AbstractString} = nothing,
        tool_calls::AbstractVector{ToolCall} = ToolCall[],
        tool_call_id::Union{Nothing,AbstractString} = nothing,
    )
        role ∈ MESSAGE_ROLES ||
            throw(ConfigError("invalid message role :$role; expected one of $(MESSAGE_ROLES)"))
        return new(
            role,
            String(content),
            name === nothing ? nothing : String(name),
            collect(ToolCall, tool_calls),
            tool_call_id === nothing ? nothing : String(tool_call_id),
        )
    end
end
