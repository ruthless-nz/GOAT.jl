
using Goat, CSV, DataFrames

# load data from CSV
empPath = joinpath(@__DIR__, "..", "data","Final_Employees_Data.csv" )
emp = DataFrame(CSV.File(empPath,stringtype = String,missingstring=" "))


names(emp)

projectPath = joinpath(@__DIR__, "..", "data","Project_details.csv" )
project = DataFrame(CSV.File(projectPath,stringtype = String,missingstring=" "))

# Ok so we have a bunch of staff, and we have a bunch of projects that we need to assign staff too. 
# While the details of the business may change, in this case we need to do all of these projects, so some staff will be on two

# Given some attributes of the projects, and the attributes of the staff, who should we assign to what projects?

# This makes the project what we need to assign, and the staff the nominees
names(emp)
names(project)

# ok so first up, we want Employees to be able to be allocated more than once, (but not more than 3 times)
empSlots = DataFrame()
slots = 3

for i in 1:slots
    # add a slot number
    emp.slot .= i
    # append
    append!(empSlots,emp)
end

@show size(empSlots,1)

# For downstream use we add some blank columns
empSlots.blank .= 1
project.blank .= 1

# Now we can feed this into the Init
projectAllocate = goatInit("Max",empSlots,"Eid",project,"PID")

# Cool, so now we want to define some rules and costs to feed into the allocation

# We want peoples first slot filled first, and apply some pressure for everyone to 
# have a job before people get put on a second project. 

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

# if a person has an interest in the subject, lets give them a hoon

function interest1(x::String,y::String)::Float64
    z = 0
    if uppercase(x) == uppercase(y)
        z = 2
    end
    return z
end
function interest2(x::String,y::String)::Float64
    z = 0
    if uppercase(x) == uppercase(y)
        z = 1.5
    end
    return z
end
function interest3(x::String,y::String)::Float64
    z = 0
    if uppercase(x) == uppercase(y)
        z = 1
    end
    return z
end

# However we want experience to trump that.


function generalExperience(x,y)

    log(2,x)

end


goatInputs!(
    projectAllocate,
["SlotCost", :slot,:blank,slot],
["Interest1",:Area_of_Interest_1 ,:Primary_Skill ,interest1],
["Interest2",:Area_of_Interest_2 ,:Primary_Skill ,interest2],
["Interest3",:Area_of_Interest_3 ,:Primary_Skill ,interest3],
["generalExperience",:Total_projects ,:blank ,generalExperience],
)

# We can then run the allocation and assess it
goatOptMax!(projectAllocate)
goatAssess(projectAllocate)

# Get the matched ID's out
allocations = goatAllocations(projectAllocate)[!,2:3]

leftjoin!(allocations,emp, on = :Eid)
leftjoin!(allocations,project, on = :PID,makeunique=true)
allocations



# ok so some of these are bad

# Lets try a more sophisticated example
empSlots.Area_of_Interest .= string.(empSlots.Area_of_Interest_1,",",empSlots.Area_of_Interest_2,",",empSlots.Area_of_Interest_3)

projectAllocate2 = goatInit("Max",empSlots,"Eid",project,"PID")

function interest(x,y)
    # split into vec by comma
    x_vec = split(x,",")
    y_vec = split(y,",")
    # find the amount of overlap and add an exponenet to make it stronger
    z = length(intersect(x_vec,y_vec))^1.5

    return z
end

# lets also add a more specific experience function
function experience_AI(x,y)  
    z = 0
    if contains(y,"AI")
        z = max(log(2,x),0) 
    end
    return z   
end

function experience_ML(x,y)
    z = 0
    if contains(y,"ML")
        z = max(log(2,x),0) 
    end
    return z   
end

function experience_JS(x,y)
    z = 0
    if contains(y,"JS")
        z = max(log(2,x),0) 
    end
    return z   
end

function experience_Java(x,y)   
    z = 0
    if contains(y,"Java")
        z = max(log(2,x),0) 
    end
    return z   
end

function experience_DotNet(x,y)   
    z = 0
    if contains(y,"DotNet")
        z = max(log(2,x),0) 
    end
    return z  
end

function experience_Mobile(x,y)  
    z = 0
    if contains(y,"Mobile")
        z = max(log(2,x),0) 
    end
    return z   
end


goatInputs!(
    projectAllocate2,
["SlotCost", :slot,:blank,slot],
["Interest",:Area_of_Interest ,"all skills" ,interest],
# ["Interest2",:Area_of_Interest_2 ,:Primary_Skill ,interest2],
# ["Interest3",:Area_of_Interest_3 ,:Primary_Skill ,interest3],
# ["generalExperience",:Total_projects ,:blank ,generalExperience],
["experience_AI",:AI_project_count ,"all skills" ,experience_AI],
["experience_ML",:AI_project_count ,"all skills" ,experience_ML],
["experience_JS",:AI_project_count ,"all skills" ,experience_JS],
["experience_Java",:AI_project_count ,"all skills" ,experience_Java],
["experience_DotNet",:AI_project_count ,"all skills" ,experience_DotNet],
["experience_Mobile",:AI_project_count ,"all skills" ,experience_Mobile],
)

# We can then run the allocation and assess it
goatOptMax!(projectAllocate2)
goatAssess(projectAllocate2)

# Get the matched ID's out

goatAllocations(projectAllocate2)
allocations2 = goatAllocations(projectAllocate2)[!,2:5]

leftjoin!(allocations2,emp, on = :Eid)
leftjoin!(allocations2,project, on = :PID,makeunique=true)
sort(allocations2,:total_score, rev = true)

project
emp

max(log(2,0),0) 