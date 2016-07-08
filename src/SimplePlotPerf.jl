module SimplePlotPerf

using SimplePlot

export prplot,precisionrecall,kaplanmeier

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

function prplot(methods::AbstractArray, truth; samplePoints=linspace(0,1,200), auc=true,
        colors=SimplePlot.colors,
        randomMeanLayer=line(),
        randomSampleLayer=line(), kwargs...)
    rmean = zeros(length(samplePoints))
    pmean = zeros(length(samplePoints))
    layers = Any[]
    numRandom = 10
    for i in 1:numRandom
        r,p = precisionrecall(rand(length(truth)), truth, samplePoints=samplePoints)
        rmean .+= r
        pmean .+= p

        layerParams = merge(Dict(
            :color => "#cccccc"
        ), randomSampleLayer.params, randomSampleLayer.unusedParams)
        push!(layers, line(r, p; layerParams...))
    end
    rmean ./= numRandom
    pmean ./= numRandom
    aucRand = @sprintf("%0.03f", area_under_curve(rmean, pmean))

    methodLayers = Any[]
    for (ind,method) in enumerate(methods)
        r,p = nothing,nothing
        if typeof(method[2][1]) <: Array
            r = zeros(length(samplePoints))
            p = zeros(length(samplePoints))

            for member in method[2]
                rtmp,ptmp = precisionrecall(member, truth, samplePoints=samplePoints)
                r .+= rtmp
                p .+= ptmp
                layerParams = merge(Dict(
                    :color => colors[ind],
                    :alpha => 0.5,
                ))
                push!(layers, line(rtmp, ptmp; layerParams...))
            end
            r ./= length(method[2])
            p ./= length(method[2])
        else
            r,p = precisionrecall(method[2], truth, samplePoints=samplePoints)
        end

        aucStr = @sprintf("%0.03f", area_under_curve(r, p))
        layerParams = Dict{Any,Any}(
            :linewidth => 2,
            :color => colors[ind],
            :label => method[1]*(auc ? " (AUC $aucStr)" : "")
        )
        if length(method) > 2
            @assert typeof(method[3]) <: SimplePlot.LineLayer "Third slot for a method must be a template line layer"
            merge!(layerParams, method[3].params, method[3].unusedParams)
        end
        push!(methodLayers, line(r, p; layerParams...))
    end

    aucStr = @sprintf("%0.03f", area_under_curve(rmean, pmean))
    layerParams = merge(Dict(
        :color => "#666666",
        :linewidth => 2,
        :label => "Random"*(auc ? " (AUC $aucStr)" : "")
    ), randomMeanLayer.params, randomMeanLayer.unusedParams)
    axis(
        methodLayers...,
        line(rmean, pmean; layerParams...),
        layers...;
        xlabel="recall",
        ylabel="precision",
        kwargs...
    )
end

function kaplanmeier(times, events)
    xs = Float64[]
    ys = Float64[]

    probSurv = 1
    N = length(times)
    numEventsNow = 0
    lastTime = -1.0

    count = 0
    for i in sortperm(times)
        count += 1

        # if we have a new unique time point
        if times[i] != lastTime && lastTime >= 0.0
            numLeft = N-count+1
            probSurv *= (numLeft - numEventsNow)/numLeft
            numEventsNow = 0
            push!(xs, times[i])
            push!(ys, probSurv)
        end

        lastTime = times[i]
        numEventsNow += 1
    end
    xs,ys
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
