# Define struct to represent grid
mutable struct Grid
    num::Int64
    time::Float64
    parent::Int64
    parent_s_index::Vector{Int}
    parent_e_index::Vector{Int}
    base2level::Int
    Dimension::Vector{Int64}
    LeftEdge::Vector{Float64}
    RightEdge::Vector{Float64}
    NumberOfBaryonFields::Int64
    NumberOfParticles::Int64
    FileName::String
    ngnl::Int64
    ngtl::Int64
    data::Dict()
end

import Base.getindex

function fcoord(cg::Grid, ax)
    # perform some operations with `grid`
    # always calculate all the coordinates (while we are at it)
    # just return the diffferent parts if called with x, y, or z instead of xyz. 
    ind = findfirst(ax, "xyz")[1]
    local dx = (cg.RightEdge .- cg.LeftEdge)/cg.Dimension
    ct = 1
    td = Dict()
    xyz = zeros(cg.Dimension... , 3)
    @inbounds for i in 1:cg.Dimension[1]
        @inbounds for j in 1:cg.Dimension[2]
            @inbounds for k in 1:cg.Dimension[3]
                xyz[i,j,k,1] = (i .- 0.5) * dx[1] + cg.LeftEdge[1]
                xyz[i,j,k,2] = (j .- 0.5) * dx[2] + cg.LeftEdge[2]
                xyz[i,j,k,3] = (k .- 0.5) * dx[3] + cg.LeftEdge[3]
                ct += 1
            end
        end
    end
    cg.data["xyz"] = xyz

    if ax == ""
        return
    elseif ax == "x"
        return cg.data["xyz"][:,1]    
    elseif ax == "y"
        return cg.data["xyz"][:,2]    
    elseif ax == "z"
        return cg.data["xyz"][:,3]    
    elseif ax == "xyz"
        return cg.data["xyz"]
    else 
        @warn "fccord: " * string(cg.num) * " called with ax=" * ax * " different from x,y,z,xyz"
        return 
    end
end

# Similarly, you can define functions for other fields.

# Here, define a dictionary of functions that correspond to data field names.
# For example, fcoord(grid::Grid,ax) is a function that takes a Grid instance and computes
# the floating point x,y,z coordinates

# The next step is to map these function names to the actual functions.
# Let's say `x` and `y` are the only special fields that correspond to functions. 
# You would create a dictionary like this:
const data_func_dict = Dict(
    "x" => fcoord,  # replace `x` with the actual function you have defined.
    "y" => fcoord,  # similarly for other functions
    "z" => fcoord,  # 
    "xyz" => fcoord
)

# Finally, override the getindex method for Grid instances:
function getindex(grid::Grid, key::String)
    if key in keys(grid.data)
        return grid.data[key]
    elseif key in keys(data_func_dict)
        # Here, `data_func_dict[key]` will give you the corresponding function,
        # and `(data_func_dict[key])(grid)` will call that function with `grid` as the argument.
        return (data_func_dict[key])(grid,key)
    else
        error("Key $key not found in grid data or in function dictionary. You may want to call getData first.")
    end
end
