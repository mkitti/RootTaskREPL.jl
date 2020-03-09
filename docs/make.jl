using Documenter, RootTaskREPL

makedocs(
    modules = [RootTaskREPL],
    format = Documenter.HTML(; prettyurls = get(ENV, "CI", nothing) == "true"),
    authors = "Mark Kittisopikul",
    sitename = "RootTaskREPL.jl",
    pages = Any["index.md"]
    # strict = true,
    # clean = true,
    # checkdocs = :exports,
)

deploydocs(
    repo = "github.com/mkitti/RootTaskREPL.jl.git",
    push_preview = true
)
