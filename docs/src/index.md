# Goat.jl

Documentation for [Goat.jl](https://github.com/data-and-analytics-accnz/Goat.jl/) - Generic Optimisation Allocation Tool

# Introduction 

The Generic Optimisation Allocation Tool, or Goat, is an abstraction of a set of optimisation problems, and is loosely based on the [facility allocation problem](https://en.wikipedia.org/wiki/Facility_location_problem). 

With an Optimisation Allocation problem, we have entities (ToAssign) that need to be assigned to nominees (nominee) and we would like to find the optimal assignment of entities to nominees. (Maximum or Minimum)


* Each entitity will have a set of costs associated with the asignment to each nominee
* These costs are summed to getting a total cost that is then used to find the optimiation solution
* Only one entitity can be assigned to a nominee, and vice versa. - More on this later.



 