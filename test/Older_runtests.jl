
include("EnzoIO.jl")
using EnzoIO, Revise

fname = "/Users/tabel/Downloads/DD0081/DD0081.hierarchy"
#@time gi = EnzoIO.parse_hierarchy_file(fname, ignore_binary=true)
@time gi = EnzoIO.parse_hierarchy_file(fname)

#gf = DataFrame(gi)


#fl = EnzoIO.getData(gi,["Density"])

@time xyz = xyzs(gi[10:1000])


#@time data = EnzoIO.getData(gi, ["Density", "Temperature"], dir="/Users/tabel/Downloads/") ;

#field_names = EnzoIO.list_field_names(gi[1], dir="/Users/tabel/Downloads/")

dummy = [1]
#df = DataFrame(x = xyz[:,1],y = xyz[:,2],z = xyz[:,3])
