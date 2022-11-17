local log = require "log"
local capabilities = require "st.capabilities"

----- added by Hugh -----------------
local socket = require("socket")
local tcp = assert(socket.tcp())
local displayID = 0x00
------------- comaand list with expected return byte number ---
local powerOn = {string.char(0xAA,0x11,displayID,0x01,0x01,0x13)}
local powerOff = {string.char(0xAA,0x11,displayID,0x01,0x00,0x12)}
local inputHDMI1 = {string.char(0xAA,0x14, displayID, 0x01,0x21,0x36)}
local inputMagicINFO = {string.char(0xAA,0x14, displayID, 0x01,0x60,0x75)}
local ssDeviceStatus ={string.char(0xAA,0x00, displayID,0x00,0x00)}

------------------------------------------------------------------------------


local command_handlers = {}

-- callback to handle an `on` capability command
function command_handlers.switch_on(driver, device, command)
  log.debug(string.format("[%s] calling set_power(on)", device.device_network_id))

  local success = sendCommandToDisplay("powerOn",device.device_network_id);
  if success then
    device:emit_event(capabilities.switch.switch.on())
    return success
  end
end

-- callback to handle an `off` capability command
function command_handlers.switch_off(driver, device, command)
  log.debug(string.format("[%s] calling set_power(off)", device.device_network_id))

  local success = sendCommandToDisplay("powerOff",device.device_network_id);
if success then
  device:emit_event(capabilities.switch.switch.off())
  return success
end
end

function sendCommandToDisplay(command,host)
  tcp:settimeout(0.5)
  tcp:connect(host, 1515);
 
  tcp:send(command[1]);
  --- check the response based on the expected number of bytes to come back --
  local received, err, partial = tcp:receive(8);

      if not err then
          if received ~= nil then

      ---------  Check the Ack or Nack Status of the response ac should be 0x41 ---------- 
                  if string.sub(received,5,5) ~= string.char(0x41) then
                  --print("DIsplay returned a Nack!!");
                  --print(hexencode(recieved));
                  log.debug(string.format("[%s] Returned a Nack!", host))
          else 
              --print(hexencode(string.sub(received,5,5)))
              log.debug(string.format("[%s] Returned good", host))
          end
      end
      elseif err == "closed" then
      tcp:close();
      log.debug(string.format("[%s] Bad Response Closed socket!!", host))
  end
end

local function hexencode(str)
  --return (str:gsub(".", function(char) return string.format("%2x", 
  return (str:gsub(".", function(char) return string.format("%02x", 
  char:byte()) end))
end

return command_handlers
