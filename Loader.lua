--/ Main entry. Checks the game, asks for a key and the terms, then loads the script for that game

local Import = ...

--/ Run straight from a loadstring: no Import was passed, so fetch it. Dev uses the workspace copy, everyone else the public yen-loader repo
if not Import then
	local LoaderUrl = "https://raw.githubusercontent.com/vbbi33jkllljcvvbjkqw89fjjkjhkjzsdaih/yen-loader/main/Import.lua"
	local Root = getgenv().YenLocalRoot

	local Ok, Result = pcall(function()
		local Source = Root and readfile(Root .. "src/Import.lua") or game:HttpGet(LoaderUrl)

		return loadstring(Source, "=Import.lua")()
	end)

	if not Ok or type(Result) ~= "table" then
		pcall(function()
			game:GetService("StarterGui"):SetCore("SendNotification", { Title = "Yen", Text = "Could not load Yen. Check your connection and try again.", Duration = 6 })
		end)

		return
	end

	Import = Result
end

local KeyOk, KeySystem = pcall(Import.Load, "KeySystem.lua")

if KeyOk and type(KeySystem) == "table" then
	KeySystem.Register()
else
	Import.Report("Loader", KeySystem)
end

if getgenv().YenLoading then
	return
end

getgenv().YenLoading = true

local function Find(Games)
	for _, Entry in Games do
		if table.find(Entry.PlaceIds or {}, game.PlaceId) or table.find(Entry.GameIds or {}, game.GameId) then
			return Entry
		end
	end
end

local function Main()
	local Entry = Find(Import.Load("Games.lua"))
	local KeyConfig = Import.Load("KeyConfig.lua")

	if not Entry then
		--/ Players with a live key are hopping servers, they are not told about every lobby
		if Import.Edition == "Premium" or KeySystem.Active(KeyConfig) then
			return
		end

		return KeySystem.Notice({
			Title = "Game not supported",
			Description = "This game is not on our supported list yet. Check back after a future update.",
		})
	end

	local Terms = Import.Load("Terms.lua")
	local Token = {}

	getgenv().YenWatch = Token

	local Start

	--/ When the key runs out the script is unloaded and the key is asked for again
	local function Watch(ExpiresAt)
		task.delay(math.max(ExpiresAt - os.time(), 0), Import.Safe("Relock", function()
			if getgenv().YenWatch ~= Token then
				return
			end

			if getgenv().YenHub then
				pcall(getgenv().YenHub.Unload)
			end

			KeySystem.Forget()

			getgenv().YenKeyExpires = nil
			getgenv().YenLoading = true

			local Ok, Err = pcall(Start, true, "Key expired")

			getgenv().YenLoading = false

			if not Ok then
				Import.Report("Relock", Err)
			end
		end))
	end

	Start = function(Fresh, Status)
		local Unlocked, ExpiresAt = true, nil

		if Import.Edition ~= "Premium" or KeyConfig.KeyForPremium then
			Unlocked, ExpiresAt = KeySystem.Run(KeyConfig, { Fresh = Fresh, Status = Status })
		end

		if not Unlocked then
			return
		end

		if not KeySystem.Terms(Terms) then
			return KeySystem.Notice({
				Title = "Terms of Service",
				Description = "You need to accept the Terms of Service to use Yen.",
			})
		end

		getgenv().YenGame = Entry
		getgenv().YenKeyExpires = ExpiresAt

		Import.Load(Entry.Script)

		if ExpiresAt then
			Watch(ExpiresAt)
		end
	end

	Start(false)
end

local Ok, Err = pcall(Main)

getgenv().YenLoading = false

if not Ok then
	Import.Report("Loader", Err)
	Import.Notify("Yen could not load. Check your connection and try again.")
end
