# RootTaskREPL.jl

![Lifecycle](https://img.shields.io/badge/lifecycle-experimental-orange.svg)<!--
![Lifecycle](https://img.shields.io/badge/lifecycle-maturing-blue.svg)
![Lifecycle](https://img.shields.io/badge/lifecycle-stable-green.svg)
![Lifecycle](https://img.shields.io/badge/lifecycle-retired-orange.svg)
![Lifecycle](https://img.shields.io/badge/lifecycle-archived-red.svg)
![Lifecycle](https://img.shields.io/badge/lifecycle-dormant-blue.svg) -->
[![Build Status](https://travis-ci.com/mkitti/RootTaskREPL.jl.svg?branch=master)](https://travis-ci.com/mkitti/RootTaskREPL.jl)
[![codecov.io](http://codecov.io/github/mkitti/RootTaskREPL.jl/coverage.svg?branch=master)](http://codecov.io/github/mkitti/RootTaskREPL.jl?branch=master)

RootTaskREPL creates a Julia REPL where the REPL backend runs on the
current Task and the frontend runs on a new task. This allows the
backend to execute on the root Task if used at startup.

If initialized on the root Task, the module will automatically start
the REPL.

This is useful for packages that must be initialized on the root Task
on some platforms (e.g. JavaCall)

Usage:
```
julia -e "import RootTaskREPL"

julia-root> Base.roottask === Base.current_task()
true
```

Advanced Usage:
```
ROOTTASKREPL_ON_INIT=0 julia -e \
"import RootTaskREPL; RootTaskREPL.run_main_repl()"
```

Licensed under MIT "Expat" License. See License.md for details.
