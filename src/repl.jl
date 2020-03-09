import Base
import REPL

have_color = false
is_interactive = false

"exec_options(opts): Adapted from base/client.jl"
function exec_options(opts)
    quiet                 = (opts.quiet != 0)
    startup               = (opts.startupfile != 2)
    history_file          = (opts.historyfile != 0)
    color_set             = (opts.color != 0) # --color!=auto
    global have_color     = (opts.color == 1) # --color=on
    global is_interactive = (opts.isinteractive != 0)
    interactiveinput = isa(stdin, Base.TTY)
    if interactiveinput
        global is_interactive = true
        banner = (opts.banner != 0) # --banner!=no
    else
        banner = (opts.banner == 1) # --banner=yes
    end
    run_main_repl(interactiveinput, quiet, banner, history_file, color_set)
    nothing
end
"exec_options(): Use Base.JLOptions())"
exec_options() = exec_options(Base.JLOptions())

"run_main_repl(interactive, quiet, banner, history_file, color_set): See base/client.jl"
function run_main_repl(interactive::Bool, quiet::Bool, banner::Bool, history_file::Bool, color_set::Bool)
    # load interactive-only libraries
    if !isdefined(Main, :InteractiveUtils)
        try
            let InteractiveUtils = Base.require(Base.PkgId(Base.UUID(0xb77e0a4c_d291_57a0_90e8_8db25a27a240), "InteractiveUtils"))
                Core.eval(Main, :(const InteractiveUtils = $InteractiveUtils))
                Core.eval(Main, :(using .InteractiveUtils))
            end
        catch ex
            @warn "Failed to import InteractiveUtils into module Main" exception=(ex, catch_backtrace())
        end
    end

    if interactive && isassigned(Base.REPL_MODULE_REF)
        Base.invokelatest(Base.REPL_MODULE_REF[]) do REPL
            term_env = get(ENV, "TERM", @static Sys.iswindows() ? "" : "dumb")
            term = REPL.Terminals.TTYTerminal(term_env, stdin, stdout, stderr)
            color_set || (global have_color = REPL.Terminals.hascolor(term))
            set_have_color()
            banner && Base.banner(term)
            if term.term_type == "dumb"
                active_repl = REPL.BasicREPL(term)
                quiet || @warn "Terminal not fully functional"
            else
                active_repl = REPL.LineEditREPL(term, have_color, true)
                active_repl.history_file = history_file
            end
            set_active_repl(active_repl)
            # Make sure any displays pushed in .julia/config/startup.jl ends up above the
            # REPLDisplay
            Base.pushdisplay(REPL.REPLDisplay(active_repl))
            Base._atreplinit(active_repl)
            if Base.roottask === Base.current_task()
                active_repl.interface.modes[1].prompt = "julia-root> "
            end
            set_active_repl(active_repl)
            run_repl(active_repl, set_active_repl_backend)
        end
    end
end
run_main_repl() = exec_options()

function set_active_repl(repl::REPL.AbstractREPL)
    @eval Base active_repl = $repl
    @eval Base have_color = $have_color
    @eval Base is_interactive = $is_interactive
end

function set_have_color()
    @eval Base have_color = $have_color
end

function set_active_repl_backend(backend::REPL.REPLBackend)
    @eval Base active_repl_backend = $backend
end

"run_repl(repl, consumer): Run frontend on another Task, run backend on current Task. See stdlib/REPL/src/REPL.jl"
function run_repl(repl::REPL.AbstractREPL, @nospecialize(consumer = x -> nothing))
    repl_channel = Channel(1)
    response_channel = Channel(1)
    backend = REPL.REPLBackend(repl_channel, response_channel, false)
    backend.backend_task = Base.current_task()
    consumer(backend)
    @debug "RootTaskREPL: Starting frontend_task"
    frontend_task = @async begin
            REPL.run_frontend(repl, REPL.REPLBackendRef(repl_channel, response_channel))
            @debug "RootTaskREPL: Frontend exit"
            # Explicitly stop the backend REPL
            put!(repl_channel, (nothing, -1))
    end
    @debug "RootTaskREPL: Starting backend"
    repl_backend_loop(backend)
    @debug "RootTaskREPL: Backend exit"
    # Make non-interactive so normal REPL does not start
    @eval Base is_interactive = false
    return backend
end

"repl_backend_loop(backend): Run backend loop on current Task rather than using @async. See stdlib/REPL/src/REPL.jl"
function repl_backend_loop(backend::REPL.REPLBackend)
    # include looks at this to determine the relative include path
    # nothing means cwd
    while true
        tls = task_local_storage()
        tls[:SOURCE_PATH] = nothing
        ast, show_value = take!(backend.repl_channel)
        if show_value == -1
            # exit flag
            break
        end
        REPL.eval_user_input(ast, backend)
    end
    nothing
end
