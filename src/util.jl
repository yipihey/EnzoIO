
import Base.log2 # extend to use with vectors
function log2(elements::Vector{Float64})
    return [log2(el) for el in elements]
end

