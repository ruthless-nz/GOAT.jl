# Guide to GOAT

The Generic Optimiation Allocation Tool is designed to do one thing. Allocate things to each other in a way that is accessible, generic and easy.  
This guide should help you to get started. 


 ## Installation

Goat can be installed using the Julia package manager.
From the Julia REPL, type `]` to enter the Pkg REPL mode and run

```
pkg> add Goat
```

Alternatively, if you're inside ACC:

```
pkg> add https://github.com/data-and-analytics-accnz/Goat.jl
```


## Project Allocation Example

#### Data
Here we have a list of staff, who have a variety of attributes and skills 

```julia
using Goat, CSV, DataFrames
# sample data:
empPath = joinpath(@__DIR__, "..", "data","Final_Employees_Data.csv" )
emp = DataFrame(CSV.File(empPath,stringtype = String,missingstring=" "))
```
```R

20×14 DataFrame
 Row │ Eid    Ename                Experience  Total_projects  Rating    Area_of_Interest_1  Area_of_Interest_2  Area_of_Interest_3  AI_project_count  ML_project_count  JS_project_count  Java_project_count  DotNet_project_count  Mobile_project_count 
     │ Int64  String               Int64       Int64           Float64   String              String              String              Int64             Int64             Int64             Int64               Int64                 Int64
─────┼────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
   1 │     1  Dana Bond                     2               2  1.0       DotNet              JS                  AI                                 0                 1                 1                   0                     0                     0
   2 │     2  Jesus Hampton                 9              13  1.44444   DotNet              AI                  JS                                 4                 3                 0                   2                     3                     1
   3 │     3  Teresa Munoz                 15              16  1.06667   ML                  JS                  Java                               3                 3                 1                   3                     5                     1
   4 │     4  Annette Dipietro             18              19  1.05556   DotNet              ML                  Mobile                             4                 4                 2                   3                     3                     3
   5 │     5  Jennifer Fortner             22              15  0.681818  Mobile              Java                JS                                 3                 4                 3                   1                     1                     3
  ⋮  │   ⋮             ⋮               ⋮             ⋮            ⋮              ⋮                   ⋮                   ⋮                  ⋮                 ⋮                 ⋮                  ⋮                    ⋮                     ⋮
  17 │    17  Charles Vine                 15               6  0.4       AI                  Mobile              ML                                 2                 1                 2                   1                     0                     0
  18 │    18  John Peters                  16              19  1.1875    DotNet              JS                  Mobile                             6                 1                 3                   3                     2                     4
  19 │    19  Lawrence Litzenberg          21              21  1.0       Java                ML                  JS                                 2                 3                 6                   5                     4                     1
  20 │    20  Michael Harpole              22              23  1.04545   AI                  Mobile              DotNet                             3                 1                 8                   5                     5                     1
                                                                                                                                                                                                                                           11 rows omitted
```

  
And a variety of projects roles that need people assigned to them.

  
```julia
# sample data:
projectPath = joinpath(@__DIR__, "..", "data","Project_details.csv" )
project = DataFrame(CSV.File(projectPath,stringtype = String,missingstring=" "))
```
```R

29×5 DataFrame
 Row │ PID    Project_name       Role             Primary_Skill  all skills       
     │ Int64  String             String           String         String
─────┼────────────────────────────────────────────────────────────────────────────
   1 │     1  AI Discovey Spike  Team Lead        AI             AI,ML,
   2 │     2  AI Discovey Spike  Programmer-1     AI             AI,ML,
   3 │     3  AI Discovey Spike  Programmer-1     AI             AI,ML,
   4 │     4  AI Discovey Spike  Project Manager
   5 │     5  AI Discovey Spike  Programmer-3     ML             AI,ML,
  ⋮  │   ⋮            ⋮                 ⋮               ⋮               ⋮
  26 │    26  Website BAU        Programmer-2     JS             DotNet,JS,Mobile
  27 │    27  Website BAU        Programmer-2     DotNet         DotNet,Java,JS
  28 │    28  Full Stack BAU     Programmer-1     DotNet         DotNet,Java,JS
  29 │    29  Full Stack BAU     Programmer-1     Java           DotNet,Java,JS
                                                                   20 rows omitted

```

#### Problem

How can we find the best allocation of staff to these projects in order to maximise our resources? 

Well, first of all, a few assumptions: All roles need to be assigned someone. Given that the number of roles 
is greater that the number of people, some people will need to get more than one role. 



This makes projects the toAssign group, and the employees the nominees.
---

Now, we know we want to allow staff to be allocated at least twice. Lets make it 3 times for good measure.

```julia
# ok so first up, we want Employees to be able to be allocated more than once, (but not more than 3 times)
empSlots = DataFrame()
slots = 3

for i in 1:slots
    # add a slot number
    emp.slot .= i
    # append
    append!(empSlots,emp)
end

# For downstream use we add some blank columns
empSlots.blank .= 1
project.blank .= 1

@show size(empSlots,1)
60
```
This gives us a dataframe with all our employees 3x over, the only difference being the 'slot' that they have.  
We also add some null columns that will always be 1. This is to give us a column we can use to show that we are not doing anything...


Now that this is all set up, we can pass this into the [`goatInit`](@ref) function, where it can create an goat object:
We choose to look for a maximum value, so going fowards, our costs need to be positive for desirable behaviour, and negative for undesirable behaviour. 

```julia

projectAllocate = goatInit("Max",empSlots,"Eid",project,"PID")

```

#### Creating costs

when we have nominees who can be allocated more than once, a good technique is to apply a cost based on the slot of the nominee. This can generate behaviour so that generally every nominee gets assigned something before anyone gets two things assigned to them.

```julia
# having a person on a 3rd project can only happen in extreme cases
function slotCost(x,y)::Float64
    z = 0
    if x == 2
        z = -5
    elseif x == 3
        z = -15
    end
    return z
end
```