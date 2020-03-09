(rd,wr) = Base.redirect_stdin()
write(wr,"println(Base.roottask === Base.current_task());\n")
write(wr,"@assert false\n")

using Test
using RootTaskREPL

@testset "check_root_task" begin
        @test Base.roottask === Base.current_task()
end

close(wr)
