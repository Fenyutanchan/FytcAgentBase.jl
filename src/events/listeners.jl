"""
    events/listeners.jl

Built-in event listeners. Phase 0 ships [`ConsoleListener`], which prints events
through the standard `Logging` system.
"""

"""
    ConsoleListener(; min_level = Logging.Info)

A callable listener that prints events to the active logger. [`LogEvent`]s are
emitted at their own level (filtered by `min_level`); other events are printed at
`Logging.Info`.

# Example
```julia
bus = EventBus()
subscribe!(bus, ConsoleListener())
emit!(bus, LogEvent(Logging.Info, "hello"))
```
"""
struct ConsoleListener <: AbstractEventListener
    min_level::LogLevel
end
ConsoleListener(; min_level::LogLevel = Logging.Info) = ConsoleListener(min_level)

function (listener::ConsoleListener)(event::LogEvent)
    event.level >= listener.min_level || return nothing
    @logmsg event.level event.message _module = FytcAgentBase _group = :event
    return nothing
end

function (listener::ConsoleListener)(event::GenericEvent)
    @logmsg Logging.Info "event :$(event.name)" payload = event.payload
    return nothing
end

# Fallback for any other AbstractEvent subtype.
function (listener::ConsoleListener)(event::AbstractEvent)
    @logmsg Logging.Info "event $(nameof(typeof(event)))"
    return nothing
end
