extends RefCounted

var group: Settings.SettingsUIGroup

func load() -> Settings.SettingsUIGroup:
    group = Settings.create("Settings_About")
    
    group.label("Gindustry by awa")

    return group
