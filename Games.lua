--/ Supported games. Match by PlaceId or GameId (universe), Script is loaded after the key is accepted
--/ Features lists the files in src/Features that everyone gets

return {
	{
		Name = "Slayers 2 (Ouwland)",
		--/ Every world of the game: Slayers 2, Testing, Minigames, Storage, Ouwland Test Place, Ouwland. GameIds already cover them all
		PlaceIds = { 16205713724, 17047024836, 75556147183481, 109676363279588, 130395143593224, 136406881576517 },
		GameIds = { 5595353122 },
		Script = "Hub.lua",
		--/ Farms paused after two bans on 2026-10-26: FarmSettings, Autofarm, LevelFarm, BanditFarm, BossFarm, Loot. Add them back here to ship them
		Features = { "Esp" },
		--/ premium:start
		--/ Premium lists files in src/Features/Premium. They only exist in the premium file, the lines between premium:start and premium:end are cut from the free file by tools\Bundle.ps1
		Premium = {},
		--/ premium:end
	},
	{
		Name = "Baseplate (test)",
		PlaceIds = { 123974602339071 },
		GameIds = {},
		Script = "Hub.lua",
		--/ Every feature, so the tab layout can be checked here. The farms find no enemies on a baseplate and stay idle
		Features = { "FarmSettings", "Autofarm", "LevelFarm", "BanditFarm", "BossFarm", "Esp", "Loot", "Example" },
		--/ premium:start
		Premium = { "Premium/PremiumExample" },
		--/ premium:end
	},
}