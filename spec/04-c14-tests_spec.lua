local dir = require("pl.dir")
local utils = require("pl.utils")
local path = require("pl.path")

local expadom = require "expadom"

describe("canonicalization test", function()

	local options_ns = "http://www.w3.org/2010/xml-c14n2"

	local files = dir.getfiles("./spec/03-test-files/c14n/", "out_*.xml")
	table.sort(files)

	local function canonicalize(inputXml, options)
		return table.concat(inputXml:writeCanonical(options))
	end

	local function readXml(filename)
		return assert(expadom.parseDocument(assert(utils.readfile(filename))))
	end

	-- Note that options file parsing is only designed to handle the options that are present in the official C14
	-- test cases (https://www.w3.org/TR/xml-c14n2-testcases/files/).  In particular, only one of each QNameAware
	-- element types is read from the options file.

	local function readOptions(filename)
		local xml = readXml(filename)

		local function getElement(name)
			return xml:getElementsByTagNameNS(options_ns, name)[1]
		end

		local function getElementText(name)
			local element = getElement(name)
			if element and element.childNodes[1] then
				return element.childNodes[1].nodeValue
			end
		end

		local function getQNameAwareElement(name)
			local element = getElement(name)
			if element then
				return { element:getAttribute("NS"), element:getAttribute("Name") }
			end
		end

		local function getQNameAware()
			return {
				element = getQNameAwareElement("Element"),
				xpathElement = getQNameAwareElement("XPathElement"),
				qualifiedAttr = getQNameAwareElement("QualifiedAttr"),
			}
		end

		return {
			ignore_comments =  getElementText("IgnoreComments") == "true",
			prefix_rewrite = getElementText("PrefixRewrite"),
			trim_text_nodes = getElementText("TrimTextNodes") == "true",
			qname_aware = getQNameAware(),
		}
	end

	for _, outputFile in ipairs(files) do
		local inputFile = outputFile:gsub("out_(.+)_.+%.xml", "%1.xml")
		local optionsFile = outputFile:gsub("out_.+_(.+)%.xml", "%1.xml")

		-- inC14N5.xml contains external entity references that LuaExpat does parse
		if path.basename(inputFile) ~= "inC14N5.xml" then
			it("#" .. path.splitext(path.basename(inputFile)) .. " with options #" .. path.splitext(path.basename(optionsFile)), function()
				local inputXml = readXml(inputFile)
				local options = readOptions(optionsFile)
				local outputString = assert(utils.readfile(outputFile))

				assert.same(outputString, canonicalize(inputXml, options))
			end)
		end
	end
end)
