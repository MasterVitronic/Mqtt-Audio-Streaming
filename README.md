# Mqtt Audio Streaming

Audio streaming server and player via MQTT protocol.

> This project is inspired in [multi-speakers-audio-streaming](https://github.com/leotok/multi-speakers-audio-streaming)

_Author:_ _[Díaz Devera Víctor Diex Gamar (Máster Vitronic)](https://www.linkedin.com/in/Master-Vitronic)_

[![Lua logo](./doc/powered-by-lua.gif)](http://www.lua.org/)

## Dependencies

* [luasocket](http://luaforge.net/projects/luasocket/)
* [lua-mqtt](https://github.com/tacigar/lua-mqtt.git) 
* [lua-subprocess](https://github.com/tdtrask/lua-subprocess)

## Installation

Clone this repository.

```
git clone https://gitlab.com/vitronic/Mqtt-Audio-Streaming.git
```

## Usage

Edit the broker variable to use your preferred MQTT server.

To run the streaming server run the following in the terminal.

```
cd Mqtt-Audio-Streaming/
lua streaming.lua
```

In a separate terminal or on another machine, run the following.

```
cd Mqtt-Audio-Streaming/
lua player.lua
```

This is basically a wrapper that does the same thing that.

```
mosquitto_sub -h ispcore.com.ve  -t song/stream | aplay -t raw
```

To add more songs to the playlist you must convert them to a suitable format.

```
sox input.ogg -t u8 -c 1 -b 8 -r 8k output.u8
```

Then edit `audio_list.lua` and add your new songs to the table


## Contributing
Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.


## License
[MIT](https://choosealicense.com/licenses/mit/)