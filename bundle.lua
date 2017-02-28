
local class = require "mini.class"

--local bundle = class("bundle", nil, nil)
local bundle = require"mini.microclass"()

-- mode = "raw2"|"lua"|"raw"
-- open = io.open
-- output = io.stdout|<fd>
-- import_as = "module"|"file"|"textcode"|"bytecode"

function bundle:init(config)
	config = config or {}
	self._open = config.open or require"io".open
	self._output = config.output or require"io".stdout
	self._deleted = {} -- mark
	self._config = {}

	self._imports = {}
	--self._import_as = config.import_as or nil -- "module"
	self._default = {
		fallback=false,
	}
	--self._default.as = config.as or "module"

	--self._config.mode = "raw2"
	local mt = assert(getmetatable(self))
	mt.__add = function(self, ...) return self:add(...) end
	mt.__sub = function(self, ...) return self:del(...) end
	mt.__tostring = function(self) return self:__tostring() end
	--mt.__gc = function() print("instance destroyed") end
	return self
end

function bundle:def(t_def)
	for k,v in pairs(t_def) do
		self._default[k]=v
	end
	assert(self._default.as)
	return self
end

function bundle:fallback()
	self:def {fallback=true}
	assert(self._default.fallback==true)
	return self
end

function bundle:internal()
	self:def {fallback=false}
	assert(self._default.fallback==false)
	return self
end

function bundle:add(entry)
	if type(entry)=="string" then
		if (entry=="fallback" or entry=="internal") and self[entry] then
			self[entry](self)
		end
		return self	
	end
	local e = {}
	local def = self._default
	for k,v in pairs(def) do
		e[k]=v
	end
	for k,v in pairs(entry) do
		if v~=nil then
			e[k]=v
		end
	end
	assert(e.as)
	--entry.as = entry.as or self._import_as or error("self._import_as not defined ?!")
	table.insert(self._imports, e)
	return self
end

function bundle:del(entry)
	local deleted = self._deleted
	local import = self._imports
	for i,e in ipairs(import) do
		if ( entry.name and entry.file and entry.name == v.name and entry.file == e.file )
		or ( entry.name and entry.name == e.name )
		or ( entry.file and entry.file == e.file ) then
			import[i]=deleted
		end
	end
	return self
end

function bundle:readfiles()
	local import = self._imports
	for i,entry in ipairs(import) do
		if entry ~= self._deleted and not entry.content then
			--print("reading "..(entry.file or "unknown"), entry.file)
			local fd, err = self._open(entry.file, "r")
			if not fd then
				error(err, 2)
			end
			entry.content = fd:read("*a")
			fd:close()
		end
	end
	return self
end

local function packed(entry)
	local r = {}
	table.insert(r, "-- file: "..entry.name.." "..(entry.fallback and "[fallback]" or "[internal]"))
	table.insert(r, entry.content)
	table.insert(r, "-- end of file")
	return table.concat(r, "\n").."\n"
end

function bundle:_finish(out)
	local import = self._imports
	local r = {}
	for i,entry in ipairs(import) do
		if entry ~= self._deleted then
			if entry.as == "textcode" then
				out:write(entry.content)
			elseif entry.as == "module" then
				out:write(packed(entry))
			else
				error("NYI", 2)
			end
		end
	end
	return self
end

function bundle:finish()
	self:_finish(self._output)
	return self
end

function bundle:__tostring()
	local fakefd = {}
	local buf = {}
	function fakefd:write(data)
		table.insert(buf, data)
	end
	self:_finish(fakefd)
	return table.concat(buf, "")
end

--[[
aio.au
aio.code
aio.codehead
aio.config
aio.core
--aio.finish
aio.gi
aio.ichechini
aio.icheck
aio.in
aio.ini
aio.inpreload
aio.lua
aio.luacode
aio.luamod
aio.mod
aio.mode
aio.modlua
aio.modraw
aio.modraw2
aio.mods
aio._NAME
aio.packmod
aio.rawmod
aio.require
aio.rock
aio.rock.au
aio.rock.file
aio.rock.mod
aio.shcode
aio.shebang
aio.sheebang
aio.shellcode
aio.use
aio.vfile
]]--

return bundle
