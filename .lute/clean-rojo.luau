local fs = require("@std/fs")
local json = require("@std/json")
local path = require("@std/path")

export type RojoPath = string | { optional: string }
export type RojoNode = { ["$path"]: RojoPath?, [string]: RojoNode }
export type RojoProject = {
	tree: RojoNode,
}

local function removePath(target: string)
	if fs.exists(target) then
		local type = fs.type(target)
		if type == "file" then
			fs.remove(target)
		elseif type == "dir" then
			for _, file in fs.listdirectory(target) do
				removePath(path.join(target, file.name))
			end
		end
	end
end

local function processNode(node: RojoNode)
	local path = node["$path"]
	if path then
		path = if type(path) == "string" then path else path.optional
		print("cleaning:", path)
		removePath(path)
	end

	for _, node in node do
		if type(node) == "table" then
			processNode(node)
		end
	end
end

local project = json.deserialize(fs.readfiletostring("default.project.json")) :: RojoProject
processNode(project.tree)
