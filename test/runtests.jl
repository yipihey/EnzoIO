using Test
using EnzoIO
using Logging

# Insert your tests here
@testset "EnzoIO Tests" begin
    # Test the Grid struct
    @testset "Grid tests" begin
        g = Grid()
        @test g.num == 1
        @test g.time ≈ 0.0
        g.data["vel"] = [1.0, 2.0, 4.0]
        # Add more tests specific to the Grid structure
    end

    # Test the Hierarchy struct
    @testset "Hierarchy tests" begin
        hi = Hierarchy()
        for i in 1:10
            cg = Grid()
            cg.num = i
            push!(hi.grids, cg)
        end
        @test hi.grids[10].num == 10
        @test hi.grids[2].num == 2
        @test hi.grids[2].LeftEdge[1] ≈ 0.0

        hi.grids[10].data["vel"] = [1.0, 2.0, 4.0]
        @test hi.grids[10].data["vel"] == [1.0, 2.0, 4.0]
        # Add more tests specific to the Hierarchy structure
    end


    # Test the handling of hierarchy files
    @testset "Hierarchy file tests" begin
        fname = "/Users/tabel/Downloads/DD0081/DD0081.hierarchy"
        @time hi = EnzoIO.parse_hierarchy_file(fname, ignore_binary=true)
        @info "Test read " * fname
    end

    # Test the HDF5 IO
    @testset "HDF5 IO tests" begin
        # Add tests to check reading and writing of HDF5 files
        # You could write a small HDF5 file, read it back in and check that the values are as expected
    end

end