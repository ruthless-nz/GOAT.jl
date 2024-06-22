using Documenter
using Goat

makedocs(
    sitename = "Generic Optimisation Allocation Tool",
    pages = [
        "Overview" => "index.md",
        "Detailed Documentation" => "api.md",
        "Example" => "example.md",
     ],
    format = Documenter.HTML(),
    modules = [Goat]
)

# Documenter can also automatically deploy documentation to gh-pages.
# See "Hosting Documentation" and deploydocs() in the Documenter manual
# for more information.

deploydocs(
    repo ="" ,
    devbranch = "main"
)
