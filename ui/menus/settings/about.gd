extends RefCounted

var group: SettingsUIGroup

func load() -> SettingsUIGroup:
    group = Settings.create("Settings_About")
    
    group.label("Gindustry by awa")

    return group
