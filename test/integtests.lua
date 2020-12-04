function getScriptPath() return io.popen("cd"):read('*l') end
getInfoParam = function(prm) 
	if prm == "VERSION" then 
		return "8.7" 
	else 
		error('Not applied for param: '..prm)
	end 
end

local function myget_parent_dir(str)
   local fpat = "\\"
   local last_end = #str-1
   local s, e, cap = str:find(fpat, last_end)
   while last_end >= 1 do
      if e ~= nil then
         return str:sub(1, e - 1)
      end
      last_end = last_end-1
      s, e, cap = str:find(fpat, last_end)
   end
   return nil
end

local script_path = getScriptPath()
local base_path = myget_parent_dir(script_path)
local socketcore_path = base_path.."\\clibs64\\53_MD\\"
local libs_path = base_path.."\\libs\\"
local testlibs_path = script_path.."\\libs\\"

package.path = package.path .. ";"..base_path.."\\?.lua;"..base_path.."\\?.luac;"..".\\?.lua;"..".\\?.luac;"..libs_path.."?.lua;"..testlibs_path.."?.lua"
package.cpath = package.cpath..";"..socketcore_path..'?.dll;' ..'.'..socketcore_path..'?.dll;'..testlibs_path.."?.lua"
-------------------------

local lu = require('luaunit')

-----------------------------------------
		   --	RECEIVERAPI  --
-----------------------------------------
local lreceiver = require('receiverapi')
local socket = require ('socket')

TestReceiverApi = {}
		function TestReceiverApi:setUp()
			self.dr = lreceiver:create('127.0.0.1', 9091)
			self.r = lreceiver:create('127.0.0.1', 9090)
			self:runServer()
		end
		
		function TestReceiverApi:tearDown()
			self:closeServer()
		end
		
		---------------------------------
		
		function TestReceiverApi:runServer()
			os.execute('start pythonw '..base_path..'\\DataReceiver.py')
			self.runned = true
		end
		
		function TestReceiverApi:closeServer()
			if self.runned then
				os.execute('taskkill /IM pythonw.exe /F >nul')
			end
			self.runned = false
		end
		
		---------------------------------
		
		function TestReceiverApi:test_connect2DS_False()
			local res = self.dr:connect()
			lu.assertFalse(res)
			lu.assertFalse(self.dr.is_connected)
		end
		
		function TestReceiverApi:test_connect2RS_True()
			local res = self.r:connect()
			lu.assertTrue(res)
			lu.assertTrue(self.r.is_connected)
		end
		
		function TestReceiverApi:test_disconnect2DS_False()
			local res = self.dr:disconnect()
			lu.assertFalse(res)
			lu.assertFalse(self.dr.is_connected)
		end
				
		function TestReceiverApi:test_disconnect2RS_True()
			local cres = self.r:connect()
			lu.assertTrue(self.r.is_connected)
			lu.assertTrue(cres)
			
			local res = self.r:disconnect()
			lu.assertFalse(self.r.is_connected)
			lu.assertTrue(res)
		end
		
		function TestReceiverApi:test_disconnect2RSShooted_True()
			local cres = self.r:connect()
			lu.assertTrue(self.r.is_connected)
			lu.assertTrue(cres)
			
			self:closeServer()
			
			local res = self.r:disconnect()
			lu.assertFalse(self.r.is_connected)
			lu.assertTrue(res)
		end
		
		---------------------------------
		
		function TestReceiverApi:test_sendMsg2RS_ReturnTrue()
			local cres = self.r:connect()
			
			local sres = self.r:sendStr("asdasd")
			
			lu.assertTrue(self.r.is_connected)
			lu.assertTrue(cres)
			lu.assertTrue(sres)
		end
		
		function TestReceiverApi:test_sendMsg2DS_ReturnNil()
			local cres = self.dr:connect()
			
			local sres = self.dr:sendStr("asdasd")
			
			lu.assertFalse(self.dr.is_connected)
			lu.assertFalse(cres)
			lu.assertNil(sres)
		end
		
		function TestReceiverApi:test_sendMsg2RSShooted_ReturnFalse()
			local cres = self.r:connect()
			lu.assertTrue(self.r.is_connected)
			lu.assertTrue(cres)
			
			self:closeServer()
			local sres = self.r:sendStr("asdasd")
			
			lu.assertFalse(sres)
			lu.assertFalse(self.r.is_connected)
		end

local runner = lu.LuaUnit.new()
--runner:setOutputType("junit", "unit_test_results")
runner:runSuite()



