# This file gathers all Taylor-related interpolations

struct Taylor <: AbstractFunctionSpaceType end

FunctionSpace(::Val{:Taylor}, degree::Integer) = FunctionSpace(Taylor(), degree)

basis_functions_style(::FunctionSpace{<:Taylor}) = ModalBasisFunctionsStyle()

"""
Default version : the shape functions are "replicated". If `shape_functions` returns the vector `[λ₁; λ₂; λ₃]`, and if the `FESpace`
is of size `2`, then this default behaviour consists in returning the matrix `[λ₁ 0; λ₂ 0; λ₃ 0; 0 λ₁; 0 λ₂; 0 λ₃]`.
"""
function shape_functions(
    fs::FunctionSpace{<:Taylor},
    ::Val{N},
    shape::AbstractShape,
    ξ,
) where {N} #::Union{T,AbstractVector{T}} ,T<:Number
    if N == 1
        return _scalar_shape_functions(fs, shape, ξ)
    elseif N < MAX_LENGTH_STATICARRAY
        return kron(SMatrix{N, N}(1I), _scalar_shape_functions(fs, shape, ξ))
    else
        return kron(Diagonal([1.0 for i in 1:N]), _scalar_shape_functions(fs, shape, ξ))
    end
end
function shape_functions(
    fs::FunctionSpace{<:Taylor, D},
    n::Val{N},
    shape::AbstractShape,
) where {D, N}
    ξ -> shape_functions(fs, n, shape, ξ)
end

# Shared functions for all Taylor elements of some kind
"""
    shape_functions(::FunctionSpace{<:Taylor, 0}, ::AbstractShape, x)

Shape functions for any Taylor element of degree 0 :  ``\\hat{\\lambda}(\\xi) = 1``
"""
function _scalar_shape_functions(::FunctionSpace{<:Taylor, 0}, ::AbstractShape, ξ)
    return SA[1.0]
end

# Functions for Line shape
"""
    grad_shape_functions(::FunctionSpace{<:Taylor, 0}, ::Line, x)

Gradient (=derivative) of shape functions for Line Taylor element of degree 0 in a 1D space : ``\\nabla \\hat{\\lambda}(\\xi) = 0``
"""
function grad_shape_functions(::FunctionSpace{<:Taylor, 0}, ::Val{1}, ::Line, ξ)
    return SA[0.0]
end

"""
    shape_functions(::FunctionSpace{<:Taylor, 1}, ::Line, ξ)

Shape functions for Line Taylor element of degree 1 in a 1D space.

```math
\\hat{\\lambda}_1(\\xi) = 1 \\hspace{1cm} \\hat{\\lambda}_1(\\xi) = \\frac{\\xi}{2}
```
"""
function _scalar_shape_functions(::FunctionSpace{<:Taylor, 1}, ::Line, ξ)
    return SA[
        1.0
        ξ[1] / 2
    ]
end

"""
    grad_shape_functions(::FunctionSpace{<:Taylor, 1}, ::Line, ξ)

Gradient (=derivative) of shape functions for Line Taylor element of degree 1 in a 1D space.

```math
\\nabla \\hat{\\lambda}_1(\\xi) = 0 \\hspace{1cm} \\nabla \\hat{\\lambda}_1(\\xi) = \\frac{1}{2}
```
"""
function grad_shape_functions(::FunctionSpace{<:Taylor, 1}, ::Val{1}, ::Line, ξ)
    return SA[
        0.0
        1.0 / 2.0
    ]
end

# Functions for Square shape
"""
    grad_shape_functions(::FunctionSpace{<:Taylor, 0}, ::Union{Square,Triangle}, ξ)

Gradient of shape functions for Square or Triangle Taylor element of degree 0 in a 2D space.

```math
\\hat{\\lambda}_1(\\xi, \\eta) = \\begin{pmatrix} 0 \\\\ 0 \\end{pmatrix}
```
"""
function grad_shape_functions(
    ::FunctionSpace{<:Taylor, 0},
    ::Val{1},
    ::Union{Square, Triangle},
    ξ,
)
    return SA[0.0 0.0]
end

"""
    shape_functions(::FunctionSpace{<:Taylor, 1}, ::Square, ξ)

Shape functions for Square Taylor element of degree 1 in a 2D space.

```math
\\begin{aligned}
    & \\hat{\\lambda}_1(\\xi, \\eta) = 0 \\\\
    & \\hat{\\lambda}_2(\\xi, \\eta) = \\frac{\\xi}{2} \\\\
    & \\hat{\\lambda}_3(\\xi, \\eta) = \\frac{\\eta}{2}
\\end{aligned}
```
"""
function _scalar_shape_functions(::FunctionSpace{<:Taylor, 1}, ::Square, ξ)
    return SA[
        1.0
        ξ[1] / 2
        ξ[2] / 2
    ]
end

"""
    grad_shape_functions(::FunctionSpace{<:Taylor, 1}, ::Square, ξ)

Gradient of shape functions for Square Taylor element of degree 1 in a 2D space.

```math
\\begin{aligned}
    & \\nabla \\hat{\\lambda}_1(\\xi, \\eta) = \\begin{pmatrix} 0 \\\\ 0 \\end{pmatrix} \\\\
    & \\nabla \\hat{\\lambda}_2(\\xi, \\eta) = \\begin{pmatrix} \\frac{1}{2} \\\\ 0 \\end{pmatrix} \\\\
    & \\nabla \\hat{\\lambda}_3(\\xi, \\eta) = \\begin{pmatrix} 0 \\\\ \\frac{1}{2} \\end{pmatrix}
\\end{aligned}
```
"""
function grad_shape_functions(::FunctionSpace{<:Taylor, 1}, ::Val{1}, ::Square, ξ)
    return SA[
        0.0 0.0
        1.0/2 0.0
        0.0 1.0/2
    ]
end

# Number of dofs
ndofs(::FunctionSpace{<:Taylor, N}, ::Line) where {N} = N + 1
ndofs(::FunctionSpace{<:Taylor, 0}, ::Union{Square, Triangle}) = 1
ndofs(::FunctionSpace{<:Taylor, 1}, ::Union{Square, Triangle}) = 3

# For Taylor base there are never any dof on vertex, edge or face
function idof_by_vertex(::FunctionSpace{<:Taylor, N}, shape::AbstractShape) where {N}
    fill(Int[], nvertices(shape))
end

function idof_by_edge(::FunctionSpace{<:Taylor, N}, shape::AbstractShape) where {N}
    ntuple(i -> SA[], nedges(shape))
end
function idof_by_edge_with_bounds(
    ::FunctionSpace{<:Taylor, N},
    shape::AbstractShape,
) where {N}
    ntuple(i -> SA[], nedges(shape))
end

function idof_by_face(::FunctionSpace{<:Taylor, N}, shape::AbstractShape) where {N}
    ntuple(i -> SA[], nfaces(shape))
end
function idof_by_face_with_bounds(
    ::FunctionSpace{<:Taylor, N},
    shape::AbstractShape,
) where {N}
    ntuple(i -> SA[], nfaces(shape))
end