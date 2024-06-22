
"""
rawScore(name::String,scoreMatrix::Matrix)

Holds the raw scores from a cost.

name is the name of the function that generateds the cost, as a string
scoreMatrix is the array of scores that the cost produces

It is used inside the goat struct to consistently hold the scores
"""
struct rawScore
name::String
scoreMatrix::Matrix
end

"""
goat(
    optSense::String
    nominees::DataFrame
    nomineesId::String
    toAssign::DataFrame
    toAssignId::String
    toAssignPrimaryId::String 

    rawScores::Array{rawScore}
    rawAllocation::Array
    allAllocationOut::DataFrame
)

Used to hold all the data for the optimisation problem and is an input to goat functions in this module. 

# Arguments
#### immutable
* `optSense`: The optimsation objective; `Max`, Or `Min` are the two options
* `nominees`: The DataFrame containing information about our Nominees
* `nomineesId`: The name of the column in `nominees` that is the Identifier for each Nominee
* `toAssign`: The DataFrame containing information about our assignees 
* `toAssignId`: The name of the column in `toAssign` that is the Identifier for each assignee
* `toAssignPrimaryId`: The name of the column in `toAssign` that is the Primary Identifier for each assignee
#### mutable
* `rawScores`: an array containing the rawScore type, used to hold information about the cost scores 
* `rawAllocation`: a binary array containg the raw allocation information
* `allAllocationOut`: A Dataframe containing allocation, score data and ID's for assignees and Nominees

It comes with a handy constructor function: `goatInit()`
"""
mutable struct GOAT
    # Constant values
    optSense::String
    nominees::DataFrame
    nomineesId::String
    toAssign::DataFrame
    toAssignId::String
    toAssignPrimaryId::String 
    # Mutable values 
rawScores::Array{rawScore}
rawAllocation::Array
allAllocationOut::DataFrame

end


"""
    goatInit(
        optSense::String,
        nominees::DataFrame,
        nomineesId::String,
        toAssign::DataFrame,
        toAssignId::String,
        toAssignPrimaryId::String = "")

Creates a Goat object with all the required information

# Arguments

* `optSense`: The optimsation objective; `Max`, Or `Min` are the two options
* `nominees`: The DataFrame containing information about our Nominees
* `nomineesId`: The name of the column in `nominees` that is the Identifier for each Nominee
* `toAssign`: The DataFrame containing information about our assignees 
* `toAssignId`: The name of the column in `toAssign` that is the Identifier for each assignee
* **Optional** `toAssignPrimaryId`: The name of the column in `toAssign` that is the Primary Identifier for each assignee,  

# Example

```julia
# Create sample data
nomineeDf = DataFrame( id = [1,2,3,4],   nomVal = [0,1,2,missing],)
toAssignDf = DataFrame( id = [1,2,3,4],assignVal= [2,3,4,5])

# call goat funct
goatInit("Max", nomineeDf, "id", toAssignDf, "id" )

```
"""
function goatInit(
optSense::String,
nominees::DataFrame,
nomineesId::String,
toAssign::DataFrame,
toAssignId::String,
toAssignPrimaryId::String = "")
# Pass the immutable objects through, and init the Mutable ones 

# If there is no PrimaryId then pass through the normal ID

# If there is no PrimaryId then pass through the normal ID, but give it an extra name
if toAssignPrimaryId == "" 
    toAssignPrimaryId = string("__",toAssignId)
    toAssign[!,toAssignPrimaryId] = toAssign[!,toAssignId]
end

if !(optSense in ["Min","Max"])
error("optSense has value $optSense, It needs to be either 'Min' or 'Max' ")
end

    GOAT(   optSense,
            nominees,
            nomineesId,
            toAssign,
            toAssignId,
            toAssignPrimaryId,
            Array{rawScore}(undef),
            Array{Int}(undef),
            DataFrame()
    );

end



