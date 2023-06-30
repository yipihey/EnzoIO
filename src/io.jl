function extractGridNumber(s::AbstractString)
    # helper function to parse the lines in .hierarchy that specify 
    # the NexgtGridThisLevel and NExtGridNextLevel pointers 
    match_obj = match(r"Grid\[(\d+)\]->", s)

    if match_obj != nothing
        num_str = match_obj.captures[1]
        num = parse(Int, num_str)
        return num
    else
        println("No match found.")
    end
end

function parse_hierarchy_grid_block(start::Int, stop::Int, file_lines::Vector{String}, ngtl::Dict{Int,Int}, ngnl::Dict{Int,Int})
    #    println(s)
    # Initialize an empty Grid and empty dictionary
    grid_dict = Dict()
    cg = Grid()

    for ct in start:stop
        line = file_lines[ct]
        kv_pair = split(strip(line), " = ")   # Split the line into key-value pair
        if length(kv_pair) != 2
            continue
        end
        key = strip(kv_pair[1])
        value = kv_pair[2]
        # If we encounter a new Grid line, store the current grid and create a new one
        # Update fields of current_grid with values from grid_dict

        if key == "Grid"
            grid_dict["num"] = parse(Int, value)
        elseif key == "Time"
            grid_dict["Time"] = parse(Float64, value)
        elseif key == "GridStartIndex" || key == "GridEndIndex"
            grid_dict[key] = readdlm(IOBuffer(value), Int)[:]
        elseif key == "GridLeftEdge" || key == "GridRightEdge"
            grid_dict[key] = readdlm(IOBuffer(value), Float64)[:]
        elseif key == "BaryonFileName" || key == "ParticleFileName"
            grid_dict[key] = value
        elseif key == "NumberOfBaryonFields" || key == "NumberOfParticles"
            grid_dict[key] = parse(Int, value)
        elseif occursin("NextGridThisLevel", key)
            ngtl[extractGridNumber(key)] = parse(Int, value)
        elseif occursin("NextGridNextLevel", key)
            ngnl[extractGridNumber(key)] = parse(Int, value)
        end
    end
    cg.num = grid_dict["num"]
    cg.time = grid_dict["Time"]
    cg.Dimension = grid_dict["GridEndIndex"] - grid_dict["GridStartIndex"] .+ 1
    cg.LeftEdge = grid_dict["GridLeftEdge"]
    cg.RightEdge = grid_dict["GridRightEdge"]
    if haskey(grid_dict, "BaryonFileName")
        cg.FileName = grid_dict["BaryonFileName"]
    elseif haskey(grid_dict, "ParticleFileName")
        cg.FileName = grid_dict["ParticleFileName"]
    end
    cg.NumberOfBaryonFields = grid_dict["NumberOfBaryonFields"]
    cg.NumberOfParticles = grid_dict["NumberOfParticles"]

    return cg
end

function parse_hierarchy_file(filepath; ignore_binary=false)
    # use the optional named keyword ignore_binary=true when debugging the parsing routines.
    # without it we store the parsed file into a a new .hierarchy.bin file which we read instead
    # of the .hierarchy file next time. This can save a lot of time for large hierarchies or slow
    # file systems. 
    binary_hierarchy = filepath * ".bin"
    if isfile(binary_hierarchy) && !ignore_binary
        println("found " * binary_hierarchy * ". Will read that.")
        @time hi = deserialize(binary_hierarchy)
        return hi
    else
        println("Time to read .hierarchy file:")
        file_lines = readlines(filepath)

        # Get the line numbers at which "Grid =" occurs
        grid_line_nums = findall(occursin("Grid = "), file_lines)
        # Calculate the number of grids
        num_grids = length(grid_line_nums)

        # Append the last line number 
        push!(grid_line_nums, length(file_lines))

        # Initialize empty array to store Grid structs
        grids = Vector{Grid}(undef, num_grids)
        # Dictionaries to hold NextGridThisLevel and NextGridNextLevel pointers
        ngtl = Dict{Int,Int}()
        ngnl = Dict{Int,Int}()
        # 
        block_indices = [(grid_line_nums[i], grid_line_nums[i+1]) for i in 1:num_grids]

        for i in 1:num_grids
            indices = block_indices[i]
            grids[i] = parse_hierarchy_grid_block(indices[1], indices[2], file_lines, ngtl, ngnl)
        end

        for i in 1:num_grids  # fill in values that define the tree of grids
            grids[i].ngtl = ngtl[i]
            grids[i].ngnl = ngnl[i]
        end

        hi = Hierarchy()
        hi.grids = grids
        println("Time to set parents:")
        @time set_parents(hi)

        set_levels(hi)

        println("serialize:")
        try
            open(binary_hierarchy, "w") do io
                serialize(io, hi) # write parsed version to save time next time
                @info "Wrote " * binary_hierarchy
            end
        catch e
            @warn "An error occurred writing the binary hierachy: " * binary_hierarchy * e
        end

        return hi

    end
end

function getData(h::Hierarchy,
    vars::Vector{T};
    dir="./",  # directory from which gi.FileName describe the path
    nan_parent_cells=true # parent cells that also cover region have values set to NaN
) where {T<:AbstractString}
    # This routine sorts the access so that it opens each file only once and opens groups sequentially
    # This is faster than looping over grids and having each of them open and close files, groups. 
    flist = fileListFromHierarchy(h)
    ct = 0
    for fnow in flist
        gnums = findall(x -> x.FileName == fnow, h.grids)
        h5open(dir * fnow, "r") do file
            for cg in h.grids[gnums]
                gstring = "Grid" * string(cg.num, pad=8)
                g = g_open(file, gstring)
                for v in vars
                    gdata = read(g, v)
                    cg.data[v] = gdata
                end
                ct += 1
            end
            #        println(fnow, " ", ct, " grids.")
        end
    end
end

function getData(cg::Grid,
    vars::Vector{T};
    dir="./",  # directory from which gi.FileName describe the path
    nan_parent_cells=true # parent cells that also cover region have values set to NaN
) where {T<:AbstractString}
    flist = [cg.FileName]
    ct = 0
    for fnow in flist
        h5open(dir * fnow, "r") do file
            @info "getData: Opened " * dir * fnow
            gstring = "Grid" * string(cg.num, pad=8)
            g = g_open(file, gstring)
            for v in vars
                gdata = read(g, v)
                cg.data[v] = gdata
            end
            ct += 1
        end
    end
end

function list_field_names(cg::Grid; dir="")
    h5open(dir * cg.FileName, "r") do file
        gstring = "Grid" * string(cg.num, pad=8)
        g = g_open(file, gstring)
        return names(g)
    end
end