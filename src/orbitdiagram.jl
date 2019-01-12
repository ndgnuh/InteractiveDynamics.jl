using DynamicalSystemsBase, Makie
using AbstractPlotting: textslider, modelmatrix

function interactive_orbitdiagram(ds::DiscreteDynamicalSystem,
    i::Int, p_index, p_min, p_max;
    density = 1000, u0 = get_state(ds), Ttr = 100, n = 100
    )

    # Initialization
    integ = integrator(ds)
    scene = Scene()
    pmin, pmax = p_min, p_max

    ui_n, n = textslider(
        round.(Int, range(10, stop=10000, length=1000)),"n", start=n)
    ui_T, Ttr = textslider(
        round.(Int, range(10, stop=10000, length=1000)),"Ttr", start=Ttr)
    ui_d, density = textslider(
        round.(Int, range(10, stop=10000, length=1000)),"density", start=density)
    ui_i, i = textslider(1:dimension(ds), "variable", start=i)

    od = minimal_od(integ, i[], p_index, pmin, pmax, density[], n[], Ttr[], u0)
    od_node = Node(od)
    # Scales for x and p:
    pdif = abs(pmax - pmin)
    xdif = begin
        xmin, xmax = extrema(o[2] for o in od)
        abs(xmax - xmin)
    end
    xdif = 1.0

    msize = Node(min(pdif, xdif) / 100.0) # replace 100.0 with slider

    scplot = scatter(od_node, markersize = msize)
    display(scplot)
    rect = select_rectangle(scplot)

    on(rect) do r
        pmin, xmin = r.origin
        pmax, xmax = r.origin + r.widths
        msize[] = min(abs(pmax - pmin), abs(xmax - xmin)) / 100.0 # replace 100.0 with slider
        od_node[] = minimal_od(
            integ, i[],  p_index, pmin, pmax,
            density[], n[], Ttr[], u0, xmin, xmax
        )

        AbstractPlotting.update_limits!(scplot, rect[])
        AbstractPlotting.update_cam!(scplot, (modelmatrix(scplot)) * boundingbox(scplot[Axis]))
    end
    hbox(vbox(ui_n, ui_T, ui_d, ui_i), scplot, parent=scene)
    display(scene)
    return od_node
end

function minimal_od(integ, i, p_index, pmin, pmax,
                    density::Int, n::Int, Ttr::Int, u0, xmin = -Inf, xmax = Inf)

    pvalues = range(pmin, stop = pmax, length = density)
    od = Vector{Point2f0}()
    @inbounds for p in pvalues
        DynamicalSystemsBase.reinit!(integ, u0)
        integ.p[p_index] = p
        DynamicalSystemsBase.step!(integ, Ttr)
        for z in 1:n
            DynamicalSystemsBase.step!(integ)
            x = integ.u[i]
            if xmin ≤ x ≤ xmax
                push!(od, Point2f0(p, integ.u[i]))
            end
        end
    end
    return od
end

ds = Systems.henon()
i = 1
p_index = 1
p_min = 0.8
p_max = 1.4

od_node = interactive_orbitdiagram(ds, i, p_index, p_min, p_max);

# TODO:
# add reset button that goes to the initial x0,p0
# add button to select which variable of the system is plotted
# make recomputation trigger each time one of the sliders is adjusted