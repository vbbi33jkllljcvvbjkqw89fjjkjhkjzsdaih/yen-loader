--/ Supported games. Match by PlaceId or GameId (universe), Script is loaded after the key is accepted
--/ Features lists the files in src/Features that everyone gets

return {
	{
		Name = "Slayers 2 (Ouwland)",
		--/ Every world of the game: Slayers 2, Testing, Minigames, Storage, Ouwland Test Place, Ouwland. GameIds already cover them all
		PlaceIds = { 16205713724, 17047024836, 75556147183481, 109676363279588, 130395143593224, 136406881576517 },
		GameIds = { 5595353122 },
		Script = "Hub.lua",
		--/ Farms re-enabled by the owner on 2026-10-26, knowing the ban risk. FarmSettings must come first so the shared settings exist
		Features = { "FarmSettings", "Autofarm", "LevelFarm", "BanditFarm", "BossFarm", "Esp", "Loot" },
		--/ premium:start
		--/ Premium lists files in src/Features/Premium. They only exist in the premium file, the lines between premium:start and premium:end are cut from the free file by tools\Bundle.ps1
		Premium = {},
		--/ premium:end
	},
	{
		--/ Framework test place only: key, terms and the hub shell. No game features, those belong to their own game by game id
		Name = "Baseplate (test)",
		PlaceIds = { 123974602339071 },
		GameIds = {},
		Script = "Hub.lua",
		Features = {},
		--/ premium:start
		Premium = {},
		--/ premium:end
	},
}