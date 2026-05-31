"""
    errors.jl

Typed error hierarchy for the FytcAgents framework. All framework errors subtype
[`FytcAgentsError`] so callers can catch them collectively.
"""

"""
    FytcAgentsError <: Exception

Root of the framework error hierarchy.
"""
abstract type FytcAgentsError <: Exception end

"""
    ConfigError(msg)

Raised on invalid configuration or invalid construction arguments.
"""
struct ConfigError <: FytcAgentsError
    msg::String
end

"""
    LLMError(msg)

Raised when a language-model provider call fails.
"""
struct LLMError <: FytcAgentsError
    msg::String
end

"""
    ToolError(msg)

Raised when a tool fails to execute or receives invalid arguments.
"""
struct ToolError <: FytcAgentsError
    msg::String
end

function Base.showerror(io::IO, e::FytcAgentsError)
    print(io, nameof(typeof(e)), ": ", e.msg)
    return nothing
end
