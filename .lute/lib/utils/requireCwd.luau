local path = require "@std/path"

local function requireCwd(modulePath: path.pathlike)
	return (require)(path.format(path.join("..", "..", "..", modulePath)))
end

return requireCwd
