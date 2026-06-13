"""
    memory/Memory.jl

The memory interface (plan §9 Phase 4). Concrete memories subtype
[`AbstractMemory`](@ref) and specialize [`remember!`](@ref), [`recall`](@ref)
and [`reset!`](@ref). The design mirrors CrewAI's `save` / `search` / `reset`,
but recall is **keyword / keyed**, never vector-similarity (semantic recall is a
non-goal — see plan §1).

`AbstractMemory` itself is declared in `types.jl`; this file adds the value type
carried by a memory and the generic verbs operating on it.
"""

"""
    MemoryRecord(content; key = nothing, timestamp = now())

One stored memory entry. `content` is the remembered text; `key` is an optional
label used by keyed recall (e.g. an entity name); `timestamp` records when it was
saved. Mirrors the shape of CrewAI's `MemoryRecord`, minus the embedding vector.
"""
struct MemoryRecord
    content::String
    key::Union{Nothing,String}
    timestamp::DateTime
end
MemoryRecord(
    content::AbstractString;
    key::Union{Nothing,AbstractString} = nothing,
    timestamp::DateTime = now(),
) = MemoryRecord(String(content), key === nothing ? nothing : String(key), timestamp)

function Base.show(io::IO, r::MemoryRecord)
    label = r.key === nothing ? "" : repr(r.key) * " => "
    snippet = length(r.content) > 40 ? first(r.content, 40) * "…" : r.content
    print(io, "MemoryRecord(", label, repr(snippet), ")")
    return nothing
end

"""
    remember!(mem::AbstractMemory, content; key = nothing) -> MemoryRecord

Store `content` in `mem` (optionally under `key`) and return the saved
[`MemoryRecord`](@ref). Concrete memories specialize this; the fallback throws
[`ConfigError`](@ref).
"""
function remember!(mem::AbstractMemory, content; key = nothing)
    throw(ConfigError("remember!(::$(typeof(mem)), …) is not implemented"))
end

"""
    recall(mem::AbstractMemory, query = nothing; limit = 5) -> Vector{MemoryRecord}

Return up to `limit` records from `mem` relevant to `query`. The matching is
**keyword / keyed**, never semantic: a `query` is compared by exact key and
case-insensitive substring against record keys and content; `nothing` returns the
most recent records. Concrete memories specialize this; the fallback throws
[`ConfigError`](@ref).
"""
function recall(mem::AbstractMemory, query = nothing; limit::Integer = 5)
    throw(ConfigError("recall(::$(typeof(mem)), …) is not implemented"))
end

"""
    reset!(mem::AbstractMemory) -> AbstractMemory

Clear all records from `mem` and return it. Concrete memories specialize this;
the fallback throws [`ConfigError`](@ref).
"""
function reset!(mem::AbstractMemory)
    throw(ConfigError("reset!(::$(typeof(mem))) is not implemented"))
end
