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

    @testset "Message tool-calling fields" begin
        tc = ToolCall("call_1", "add", Dict{String,Any}("x" => 2))
        m = Message(:assistant, "calling"; tool_calls = [tc])
        @test m.tool_calls[1].name == "add"
        @test m.name === nothing
        @test m.tool_call_id === nothing
        tm = Message(:tool, "5"; name = "add", tool_call_id = "call_1")
        @test tm.tool_call_id == "call_1"
        @test tm.name == "add"
        # Two-arg ToolCall convenience: id mirrors name.
        tc2 = ToolCall("greet", Dict{String,Any}("who" => "world"))
        @test tc2.id == "greet" && tc2.name == "greet"
    end

    @testset "json_schema_type" begin
        @test json_schema_type(Int) == "integer"
        @test json_schema_type(Bool) == "boolean"       # not "integer"
        @test json_schema_type(Float64) == "number"
        @test json_schema_type(String) == "string"
        @test json_schema_type(Vector{Int}) == "array"
        @test json_schema_type(Dict{String,Any}) == "object"
    end

    @testset "@tool schema + execute" begin
        add = @tool "Add two integers." function add(x::Int, y::Int)
            return x + y
        end
        @test add isa FunctionTool
        s = spec(add)
        @test s.name == "add"
        @test s.description == "Add two integers."
        @test s.parameters["type"] == "object"
        @test s.parameters["properties"]["x"]["type"] == "integer"
        @test sort(s.parameters["required"]) == ["x", "y"]
        @test execute(add, Dict{String,Any}("x" => 2, "y" => 3)) == 5
        # Arg conversion: Float that is integral converts to Int.
        @test execute(add, Dict{String,Any}("x" => 2.0, "y" => 3)) == 5
        # Missing argument errors.
        @test_throws ToolError execute(add, Dict{String,Any}("x" => 1))
    end

    @testset "execute by ToolCall dispatch" begin
        add = @tool "Add." function add(x::Int, y::Int)
            x + y
        end
        mul = @tool "Multiply." function mul(x::Int, y::Int)
            x * y
        end
        tools = AbstractTool[add, mul]
        @test execute(tools, ToolCall("c1", "mul", Dict{String,Any}("x" => 4, "y" => 5))) == 20
        @test_throws ToolError execute(tools, ToolCall("c2", "div", Dict{String,Any}()))
    end

    @testset "LLMResponse & TokenUsage" begin
        u = TokenUsage(; prompt = 10, completion = 4)
        @test u.total_tokens == 14
        r = LLMResponse("hi")
        @test r.content == "hi"
        @test isempty(r.tool_calls)
        @test r.usage.total_tokens == 0
    end

    @testset "MockLLM scripted responses" begin
        llm = MockLLM(["first", LLMResponse("second")])
        @test call(llm, [Message(:user, "a")]).content == "first"
        @test call(llm, [Message(:user, "b")]).content == "second"
        @test length(llm.received) == 2
        @test llm.received[1][1].content == "a"
        @test_throws LLMError call(llm, [Message(:user, "c")])
    end

    @testset "tool round-trip (MockLLM)" begin
        add = @tool "Add two integers." function add(x::Int, y::Int)
            return x + y
        end
        tools = AbstractTool[add]
        llm = MockLLM([
            LLMResponse(;
                tool_calls = [ToolCall("call_1", "add", Dict{String,Any}("x" => 2, "y" => 3))],
            ),
            LLMResponse("The sum is 5."),
        ])

        history = Message[Message(:user, "What is 2 + 3?")]
        # First turn: the model asks for a tool call.
        r1 = call(llm, history; tools = tools)
        @test !isempty(r1.tool_calls)
        tc = r1.tool_calls[1]
        result = execute(tools, tc)
        @test result == 5
        push!(history, Message(:assistant, r1.content; tool_calls = r1.tool_calls))
        push!(history, Message(:tool, string(result); name = tc.name, tool_call_id = tc.id))
        # Second turn: the model produces the final answer.
        r2 = call(llm, history; tools = tools)
        @test isempty(r2.tool_calls)
        @test r2.content == "The sum is 5."
    end
end

@testset "Aqua quality" begin
    import Aqua
    Aqua.test_all(FytcAgentBase; ambiguities = false)
end
