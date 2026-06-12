"""
    FytcAgentBase

Foundation package for the FytcAgents framework (the analogue of CrewAI's
`crewai-core`). It defines the shared abstract type hierarchy, the error model,
a minimal synchronous event bus, and configuration helpers.

This package is intentionally dependency-light (standard library only) so it can
serve as a stable base for the orchestration package `FytcAgents` and for user
extensions.
"""
module FytcAgentBase

using Dates: DateTime, now
using Logging: Logging, LogLevel, @logmsg
using UUIDs: UUID, uuid4

# Order matters: errors are referenced by type constructors in types.jl.
include("errors.jl")
include("types.jl")
include("events/Events.jl")
include("events/listeners.jl")
include("config.jl")

# Abstract types & value types
export AbstractLLM, AbstractTool, AbstractEvent, AbstractMemory
export AbstractEventListener
export Message, MESSAGE_ROLES, ToolCall

# Errors
export FytcAgentsError, ConfigError, LLMError, ToolError

# Events
export EventBus, subscribe!, emit!, GenericEvent, LogEvent
export CallableListener, ConsoleListener

# Config
export getconfig

end # module FytcAgentBase
