"""
    events/Events.jl

A minimal, synchronous event bus. Core framework operations emit typed
[`AbstractEvent`] values; subscribers registered via [`subscribe!`](@ref) are
invoked in registration order by [`emit!`](@ref).

Phase 0 provides a synchronous dispatch model and two seed event types
([`GenericEvent`], [`LogEvent`]). Richer event types and async dispatch arrive in
later phases.
"""

"""
    GenericEvent(name, payload)

A catch-all event carrying a symbolic `name` and an arbitrary `payload`.
"""
struct GenericEvent <: AbstractEvent
    name::Symbol
    payload::Any
    timestamp::DateTime
end
GenericEvent(name::Symbol, payload = nothing) = GenericEvent(name, payload, now())

"""
    LogEvent(level, message)

A structured logging event. `level` is a `Logging.LogLevel` (e.g. `Logging.Info`).
"""
struct LogEvent <: AbstractEvent
    level::LogLevel
    message::String
    timestamp::DateTime
end
LogEvent(level::LogLevel, message::AbstractString) = LogEvent(level, String(message), now())

"""
    EventBus()

A synchronous event bus holding an ordered list of subscriber listeners. Each
listener is an [`AbstractEventListener`] functor; raw callables passed to
[`subscribe!`](@ref) are wrapped in a [`CallableListener`].
"""
struct EventBus
    listeners::Vector{AbstractEventListener}
end
EventBus() = EventBus(AbstractEventListener[])

"""
    CallableListener(f)

Adapter that turns a raw callable `f(event::AbstractEvent)` into an
[`AbstractEventListener`]. [`subscribe!`](@ref) uses this automatically, so user
code can register plain functions and closures directly.
"""
struct CallableListener{F} <: AbstractEventListener
    f::F
end
(listener::CallableListener)(event::AbstractEvent) = listener.f(event)

"""
    subscribe!(bus::EventBus, listener) -> EventBus

Register `listener` on `bus`. An [`AbstractEventListener`] is stored as-is; any
other callable taking one [`AbstractEvent`] is wrapped in a [`CallableListener`].
Returns the bus to allow chaining.
"""
function subscribe!(bus::EventBus, listener::AbstractEventListener)
    push!(bus.listeners, listener)
    return bus
end
subscribe!(bus::EventBus, listener) = subscribe!(bus, CallableListener(listener))

"""
    emit!(bus::EventBus, event::AbstractEvent) -> AbstractEvent

Dispatch `event` to every subscriber in registration order. A failing listener
does not prevent the remaining listeners from running; its error is reported via
`@error` and swallowed. Returns the emitted event.
"""
function emit!(bus::EventBus, event::AbstractEvent)
    for listener in bus.listeners
        try
            listener(event)
        catch err
            @error "event listener failed" listener exception = (err, catch_backtrace())
        end
    end
    return event
end
