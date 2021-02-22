#!/usr/bin/env lua

--[[
 @filename  streaming.lua
 @version   1.0
 @autor     Máster Vitronic <mastervitronic@gmail.com>
 @date      22-02-2021 05:17:21 -04
 @licence   MIT licence

 @inspired  https://github.com/leotok/multi-speakers-audio-streaming
 @see	    https://nodemcu.readthedocs.io/en/release/modules/pcm/
 @require   http://luaforge.net/projects/luasocket/
 @require   https://github.com/flukso/lua-mosquitto

===============================================================================

Copyright (C) 2021 Díaz Devera Víctor Diex Gamar (Máster Vitronic)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

===============================================================================

To run the server
 $ lua streaming.lua

To play the audio on the client
 $ paho_c_sub -h ispcore.com.ve -t song/stream | aplay -t raw
or
 $ mosquitto_sub -h ispcore.com.ve -t song/stream | aplay -t raw
or
 $ mosquitto_sub -h ispcore.com.ve  -t song/stream | ffplay -f u8 -ar 8k -ac 1 -
or
 $ lua player.lua
]]--

--@see http://luaforge.net/projects/luasocket/
local socket	= require('socket')
---@see https://github.com/flukso/lua-mosquitto
local mqtt	= require('mosquitto') 
--the list of audio files
local songs	= dofile('audio_list.lua')

--local broker 	= 'broker.hivemq.com'
local broker 	= 'ispcore.com.ve'
local topic  	= 'song'
local port  	= 1883
local keepalive = 60
local QoS	= 2
local chunk_size= 256
local quit 	= false
client		= mqtt.new( 'MQTTAudioStream2' , true)

client.ON_MESSAGE = function ( mid, topicName, payload )
	if ( topicName == ('%s/cmd'):format(topic)  ) then
		if ( payload == '/quit' ) then
			io.write("Bye \n")
			quit = true
		end
	end
	collectgarbage("collect")
end

client.ON_CONNECT = function ()
	io.write("connected\n")
	client:subscribe(('%s/cmd'):format(topic), QoS)
end

client.ON_DISCONNECT = function ()
	if quit then return end
	local ok, errno, errmsg
	repeat
		ok, errno, errmsg = client:reconnect()
		if (not ok) then
			io.write('ERROR ',errno, errmsg, "\n")
		else
			io.write("REconnecting ..\n")
		end
	until(ok == true)
end

client:connect(broker,port,keepalive)

function stream()
	while true do --infinite loop
		if quit then break end
		for index,value in pairs(songs) do -- loop for songs
			local file = io.open(value.path, "rb")
			local msg = ('{name:"%s",desc:"%s"}'):format(
				value.name,value.desc
			)
			io.write(msg .. "\n")
			client:publish(('%s/info'):format(topic),msg)
			while true do -- loop for read bytes
				local bytes = file:read(chunk_size)
				if not bytes or quit then
					break
				end
				client:publish(
					('%s/stream'):format(topic),
					bytes
				)
				socket.sleep(0.03)
				collectgarbage("collect")
			end
			if quit then break end
		end
	end
end

client:loop_start()
stream()
client:disconnect()
client:destroy()
