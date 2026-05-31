"""
    config.jl

Minimal environment-variable-based configuration helpers. Phase 0 intentionally
avoids extra dependencies (e.g. `Preferences.jl`); richer configuration arrives
in a later phase.
"""

"""
    getconfig(key::AbstractString, default = nothing)

Read configuration value `key` from the process environment. The lookup is
namespaced under the `FYTC_` prefix and upper-cased, so `getconfig("log_level")`
reads the `FYTC_LOG_LEVEL` environment variable. Returns `default` if unset.
"""
function getconfig(key::AbstractString, default = nothing)
    envkey = "FYTC_" * uppercase(replace(String(key), "-" => "_"))
    return get(ENV, envkey, default)
end