"""
    costMatrix(nomineeDf::DataFrame,nomineeCol,toAssignDf::DataFrame,toAssignCol,func)

Takes two vectors of data from your nominee and ToAssign datasets,  
and returns a matrix of the scores for each element of nominee and  
toAssign through the  function proivided

The function should be able to take anything as an input, but must return a Float64

# Example

```julia
# Create sample function
function absAdd(x,y)::Float64
    z = abs(x) + abs(y) 
    if ismissing(z)
        z = 0
    end
    return z
end
# Create sample DataFrames
nomineeDf = DataFrame( id = [1,2,3,4],   nomVal = [0,1,2,missing],)
toAssignDf = DataFrame( id = [1,2,3,4],assignVal= [2,3,4,5])
# Example calling 
costMatrix(nomineeDf,"nomVal",toAssignDf,"assignVal",absAdd)

4×4 Matrix{Float64}:
 2.0  3.0  4.0  5.0
 3.0  4.0  5.0  6.0
 4.0  5.0  6.0  7.0
 0.0  0.0  0.0  0.0

```

"""
function costMatrix(nomineeDf::DataFrame,nomineeCol,toAssignDf::DataFrame,toAssignCol,func)

# Get lengths
dim_i = size(nomineeDf,1)
dim_j = size(toAssignDf,1)

# init matrix\
costs = zeros(dim_i,dim_j)

# loop through every bit of the martix and calc score
for i in 1:dim_i
    for j in 1:dim_j

        costs[i, j] = func(nomineeDf[!,nomineeCol][i],toAssignDf[!,toAssignCol][j])

    end
end

return costs
end

"""
    costMatrix(nomineeDf::DataFrame,nomineeCol,toAssignDf::GroupedDataFrame,toAssignCol,func,agg)

Takes two vectors of data from your nominee and ToAssign datasets,  
and returns a matrix of the scores for each element of nominee and  
the aggregate of each grouped element of toAssign through the function proivided

When `costMatrix` is used in Goat, agg will either be `maximum` or `minimum`, but can be any  
function that takes an `itr`

The function should be able to take anything as an input, but must return a Float64  

# Example

function absAdd(x,y)::Float64
    z = abs(x) + abs(y) 
    if ismissing(z)
        z = 0
    end
    return z
end
# Create sample DataFrames
nomineeDf = DataFrame( id = [1,2,3,4],   nomVal = [0,1,2,missing],)
toAssignDf = DataFrame( id = [1,2,3,4],assignVal= [2,3,4,5], primaryId = [1,1,2,2])
toAssignGdf = groupby(toAssignDf,"primaryId")
# Example calling 
costMatrix(nomineeDf,"nomVal",toAssignGdf,"assignVal",absAdd,maximum)

4×2 Matrix{Float64}:
 3.0  5.0
 4.0  6.0
 5.0  7.0
 0.0  0.0

```
"""
function costMatrix(nomineeDf::DataFrame,nomineeCol,toAssignGdf::GroupedDataFrame,toAssignCol,func,agg)
# Get lengths
dim_i = size(nomineeDf,1)
dim_j = size(toAssignGdf,1)

# init matrix\
costs = zeros(dim_i,dim_j)

# loop through every bit of the martix and calc score
for i in 1:dim_i
    for j in 1:dim_j

        costs[i, j] = agg(func.(nomineeDf[!,nomineeCol][i],toAssignGdf[j][!,toAssignCol]))

    end
end

return costs
end

# This decider function helps simplify which optSense we are using
function MaxOrMin(x::String)
if      x=="Max"
return maximum
elseif  x=="Min"
return minimum
end
end



"""
goatInputs!(goat::GOAT,x...)
This takes the GOAT Object, as well as a list of cols and functions

It is assumed that all cols exist in the assignee and toAssign dataframes

```
goatInputs!(
goatObject,
[costName, :assigneeCol1,:ToAssignCol1,Func1],
[costName, :assigneeCol2,:ToAssignCol2,Func2],
[costName, :assigneeCol3,:ToAssignCol3,Func3],
...,
)
```
"""
function goatInputs!(goat::GOAT,x...)

