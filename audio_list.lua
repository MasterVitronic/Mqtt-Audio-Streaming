--sox 08.ogg -t u8 -c 1 -b 8 -r 8k 08.u8
--sox gun.wav -t wav -c 1 -b 8 -r 8k gun1.wav
--@see https://docs.yate.ro/wiki/ConvertingAudio
local songs = {
	{
		name = "Bensound sunny",
		desc = "Gentle acoustic royalty free music featuring guitar, marimba...",
		path = "songs/bensound-sunny_8k.u8"
	},
	{
		name = "Bensound allthat", 
		desc = "Chill-Hop royalty free music track featuring jazz samples, a hip ...",
		path = "songs/bensound-allthat_8k.u8"
	}
}

return songs