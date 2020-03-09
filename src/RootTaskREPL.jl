"""
    RootTaskREPL creates a Julia REPL where the REPL backend runs on the
    current Task and the frontend runs on a new task. This allows the
    backend to execute on the root Task if used at startup.

    If initialized on the root Task, the module will automatically start
    the REPL.

    This is useful for packages that must be initialized on the root Task
    on some platforms (e.g. JavaCall)

    Usage:
    julia -e "import RootTaskREPL"

    julia-root> Base.roottask === Base.current_task()
    true

    Advanced Usage:
    ROOTTASKREPL_ON_INIT=0 julia -e \\
    "import RootTaskREPL; RootTaskREPL.run_main_repl()"
"""
module RootTaskREPL
    include("repl.jl")

    ROOTTASKREPL_ON_INIT = true

    function __init__()
        global ROOTTASKREPL_ON_INIT = get(ENV,"ROOTTASKREPL_ON_INIT","1") in ("1","yes")
        if ROOTTASKREPL_ON_INIT && Base.roottask === Base.current_task()
           run_main_repl()
        end
    end

end # module
