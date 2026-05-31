using FytcAgentBase
using Logging: Logging
using Test

@testset "FytcAgentBase" begin
    @testset "Message" begin
        m = Message(:user, "hello")
        @test m.role === :user
        @test m.content == "hello"
        @test_throws ConfigError Message(:invalid, "x")
    end

    @testset "Errors" begin
        @test ConfigError <: FytcAgentsError
        @test LLMError <: FytcAgentsError
        @test ToolError <: FytcAgentsError
        @test sprint(showerror, ToolError("boom")) == "ToolError: boom"
    end

    @testset "EventBus dispatch" begin
        bus = EventBus()
        seen = AbstractEvent[]
        subscribe!(bus, ev -> push!(seen, ev))
        ev = emit!(bus, GenericEvent(:ping, 42))
        @test length(seen) == 1
        @test seen[1] === ev
        @test ev.name === :ping
        @test ev.payload == 42
    end

    @testset "EventBus isolates failing listeners" begin
        bus = EventBus()
        ok = Ref(false)
        subscribe!(bus, _ -> error("listener boom"))
        subscribe!(bus, _ -> (ok[] = true))
        Logging.with_logger(Logging.NullLogger()) do
            emit!(bus, GenericEvent(:x))
        end
        @test ok[]  # second listener still ran
    end

    @testset "Listener types" begin
        @test ConsoleListener <: AbstractEventListener
        @test CallableListener <: AbstractEventListener
        bus = EventBus()
        @test eltype(bus.listeners) === AbstractEventListener
        # A raw closure is auto-wrapped in a CallableListener.
        subscribe!(bus, _ -> nothing)
        @test bus.listeners[1] isa CallableListener
        # An AbstractEventListener is stored as-is.
        cl = ConsoleListener()
        subscribe!(bus, cl)
        @test bus.listeners[2] === cl
    end

    @testset "ConsoleListener" begin
        bus = EventBus()
        subscribe!(bus, ConsoleListener())
        # Should not throw under a NullLogger.
        Logging.with_logger(Logging.NullLogger()) do
            emit!(bus, LogEvent(Logging.Info, "hello"))
            emit!(bus, GenericEvent(:demo, "payload"))
        end
        @test true
    end

    @testset "Config" begin
        @test getconfig("definitely_unset_key", :fallback) === :fallback
        withenv("FYTC_LOG_LEVEL" => "debug") do
            @test getconfig("log_level") == "debug"
            @test getconfig("log-level") == "debug"  # dashes normalized
        end
    end
end

@testset "Aqua quality" begin
    import Aqua
    Aqua.test_all(FytcAgentBase; ambiguities = false)
end
