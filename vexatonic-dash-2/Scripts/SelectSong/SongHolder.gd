extends TextureRect
class_name SongHolder

@onready var artistName: Label = $ArtistName
@onready var songName: Label = $SongName
@onready var levelNumber: Label = $LevelNumber

func set_song_metadata(metadata: LevelMetaData):
	artistName.text = metadata.artist
	songName.text = metadata.name
	var diff = Setting.selected_difficulty
	levelNumber.text = str(metadata.difficulty[diff]) if metadata.difficulty.size() > diff else "-"
