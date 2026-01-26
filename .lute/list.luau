local collectProjects = require "@monorepo/collectProjects"
local exit = require "@lib/utils/exit"

local _, projectNames = collectProjects()
print(table.concat(projectNames, ", "))

exit(0)
