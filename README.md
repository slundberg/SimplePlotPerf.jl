# SimplePlotPerf

[![Build Status](https://travis-ci.org/slundberg/SimplePlotPerf.jl.svg?branch=master)](https://travis-ci.org/slundberg/SimplePlotPerf.jl)

A collection of performance plotting routines based on SimplePlot.

## Example

```julia
prplot([
    ("Method 1", scores1),
    ("Method 2", scores2)
], labels)
```

```julia
x,y = precisionrecall(sortedLabels)
SimplePliotPerf.area_under_curve(x,y)
```