# Create objects to hold the values that we will create
scores = Array{rawScore}(undef, length(x))

# SHould probs do some validation on the inputs of x.
    # costnames need to be unique

# This checks if there is a valid clusterID to use
if goat.toAssignPrimaryId == goat.toAssignId
# If there is no cluster ID, everything will be scored seperately
for (i, value) in enumerate(x)            

@show value

    scores[i] = rawScore(string(value[1]),costMatrix(goat.nominees,value[2],goat.toAssign,value[3],value[4]))
end

return goat.rawScores=scores 
# If there is a cluster ID, clusters will be combined, and the max score across the cluster will be taken. 
elseif goat.toAssignPrimaryId != goat.toAssignId

clusters = groupby(goat.toAssign,goat.toAssignPrimaryId)

for (i, value) in enumerate(x)

    scores[i] = rawScore(string(value[1]),costMatrix(goat.nominees,value[2],clusters,value[3],value[4],MaxOrMin(goat.optSense)))


end
return goat.rawScores=scores 
end


# This is where it gets complicated. Ok so we treat the PI as like a cluster

end



"""
goatOptMax!(goat::goat)

Takes a goat object with scores, and performs an otimisation to find optimal maximum solution


"""
function goatOptMax!(goat::GOAT)


size(goat.rawScores) != ()  || error("No scores found. Try running `goatInputs!()` Prior to `goatOptMax!()` ")

# Sum all the rawscores into a single matrix that can be used in 
# the JuMP Programing framework
allScores = sum(raw.scoreMatrix for raw in goat.rawScores )

toAssign_j= size(allScores,2)
nominated_i= size(allScores,1)

# init the optimiser
allocation_problem = Model(GLPK.Optimizer)

# In our problem we expresss the set of decision variables as a Slots × Claims
# matrix named `allocations` so that it is easier to define the constraints and
# objective function in the aglebraic form expected by the JuMP package later
# on.
@variable(allocation_problem, allocations[1:nominated_i,1:toAssign_j], Bin)


# Basically, this means that every i'th needs to be allocated, ie project, or cases.
@constraint(
allocation_problem, 
toAssign[j in 1:toAssign_j], 
sum(allocations[i, j] for i in 1:nominated_i) == 1
)

# This ensures that each slot, ie staff, can only be assigned to one 'thing'

# So this means that specific subsets of decision variables must be less than or
# equal to 1. As before, because we expressed the set of decision variables as a
# Slots × Claims allocation matrix, this means the Slot rows of that matrix must
# be less than or equal to 1 - this is our second constraint.

@constraint(
allocation_problem, 
nominated[i in 1:nominated_i], 
sum(allocations[i, j] for j in 1:toAssign_j) <= 1
)

# The cost of allocating a specific claim to a specific slot (Allocation_Costₙ)
# has already been pre-computed and stored in the `costFunction` matrix. This
# matrix shares the same Slots × Claims dimension as the allocation decision
# variables (Allocateₙ) we named `allocations`. Because of this structure we can
# express Total_Cost as the element-wise multipication of the two matrices, then
# sum all the elements in that resulting product.
if goat.optSense == "Max"
println("Optimising for Maximum Value")
@objective(allocation_problem, Max , sum(allScores .* allocations));
elseif goat.optSense == "Min"
println("Optimising for Minumum Value")
@objective(allocation_problem, Min , sum(allScores .* allocations));
else 
error(" Optimisation Sense $opt not found. Try again with 'Max' or 'Min ")
end


# With the problem fully specified we can now run the optimisation to find the
# best allocation decisions, given the constraints and allocation costs.
optimize!(allocation_problem)


# println("Optimal value: ", objective_value(allocation_problem))
# @show 
summary = solution_summary(allocation_problem, verbose=true)
@show summary.solve_time
@show summary.termination_status
@show summary.primal_status
@show summary.raw_status
@show summary.objective_value

