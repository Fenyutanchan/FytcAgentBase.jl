"""
    tools/Tools.jl

The tool interface: a tool is any [`AbstractTool`](@ref) exposing a [`ToolSpec`]
via [`spec`](@ref) and runnable via [`execute`](@ref). [`FunctionTool`] adapts a
plain Julia function into a tool, and the [`@tool`](@ref) macro builds one from a
function definition, auto-deriving the JSON schema from the signature.

`execute` (rather than `Base.run`) is used to avoid colliding with the standard
library's process-running `run`.
"""

"""
    spec(tool::AbstractTool) -> ToolSpec

Return the [`ToolSpec`] describing `tool` for an LLM's function-calling API.
"""
function spec end

"""
    execute(tool::AbstractTool, args::Dict{String,Any}) -> Any

Run `tool` with keyword-style `args` (parameter name => value) and return its
result. Concrete tools specialize this method.

    execute(tools, call::ToolCall) -> Any

Find the tool in `tools` whose name matches `call.name` and execute it with
`call.arguments`. Throws [`ToolError`](@ref) if no tool matches.
"""
function execute end

"""
    FunctionTool(f, spec, argnames, argtypes)

A tool backed by a Julia callable `f`. [`execute`](@ref) converts incoming
arguments to the declared `argtypes` (positionally, by `argnames`) before
calling `f`. Usually constructed via the [`@tool`](@ref) macro.
"""
struct FunctionTool{F} <: AbstractTool
    f::F
    spec::ToolSpec
    argnames::Vector{Symbol}
    argtypes::Vector{Type}
end

spec(t::FunctionTool) = t.spec

function _convert_arg(::Type{T}, value, name, toolname) where {T}
    try
        return convert(T, value)
    catch err
        throw(
            ToolError(
                "tool '$toolname' argument '$name': cannot convert $(repr(value)) to $T ($err)",
            ),
        )
    end
end

function execute(t::FunctionTool, args::Dict{String,Any})
    converted = Vector{Any}(undef, length(t.argnames))
    for (i, name) in enumerate(t.argnames)
        key = String(name)
        haskey(args, key) ||
            throw(ToolError("tool '$(t.spec.name)' missing required argument '$key'"))
        converted[i] = _convert_arg(t.argtypes[i], args[key], key, t.spec.name)
    end
    return t.f(converted...)
end

function execute(tools, call::ToolCall)
    for t in tools
        spec(t).name == call.name && return execute(t, call.arguments)
    end
    throw(ToolError("no tool named '$(call.name)' among $(length(tools)) registered tools"))
end

"""
    @tool description function name(arg::T, ...) ... end

Build a [`FunctionTool`] from a function definition. `description` is a string
shown to the LLM; the advertised tool name is taken from `name`. The JSON schema
is derived from the argument names and types. The macro expands to the
`FunctionTool` value, so bind it to a variable:

    add = @tool "Add two integers." function add(x::Int, y::Int)
        return x + y
    end

The body is wrapped in an anonymous function (no global `name` is defined), so it
is safe to use at top-level module scope.

# Example
```julia
add = @tool "Add two integers." function add(x::Int, y::Int)
    return x + y
end
execute(add, Dict{String,Any}("x" => 2, "y" => 3))  # => 5
```
"""
macro tool(description, fdef)
    (fdef isa Expr && fdef.head in (:function, :(=))) ||
        throw(ArgumentError("@tool expects a function definition"))
    sig = fdef.args[1]
    body = fdef.args[2]
    (sig isa Expr && sig.head === :call) ||
        throw(ArgumentError("@tool: unsupported function signature $sig"))
    fname = sig.args[1]
    fname isa Symbol || throw(ArgumentError("@tool: function must have a simple name"))

    argexprs = sig.args[2:end]
    argnames = Symbol[]
    argtype_exprs = Any[]
    for a in argexprs
        if a isa Symbol
            push!(argnames, a)
            push!(argtype_exprs, :Any)
        elseif a isa Expr && a.head === :(::)
            push!(argnames, a.args[1]::Symbol)
            push!(argtype_exprs, a.args[2])
        else
            throw(ArgumentError("@tool: unsupported argument $a"))
        end
    end

    namestr = String(fname)
    # An anonymous function carrying the original (typed) signature and body, so
    # no global binding named `fname` is created.
    lambda = Expr(:function, Expr(:tuple, argexprs...), body)
    prop_pairs = (
        Expr(:call, :(=>), String(n), :(_json_schema_property($(esc(t))))) for
        (n, t) in zip(argnames, argtype_exprs)
    )
    required = Expr(:vect, (String(n) for n in argnames)...)
    names_vec = Expr(:vect, (QuoteNode(n) for n in argnames)...)
    types_vec = Expr(:ref, :Type, (esc(t) for t in argtype_exprs)...)

    return quote
        local _params = Dict{String,Any}(
            "type" => "object",
            "properties" => Dict{String,Any}($(prop_pairs...)),
            "required" => $required,
        )
        FunctionTool(
            $(esc(lambda)),
            ToolSpec($namestr, $(esc(description)), _params),
            $names_vec,
            $types_vec,
        )
    end
end
