-----------------------------
-- Global Socket Variables --
-----------------------------
socket = require("socket")
tcpsock = assert(socket.tcp())

-- Connect Function
function connect(cip, cport)
	print("Connecting... \nIP: " .. cip .. "\nPort: " .. cport) 
	assert(tcpsock:connect(cip, cport))
	print("Connection established!\n");
end

-- Receive Response Function
function recvResponse()
	local data, stat, part = tcpsock:receive()
	print("Receving...")
	print(data)
end

-- Send Command Function
function sendCommand(ccmd)
	tcpsock:send(ccmd)
	recvResponse()
end

-- Close Connection Function
function close()
	assert(tcpsock:close())
end
