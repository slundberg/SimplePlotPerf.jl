module SimplePlotPerf

using SimplePlot

export prplot

function precisionrecall(sortedLabels; samplePoints=nothing)
    p = Float64[]
    r = Float64[]
    totalRight = sum(sortedLabels)
    foundRight = 0
    for i in 1:length(sortedLabels)
        foundRight += sortedLabels[i]
        push!(p, foundRight/i)
        push!(r, foundRight/totalRight)
    end

    if samplePoints == nothing
        return r,p
    else

        # re-sample the curve at the given recall points
        pout = zeros(length(samplePoints))
        ind = 1
        lastp = p[1]
        lastr = r[1]
        for i in 1:length(samplePoints)
            while samplePoints[i] > r[ind] && ind < length(r)
                lastp = p[ind]
                lastr = r[ind]
                ind += 1
            end
            if samplePoints[i] <= r[ind]
                # pick the nearest recall point
                pout[i] = r[ind]-samplePoints[i] < lastr-samplePoints[i] ? p[ind] : lastp
            else
                pout[i] = lastp # we are past any recorded recall points
            end
        end
        return samplePoints,pout
    end
end
function precisionrecall(pred, labels; samplePoints=nothing)
    @assert length(pred) == length(labels)
    precisionrecall(labels[sortperm(pred, rev=true)], samplePoints=samplePoints)
end

function prplot(methods::Dict, truth, samplePoints=linspace(0,1,200))
    rmean = zeros(length(samplePoints))
    pmean = zeros(length(samplePoints))
    layers = Any[]
    #truth = methods[first(keys(methods))][1]
    numRandom = 10
    for i in 1:numRandom
        r,p = precisionrecall(rand(length(truth)), truth, samplePoints=samplePoints)
        rmean .+= r
        pmean .+= p
        #aucValue = @sprintf("%0.03f", MLBasePlotting.area_under_curve(xvals, yvals))
        push!(layers, line(r, p, color="#cccccc"))
    end
    rmean ./= numRandom
    pmean ./= numRandom
    aucRand = @sprintf("%0.03f", area_under_curve(rmean, pmean))


    methodLayers = Any[]
    for k in keys(methods)
        r,p = precisionrecall(methods[k], truth, samplePoints=samplePoints)
        auc = @sprintf("%0.03f", area_under_curve(r, p))
        push!(methodLayers, line(r, p, label="$k (AUC $auc)", linewidth=2))
    end

    axis(
        methodLayers...,
        line(rmean, pmean, color="#666666", linewidth=2, label="Random (AUC $aucRand)"),
        layers...,
        xlabel="recall",
        ylabel="precision"
    )
end

# must be sorted by increasing x
function area_under_curve(x, y)
    area = 0.0
    for i in 2:length(x)
        area += (y[i-1]+y[i])/2 * (x[i]-x[i-1])
    end
    area
end

end # module
