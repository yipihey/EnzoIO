mutable struct Hierarchy
    grids::Vector{Grid}

    Hierarchy() = new(Grid[]) # Empty array we push to
    # Additional constructor that creates an Hierarchy object of a specified size

end

function totalNumberOfCells(h::Hierarchy)
    Ncells = 0
    for cg in h.grids
        Ncells += cg.Dimension[1] *
                  maximum([1, cg.Dimension[2]]) *
                  maximum([1, cg.Dimension[3]]) # total number of cells
    end
    println("Total number of cells:", Ncells, " ~ ", round(Ncells^0.33334, digits=1), "^3 cells.")
    return Ncells
end

function fileListFromHierarchy(h::Hierarchy)
    # which files do we need
    flist = Set{String}()
    for cg in h.grids
        push!(flist, cg.FileName)
    end
    flist = sort(collect(flist))  # turns it into sorted array
    return flist
end

function set_levels(h::Hierarchy)
    ls = [Int(log2(Float64(BigFloat(cg.Dimension[1]) ./ (BigFloat(cg.RightEdge[1]) .- BigFloat(cg.LeftEdge[1])))))
          for cg in h.grids]
    for (i, cg) in enumerate(h.grids)
        cg.base2level = ls[i]
    end
    return ls
end

# Define set_parents
function set_parents(h::Hierarchy)
    parents = h.grids[findall(x -> x.ngnl > 0, h.grids)]
    if isempty(parents)
        return
    end
    np = length(parents)
    println(np, " parent grids.")
    for (i, cp) in enumerate(parents)
        index = cp.ngnl
        cg = h.grids[index]
        stopit = false
        dxp = (Vector{BigFloat}(cp.RightEdge) .- Vector{BigFloat}(cp.LeftEdge)) ./ Vector{BigFloat}(cp.Dimension)
        while !stopit
            cg.parent = cp.num # set parent
            for j in 1:length(cp.LeftEdge)
                cg.parent_s_index[j] = (BigFloat(cg.LeftEdge[j]) - BigFloat(cp.LeftEdge[j])) / dxp[j] + 1
                cg.parent_e_index[j] = (BigFloat(cg.RightEdge[j]) - BigFloat(cp.LeftEdge[j])) / dxp[j]
            end
            if (cg.ngtl > 0)
                cg = h.grids[cg.ngtl]
            else
                stopit = true
            end
        end
    end
end

function nan_parent_cells(h::Hierarchy; value=NaN)
    ind = findall(g -> g.parent == cg.num, h.grids)
    for ccg in h.grids[ind]
        if ccg != Nothing
            for v in vars
                cg.data[v][ccg.parent_s_index[1]:ccg.parent_e_index[1],
                    ccg.parent_s_index[2]:ccg.parent_e_index[2],
                    ccg.parent_s_index[3]:ccg.parent_e_index[3]] .= value
            end
        end
    end
end
