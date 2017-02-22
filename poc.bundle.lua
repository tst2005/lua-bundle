
local deps = {error=error, type=type, pcall=pcall, _G=_G, table={concat=table.concat}, require=require, setmetatable=setmetatable}
local G = deps
local M
do
	local DEBUG = G.print or function() end

	local INT = {} -- internal modules
	local FAL = {} -- fallback modules (use parent module if available)
---------------------------------------------------------------------

	INT["foo"] = [[
local foo = require"foo.init"
local socket = require "socket"
local lpeg = require "lpeg"
print("LPEG VERS", lpeg.version())
return foo
]]
	INT["foo.init"] = [[return {_NAME="foo v1.0.0"}]]
	INT["mod1"] = [[return {_NAME="mod1"}]]
	INT["mod2"] = [[return {_NAME="mod2"}]]

	FAL["lpeg"] = [[return {_NAME="lpeg fallback", version=function() return "fake lpeg"end,}]]

	--INT.lpeg = FAL.lpeg

---------------------------------------------------------------------
	local vpreload = {}
	local vloaded = {}
	local vsearchers = {} -- internal ; with    parent lookup
	local esearchers = {} -- exposed  ; without parent lookup

	local load = G.require "mini.load"

	local function lowlevel_require(name, searchers)
		local type = G.type
		if vloaded[name] then
			DEBUG("vrequire("..name..") => already loaded in vloaded")
			return vloaded[name]
		end
		DEBUG("vrequire("..name..") => loading...")

		local msg = {}
		local loader, param
		for _, searcher in ipairs(searchers) do
			loader, param = searcher(name)
			if G.type(loader) == "function" then break end
			if G.type(loader) == "string" then
				-- `loader` is actually an error message
				msg[#msg + 1] = loader
			end
			loader = nil
		end
		if loader == nil then
			G.error("module '" .. name .. "' not found: "..G.table.concat(msg), 2)
		end
		local res = loader(name, param)
		if res ~= nil then
			module = res
		elseif not vloaded[name] then
			module = true
		else
			module = vloaded[name]
		end

		vloaded[name] = module
		return module
	end

	local function vrequire(name)
		return lowlevel_require(name, vsearchers)
	end

	local function erequire(name) -- a vrequire without parent lookup
		return lowlevel_require(name, esearchers)
	end

	local function lowlevel_search_sources(modname, sources)
		local src = sources[modname]
		if not src then
			return "source not found"
		end
		local priv = G.setmetatable({}, {__index=_G})
		priv._G = priv
		priv.require = vrequire
		local pub = G.setmetatable({}, {__index=priv})

		local f = load(src, src, "t", pub)
		if not f then
			return "fail to load from source"
			--G.error("got error: fail to load from source", 2)
		end
		return f
	end

	local function search_internal(modname)			DEBUG("# search_sources(internal)", modname)
		return lowlevel_search_sources(modname, INT)
	end
	local function search_fallback(modname)			DEBUG("# search_sources(fallback)", modname)
		return lowlevel_search_sources(modname, FAL)
	end

	local function search_preload(modname)			DEBUG("# search_preload", modname)
		return vpreload[modname]
	end
	local function search_parent(modname)			DEBUG("# search_parent", modname)
		local ok,r = G.pcall(G.require, modname)
		DEBUG("parent require return:", ok, modname)
		if not ok then return nil end
		return function() return r end
	end

	vsearchers[#vsearchers+1] = search_preload
	vsearchers[#vsearchers+1] = search_internal
	vsearchers[#vsearchers+1] = search_parent
	-- usual searcher lua+luac
	vsearchers[#vsearchers+1] = search_fallback

	esearchers[#esearchers+1] = search_preload
	esearchers[#esearchers+1] = search_internal
	--esearchers[#esearchers+1] = search_parent
	esearchers[#esearchers+1] = search_fallback

-- [3] preload the main module

	package.preload["foo"] = erequire

-- [4] all other shortcutable modules

	package.preload["foo.init"] = erequire
	package.preload["foo.other"] = erequire

	M={loaded=vloaded, preload=vpreload}
end

return M

-- code source brute
-- code source minifier
-- bytecode
-- loaded function (quand on créé une fonction qui renvoie le module deja loadé)
-- le module loadé.
