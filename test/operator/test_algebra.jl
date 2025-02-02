@testset "Algebra" begin
    @testset "Gradient" begin
        # We test the mapping of a gradient. The idea is to compute the integral of a function `f` whose
        # gradient is constant. Then the result must be this constant multiplied by the cell area.
        # But since we need to input a `ReferenceFunction`, we need to build `f ∘ F` where `F` is the mapping.
        # We also need a geometric function to compute the area of a convex quad.
        function convex_quad_area(cnodes)
            n1, n2, n3, n4 = cnodes
            return (
                abs((n1.x[1] - n3.x[1]) * (n2.x[2] - n4.x[2])) +
                abs((n2.x[1] - n4.x[1]) * (n1.x[2] - n3.x[2]))
            ) / 2
        end

        cnodes = [Node([0.0, 0.0]), Node([1.0, 0.0]), Node([2.0, 1.5]), Node([1.0, 1.5])]
        celltypes = [Quad4_t()]
        cell2node = Connectivity([4], [1, 2, 3, 4])
        mesh = Mesh(cnodes, celltypes, cell2node)
        # mesh = one_cell_mesh(:quad)

        c2n = connectivities_indices(mesh, :c2n)
        icell = 1
        cnodes = get_nodes(mesh, c2n[icell])
        ctype = cells(mesh)[icell]
        cInfo = CellInfo(mesh, icell)

        qDegree = Val(2)

        # Scalar test : gradient of scalar `f` in physical coordinates is [1, 2]
        function f1(ξ)
            x, y = mapping(cnodes, ctype, ξ)
            return x + 2y
        end
        g = ReferenceFunction(f1)

        _g = Bcube.materialize(∇(g), cInfo)
        res = Bcube.integrate_on_ref(_g, cInfo, Quadrature(qDegree))
        @test all(isapprox.(res ./ convex_quad_area(cnodes), [1.0, 2.0]))

        # Vector test : gradient of vector `f` in physical coordinates is [[1,2],[3,4]]
        function f2(ξ)
            x, y = mapping(cnodes, ctype, ξ)
            return [x + 2y, 3x + 4y]
        end
        g = ReferenceFunction(f2)

        _g = Bcube.materialize(∇(g), cInfo)
        res = Bcube.integrate_on_ref(_g, cInfo, Quadrature(qDegree))
        @test all(isapprox.(res ./ convex_quad_area(cnodes), [1.0 2.0; 3.0 4.0]))
    end
end
