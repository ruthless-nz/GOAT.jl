
"""
    Goat 
Generic Optimisation Allocation Tool
"""
module Goat

using DataFrames
using CSV
using StatsBase
using Statistics
using JuMP
using GLPK
using GLM

export rawScore, GOAT, goatInit, costMatrix, goatInputs!, goatOptMax!, goatAllocations, goatAssess

include("allocations.jl")

end # module goat

