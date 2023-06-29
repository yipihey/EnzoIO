using Test
using EnzoIO

# Insert your tests here
@testset "EnzoIO Tests" begin
    # Test the Grid struct
    @testset "Grid tests" begin
        g = Grid(1, 0.5, 0, [1, 1, 1], [1, 1, 1], 0, [10, 10, 10], 
            [0.0, 0.0, 0.0], [1.0, 1.0, 1.0], 5, 10, "testfile", 10, 20)
        @test g.num == 1
        @test g.time ≈ 0.5
        g.data["vel"] = [1., 2., 4.]
        # Add more tests specific to the Grid structure
    end

    # Test the HDF5 IO
    @testset "HDF5 IO tests" begin
        # Add tests to check reading and writing of HDF5 files
        # You could write a small HDF5 file, read it back in and check that the values are as expected
    end

    # Test the handling of hierarchy files
    @testset "Hierarchy file tests" begin
        # Add tests for your hierarchy file handling code
        # You could create a small test hierarchy file and check that it is parsed correctly
    end
end