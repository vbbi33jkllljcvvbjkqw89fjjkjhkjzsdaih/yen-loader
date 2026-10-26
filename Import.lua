--/ File access for Yen. Dev: files from the executor workspace (YenLocalRoot). Bundle: modules and assets embedded in the script
--/ Libraries are public: Farcal from its own repo, Obsidian from the pinned upstream commit

local FarcalUrl = "https://raw.githubusercontent.com/vbbi33jkllljcvvbjkqw89fjjkjhkjzsdaih/farcal-ui/main/"
local ObsidianUrl = "https://raw.githubusercontent.com/deividcomsono/Obsidian/bdaa9b8f555ed5ff1c4d87bb2d7339babe874e6f/"

local Import = {
	LocalRoot = getgenv().YenLocalRoot,
	Edition = getgenv().YenEdition or "Free",
	Modules = nil,
	Binaries = nil,
	Sources = {},
	Chunks = {},
	Errors = {},
	LastLine = nil,
	LastCount = 0,
}

--/ Nothing in Yen writes to the console. Problems go here and are shown in the UI

--/ The same problem repeating (a loop that fails every tick) is kept as one line with a count
function Import.Report(Context, Message)
	local Errors = Import.Errors
	local Line = string.format("[%s] %s", tostring(Context), tostring(Message))

	if Import.LastLine == Line and #Errors > 0 then
		Import.LastCount += 1
		Errors[#Errors] = Line .. " (x" .. Import.LastCount .. ")"

		return
	end

	Import.LastLine = Line
	Import.LastCount = 1

	if #Errors >= 100 then
		table.remove(Errors, 1)
	end

	table.insert(Errors, Line)
end

--/ The first lines of the stack are kept with the message so a failure can be found from the Diagnostics box
local function Trace(Err)
	return tostring(Err) .. " | " .. string.gsub(string.sub(debug.traceback("", 2), 2, 300), "\n+", " > ")
end

function Import.Safe(Context, Callback)
	return function(...)
		local Ok, Err = xpcall(Callback, Trace, ...)

		if not Ok then
			Import.Report(Context, Err)
		end
	end
end

--/ Notices use the Farcal look once the key module has registered Present, the plain Roblox toast is only a last resort
function Import.Notify(Text, Title)
	if Import.Present then
		local Ok = pcall(Import.Present, Title or "Yen", Text)

		if Ok then
			return
		end
	end

	pcall(function()
		game:GetService("StarterGui"):SetCore("SendNotification", { Title = Title or "Yen", Text = Text, Duration = 6 })
	end)
end

local function Attempt(Callback)
	local Last

	for Try = 1, 2 do
		local Ok, Result = pcall(Callback)

		if Ok and type(Result) == "string" and Result ~= "" then
			return Result
		end

		Last = Result
		task.wait(0.4 * Try)
	end

	error("[Yen] download failed: " .. tostring(Last), 0)
end

local function Compile(Source, Name)
	local Chunk, Err = loadstring(Source, "=" .. Name)

	if not Chunk then
		error("[Yen] " .. Name .. ": " .. tostring(Err), 0)
	end

	return Chunk
end

function Import.Remote(Url)
	local Source = Import.Sources[Url]

	if not Source then
		Source = Attempt(function()
			return game:HttpGet(Url)
		end)

		Import.Sources[Url] = Source
	end

	return Source
end

function Import.Binary(Path)
	if Import.Binaries and Import.Binaries[Path] then
		return Import.Binaries[Path]
	end

	return Attempt(function()
		return readfile(Import.LocalRoot .. "src/" .. Path)
	end)
end

--/ Compiles once per path, then every call runs a fresh copy of the module
function Import.Load(Path, ...)
	if Import.Modules and Import.Modules[Path] then
		return Import.Modules[Path](Import, ...)
	end

	local Chunk = Import.Chunks[Path]

	if not Chunk then
		Chunk = Compile(Attempt(function()
			return readfile(Import.LocalRoot .. "src/" .. Path)
		end), Path)

		Import.Chunks[Path] = Chunk
	end

	return Chunk(Import, ...)
end

--/ Downloads a binary once into the workspace, re-downloads if the header does not match
function Import.Asset(Path, Target, Magic)
	local Cached = isfile(Target) and readfile(Target) or ""

	if string.sub(Cached, 1, #Magic) ~= Magic then
		writefile(Target, Import.Binary(Path))
	end

	if string.sub(readfile(Target), 1, #Magic) ~= Magic then
		error("[Yen] " .. Path .. " is not a valid file", 0)
	end

	return getcustomasset(Target)
end

local function LibrarySource(Path, Url)
	if Import.LocalRoot and isfile(Import.LocalRoot .. "libs/" .. Path) then
		return readfile(Import.LocalRoot .. "libs/" .. Path)
	end

	return Import.Remote(Url)
end

function Import.Farcal()
	local Chunk = Import.Chunks["Farcal"]

	if not Chunk then
		Chunk = Compile(LibrarySource("Farcal.lua", FarcalUrl .. "Farcal.lua"), "Farcal.lua")
		Import.Chunks["Farcal"] = Chunk
	end

	return Chunk({
		Report = Import.Report,
		Directory = "YenHub/Farcal",
		Fetch = function(Path)
			return LibrarySource(Path, FarcalUrl .. Path)
		end,
	})
end

--/ Obsidian runs in its own environment so its warnings and deferred errors never reach the console
local function ObsidianEnvironment()
	local Raw = task

	local function Guard(Callback)
		if type(Callback) ~= "function" then
			return Callback
		end

		return Import.Safe("Obsidian", Callback)
	end

	return setmetatable({
		task = setmetatable({
			delay = function(Time, Callback, ...) return Raw.delay(Time, Guard(Callback), ...) end,
			spawn = function(Callback, ...) return Raw.spawn(Guard(Callback), ...) end,
			defer = function(Callback, ...) return Raw.defer(Guard(Callback), ...) end,
		}, { __index = Raw }),
		warn = function(Message)
			Import.Report("Obsidian", Message)
		end,
	}, { __index = getgenv() })
end

local function LoadObsidian(Key, Path)
	local Chunk = Import.Chunks[Key]

	if not Chunk then
		Chunk = Compile(LibrarySource("Obsidian/" .. Path, ObsidianUrl .. Path), Key)
		Import.Chunks[Key] = Chunk
	end

	pcall(setfenv, Chunk, ObsidianEnvironment())

	return Chunk()
end

function Import.Obsidian()
	return LoadObsidian("ObsidianLibrary", "Library.lua")
end

function Import.ObsidianSaves()
	return LoadObsidian("ObsidianSaves", "addons/SaveManager.lua")
end

--/ Downloads the library files in the background so switching interface later does not wait on the network
function Import.Prefetch()
	if Import.LocalRoot then
		return
	end

	for _, Url in { FarcalUrl .. "Farcal.lua", ObsidianUrl .. "Library.lua", ObsidianUrl .. "addons/SaveManager.lua" } do
		pcall(Import.Remote, Url)
	end
end

pcall(function()
	for _, Folder in { "YenHub", "YenHub/Assets" } do
		if not isfolder(Folder) then
			makefolder(Folder)
		end
	end
end)

return Import
