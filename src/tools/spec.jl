"""
    tools/spec.jl

Tool descriptions and JSON-schema derivation for function calling. A
[`ToolSpec`] is the provider-facing description of a tool; [`json_schema_type`]
maps Julia types onto JSON-schema primitive type names.
"""

"""
    ToolSpec(name, description, parameters)

A JSON-schema description of a tool, suitable for an LLM's function-calling
interface. `parameters` is a JSON-schema `object` (`Dict{String,Any}` with
`"type"`, `"properties"`, and `"required"` keys).
"""
struct ToolSpec
    name::String
    description::String
    parameters::Dict{String,Any}
end

"""
    json_schema_type(T::Type) -> String

Map a Julia type onto its JSON-schema primitive type name. Falls back to
`"string"` for types without a more specific mapping.
"""
json_schema_type(::Type{Bool}) = "boolean"
json_schema_type(::Type{<:Integer}) = "integer"
json_schema_type(::Type{<:Real}) = "number"
json_schema_type(::Type{<:AbstractString}) = "string"
json_schema_type(::Type{Symbol}) = "string"
json_schema_type(::Type{<:AbstractVector}) = "array"
json_schema_type(::Type{<:AbstractDict}) = "object"
json_schema_type(::Type) = "string"

"""
    _json_schema_property(T::Type) -> Dict{String,Any}

Build the JSON-schema fragment describing a single parameter of type `T`.
"""
_json_schema_property(::Type{T}) where {T} = Dict{String,Any}("type" => json_schema_type(T))
