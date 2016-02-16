using SimplePlotPerf
using Base.Test

# just make sure it runs
prplot(Dict(
    "test" => rand(100)
), bitrand(100))
