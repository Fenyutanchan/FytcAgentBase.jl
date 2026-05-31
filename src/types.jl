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
    MessageRole

Allowed roles for a [`Message`](@ref): `:system`, `:user`, `:assistant`, `:tool`.
"""
const MESSAGE_ROLES = (:system, :user, :assistant, :tool)

"""
    Message(role::Symbol, content::AbstractString)

A single chat message. `role` must be one of `$(MESSAGE_ROLES)`.
"""
struct Message
    role::Symbol
    content::String

    function Message(role::Symbol, content::AbstractString)
        role ∈ MESSAGE_ROLES ||
            throw(ConfigError("invalid message role :$role; expected one of $(MESSAGE_ROLES)"))
        return new(role, String(content))
    end
end
