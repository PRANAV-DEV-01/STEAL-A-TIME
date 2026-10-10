local GameConfig = {
	GameName = "STEAL A TIME",
	HubName = "TIME SANCTUARY",
	FolderName = "TimeSanctuary",
	WorldFolderName = "TimeSanctuary_World",
	RemotesFolderName = "Remotes",

	BaseWalkSpeed = 16,
	MaxWalkSpeed = 24,
	MaxServerSpeedClamp = 25,
	JumpPower = 50,

	RespawnProtectionDuration = 30,
	ComebackBonus = 15,
	ComebackWindow = 300,

	SaveDebounce = 30,
	SaveMaxRetries = 5,
	SaveBackoffBase = 1,

	BroadcastThrottle = 0.5,
	DecayTick = 0.25,
	MaxActiveTime = 600,
	MinActiveTime = 0,

	MaxStealSessionPerHour = 600,
	HardStealCapPerHour = 900,
	MaxComboMultiplier = 2.5,

	LogPrefix = "[TimeSanctuary]",
}

return GameConfig