goat.rawAllocation = value.(allocations)

# ok so now we want to get a list of indices
df_allocated = DataFrame(cartesian_index = findall(x->x==1,goat.rawAllocation))
# and get an allocated field
df_allocated.allocated .= 1.0

# Create a cluster lookup and cluster keys to do the thing on
cluster_lookup = goat.toAssign[!,[goat.toAssignPrimaryId,goat.toAssignId]]
cluster_keys = unique(cluster_lookup[!,goat.toAssignPrimaryId])


# ok now lets pull out the IDs and cartesian idicies for our matricies
dim_i = size(goat.nominees,1)
dim_j = size(cluster_keys,1)

# init matricies with correct types
ID_nominees = Array{eltype(goat.nominees[!,goat.nomineesId]),2}(undef, dim_i, dim_j)
ID_toAssign = Array{eltype(cluster_keys),2}(undef, dim_i, dim_j)
index = Array{CartesianIndex{2},2}(undef, dim_i, dim_j)

# loop through every bit of the martix and put values there
for i in 1:dim_i
for j in 1:dim_j
    ID_nominees[i, j] = goat.nominees[!,goat.nomineesId][i]
    ID_toAssign[i, j] = cluster_keys[j]
    index[i, j] = CartesianIndex(i,j)
end
end
# and add these to the df
df = DataFrame(cartesian_index=vec(index))

df[!,goat.toAssignPrimaryId]=vec(ID_toAssign)
df[!,goat.nomineesId]=vec(ID_nominees)

# join on if a client was allocated or not
leftjoin!(df,df_allocated, on=:cartesian_index)
# remove missing
replace!(df.allocated,missing => 0)

# now we can drop the cartesian_index
select!(df, Not(:cartesian_index));

# Get the total score
df[!,"total_score"]= vec(allScores)

# and get the rest of the scores
for i in goat.rawScores
df[!,i.name] = vec(i.scoreMatrix)
end

# and join on the cluser keys
df2 = leftjoin(cluster_lookup,df, on = goat.toAssignPrimaryId)
goat.allAllocationOut = dropmissing(df2)

end

"""
goatAllocations(goat::goat)

This gets out a list of matched ID's (assuiming there is a solution)

"""
function goatAllocations(goat::GOAT)
filter(x->x.allocated==1,goat.allAllocationOut)
# filter(x->x.allocated==1,goat.allAllocationOut)[!,1:3]

end


"""
    goatAssess(goat::GOAT,family=Binomial(),link=ProbitLink())::DataFrame

Uses a GLM to assess the effects of the scores on the allocations.
This can be used to help see if some values are too large, or are having a minimal effect

There are two ways to read this:
General importance is for 'always on' variables. Ie a business score of business. 
'Coef.' is the metric that describes how generally important a score is
'z'     can be used to attribute importance for things that are not always applicable, like a previous owner 

'Pr(>|z|)' is used as a general check on the 'effectiveness' of a a variable. if this is too large ~ 0.1, then the variable might not be having too much impact

"""
function goatAssess(goat::GOAT,family=Binomial(),link=ProbitLink())::DataFrame


# Build a formula programatically from the names
formula_goat = Term(:allocated) ~ sum(term.(names(goat.allAllocationOut)[6:end]))

# We want to normalise all the scores
features = goat.allAllocationOut[!, names(goat.allAllocationOut)[6:end]]

for i in eachcol(features)
# apply a Zscore Transform to get mean of zero and STD of 1
dt = fit(ZScoreTransform,i, dims=1)
StatsBase.transform!(dt,i)
end
# and put the allocation outcome back on
features.allocated = goat.allAllocationOut.allocated

# And get the CoefTable out
logit = sort(DataFrame(coeftable(glm(formula_goat, features, family, link))),"Coef.", rev = true)[!,1:end-2]

filter(x->x.Name != "(Intercept)", logit)

end

