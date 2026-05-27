local cli = require("@batteries/cli")
local fs = require("@std/fs")
local path = require("@std/path")
local process = require("@std/process")
local repositoryConfig = require("@lib/utils/repositoryConfig")()
local richterm = require("@batteries/richterm")
local run = require("@lib/utils/run")
local stringext = require("@std/stringext")
local toml = require("@batteries/toml")

export type Wally = { dependencies: { [string]: string? } }

local args = cli.parser()
args:add("script", "positional", { help = "This script", required = true })
args:add("subcommand", "positional", { help = "One of: apply, init, deinit, generate, regenerate", required = true })
args:add("alias", "positional", { help = "Alias of package to path" })
args:parse({ ... })

local packagesDir = repositoryConfig.wth.dirs.packages
local patchesDir = repositoryConfig.wth.dirs.patches

local function formatPackageDir(dirName: string)
	return path.join(packagesDir, "_Index", dirName)
end

local function collectRejects(dir: path.Pathlike): { path.Pathlike }
	local rejects = {}
	for _, entry in fs.listDirectory(dir) do
		local child = path.join(dir, entry.name)
		if entry.type == "dir" then
			local childRejects = collectRejects(child)
			table.move(childRejects, 1, #childRejects, #rejects, rejects)
		elseif string.find(entry.name, "%.rej$") then
			table.insert(rejects, child)
		end
	end
	return rejects
end

local function applyPatch(
	patchFilepath: path.Pathlike,
	patchTo: path.Pathlike
): ("ok" | "conflicts" | "failed", string, { path.Pathlike })
	local apply = run("git", { "apply", "--directory", patchTo, patchFilepath }, { ignoreFailure = true, quiet = true })
	if apply.ok then
		return "ok", apply.stdout, {}
	end

	local conflicts = run(
		"git",
		{ "apply", "--reject", "--directory", patchTo, patchFilepath },
		{ ignoreFailure = true, quiet = true }
	)

	local rejects = collectRejects(patchTo)
	if #rejects > 0 then
		return "conflicts", apply.stderr, rejects
	elseif conflicts.ok then
		return "ok", conflicts.stdout, {}
	else
		-- assume patch can't be applied
		return "failed", apply.stderr, {}
	end
end

local function applyPatches()
	local patchFiles: { { path: path.Path, name: string, dirName: string } } = {}
	for _, file in fs.listDirectory(patchesDir) do
		local dirName = string.match(file.name, "([%w%-]+_[%w%-]+@%d+%.%d+%.%d+)_?%d*%.patch$")
		if dirName then
			table.insert(patchFiles, { path = path.join(patchesDir, file.name), name = file.name, dirName = dirName })
		end
	end

	table.sort(patchFiles, function(lhs, rhs)
		return (lhs.name :: string) < (rhs.name :: string)
	end)

	print(richterm.dim("Applying patches..."))
	local failed = false
	for _, patch in patchFiles do
		local packageDir = formatPackageDir(patch.dirName)
		local printPrefix = richterm.bold(patch.name)
		if not fs.exists(packageDir) then
			print(printPrefix, richterm.yellow(`Missing package directory for {patch.dirName}`))
		end

		local result, stdout, rejects = applyPatch(patch.path, packageDir)
		if result == "ok" then
			print(printPrefix, richterm.cyan(`OK`))
			continue
		elseif result == "conflicts" then
			print(printPrefix, richterm.red(`Conflicts with upstream package:`))
			for _, reject in rejects do
				print(richterm.red(`  - {reject}`))
			end
		else
			print(printPrefix, richterm.red(`Failed to apply:`))
			print("  " .. richterm.dim((stringext.trim(stdout):gsub("\n", "\n  "))))
		end

		failed = true
	end

	print()
	if failed then
		print("Resolve conflicting patches (or apply .rejs manually)")
		print("Once done, regenerate individual patches by running:")
		print()
		print("  " .. richterm.cyan("lute patch regenerate <alias>"))
		process.exit(1)
	else
		print(richterm.green("Successfully applied all patches!"))
	end
end

local function initializePatch(alias: string, dirPath: path.Pathlike)
	print(richterm.dim("Initializing package for patching..."))
	run("git", { "init" }, { cwd = dirPath })
	run("git", { "add", "-A" }, { cwd = dirPath })
	run("git", { "commit", "-m", "original" }, { cwd = dirPath })

	print()
	print(richterm.green("Package initialized for patching!"))
	print("Make your changes in the following folder")
	print()
	print("  " .. richterm.cyan(path.format(dirPath)))
	print()
	print("Once you're done with your changes, run:")
	print()
	print("  " .. richterm.cyan(`lute patch generate {alias}`))
	print()
end

local function deinitializePatch(dirPath: path.Pathlike)
	pcall(fs.removeDirectory, path.join(dirPath, ".git"), { recursive = true })
	print(richterm.green("Deinitialized package!"))
	print(richterm.dim("Consider rerunning `lute install` before initializing a new patch."))
end

local function generatePatch(dirName: string, dirPath: path.Pathlike)
	run("git", { "add", "-A" }, { cwd = dirPath })
	local diff = run("git", { "diff", "--cached" }, { cwd = dirPath, captureOutput = true }).stdout
	fs.removeDirectory(path.join(dirPath, ".git"), { recursive = true })

	if diff == "" or diff == "\n" then
		print(richterm.yellow("No changes detected. There is nothing to patch."))
		return
	end

	local filepath = `patches/{dirName}.patch`
	local index = 2
	while fs.exists(filepath) do
		filepath = `patches/{dirName}_{index}.patch`
		index += 1
	end

	fs.writeStringToFile(filepath, diff)
	print()
	print(richterm.green(`Wrote patch to {filepath}!`))
	print(richterm.dim("Run `lute patch apply` to verify it's applies cleanly."))
end

do
	local alias = args:get("alias") :: string

	local subcommand = args:get("subcommand")
	if subcommand == "help" then
		return args:help()
	elseif subcommand == "apply" then
		return applyPatches()
	end

	local wally = toml.deserialize(fs.readFileToString("wally.toml")) :: Wally
	local dependencies = wally.dependencies
	local specifier = dependencies[alias] or error(`Unknown package aliased "{alias}"`)

	local scope, name, version = string.match(specifier, "([%w%-]+)/([%w%-]+)@(%d+%.%d+%.%d+)")
	local dirName = `{scope}_{name}@{version}`
	local dirPath = formatPackageDir(dirName)

	if not fs.exists(packagesDir) then
		error("Packages aren't installed! Run `lute install` prior to patching")
	end

	if subcommand == "init" then
		initializePatch(alias, dirPath)
	elseif subcommand == "deinit" then
		deinitializePatch(dirPath)
	elseif subcommand == "generate" then
		generatePatch(dirName, dirPath)
	elseif subcommand == "regenerate" then
		initializePatch(alias, dirPath)
		generatePatch(dirName, dirPath)
	else
		error(`Unknown subcommand "{subcommand}"`)
	end
end
