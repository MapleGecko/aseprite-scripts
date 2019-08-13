-- util functions

function tableFind(t,el)
	for index, value in pairs(t) do
		if value == el then
			return index
		end
	end
	return nil
end

-- file management functions

function file_exists(file)
  local f = io.open(file, "rb")
  if f then f:close() end
  return f ~= nil
end

function getScriptPath()
	local info = debug.getinfo(1,'S');
	local path = info.source:sub(2):match("(.*[/\\])")
	return path
end
-------------------------------

function addTagToList(tagname)
	if invalidTag(tagname) then
		if invalidTag(tagname) == 1 then
			app.alert{title="Error", text="The tag you entered is empty. Please enter a valid name."}
		elseif invalidTag(tagname) == 2 then
			app.alert{title="Error", text="The tag you entered already exists. Please enter a valid name."}
		end
	else
		table.insert(tags,tagname)
		adddlg:close()
		dlg:close()
		if dlg.data.composite_mode then
			generateMainDialog(tostring(dlg.data.fframe), tostring(dlg.data.lframe), dlg.data.composite_tag)
		else 
			generateMainDialog(tostring(dlg.data.fframe), tostring(dlg.data.lframe), "")
		end
	end
end

function deleteTagFromList(tagname)
	table.remove(tags, tableFind(tags, tagname))
	deldlg:close()
	dlg:close()
	if dlg.data.composite_mode then
		generateMainDialog(tostring(dlg.data.fframe), tostring(dlg.data.lframe), dlg.data.composite_tag)
	else 
		generateMainDialog(tostring(dlg.data.fframe), tostring(dlg.data.lframe), "")
	end
end

function saveConfig()
	local file, err = io.open(getScriptPath() .. "quicktag.conf", "w")
	--Mode
	file:write("compositemode=" .. tostring(compositemode) .. "\n")
	--Tags
	file:write("tags={")
	for key, tag in pairs(tags) do
		file:write("\"" .. tag .. "\",")
	end
	file:write("}")
	
	file:close()
end
	

function invalidTag(tagname)
	if tagname == "" then
		return 1
	elseif tableFind(tags, tagname) then
		return 2
	else
		return false
	end
end

-- DIALOG GENERATORS -----------------------------------------------------------

function generateAddDialog()
	adddlg = Dialog("New tag")
	
	adddlg:entry{ id="adddlg_text", focus=true }
	
	adddlg:button{ id="adddlg_confirm", text="Confirm", focus=true, 
		onclick=function()
			addTagToList(adddlg.data.adddlg_text)			
		end
		}
	adddlg:button{ id="adddlg_cancel", text="Cancel", 
		onclick=function()
			adddlg:close()
		end
		}
	adddlg:show()
	return adddlg
end

function generateDelDialog()
	deldlg = Dialog("Delete tag")
	local i, length = 0, #tags
	for key, tag in pairs(tags) do
		if (i%2==0 and length<12) or (i%3==0 and length>=12 and length<24) or (i%4==0 and length>=24) then
			deldlg:newrow()
		end

		deldlg:button{ 	id="tagname_button_" .. tostring(i), text=tag, focus=false,
						onclick =function()
							deleteTagFromList(tag)
						end
						}
		i=i+1
	end
	deldlg:show()
	return deldlg
end

function generateMainDialog(firstframe, lastframe, cur_composite_tag)
	dlg = Dialog("Quick Tag")
	local tag_color = Color{ r=0, g=0, b=0 }

	dlg:number{ id="fframe", label="Range : ", text=firstframe}

	dlg:number{ id="lframe", text=lastframe}	
	
	dlg:check{ id="composite_mode", text="Composite mode", selected=compositemode, 
			onclick=function() 
				dlg:close()
				compositemode=not compositemode
				dlg=generateMainDialog(tostring(dlg.data.fframe), tostring(dlg.data.lframe), "")
			end
			}
			
	-- Composite mode
	if compositemode then
		dlg:separator{}
		dlg:label{ id="composite_tag", label="Tag : ", text=cur_composite_tag}
		dlg:button{id="apply_composite_tag", text="Apply", onclick=tagButtonPressed(cur_composite_tag, tag_color)}
		dlg:button{	id="clear_composite_tag", text="Clear", 
					onclick=function()
						dlg:close()
						dlg=generateMainDialog(tostring(dlg.data.fframe), tostring(dlg.data.lframe), "")
					end
					}
	end
	-- Composite mode end
	
	dlg:separator{}
	
	if next(tags) == nil then
		dlg:label{ id="empty_taglist", text="There is no tag yet !"}
	else
		local i, length = 0, #tags
		for key, tag in pairs(tags) do
			if (i%2==0 and length<12) or (i%3==0 and length>=12 and length<24) or (i%4==0 and length>=24) then
				dlg:newrow()
			end
			
			dlg:button{ id="tagname_button_" .. tostring(i), text=tag, 
						onclick=function()
							if compositemode then
								dlg:close()
								dlg=generateMainDialog(tostring(dlg.data.fframe), tostring(dlg.data.lframe), cur_composite_tag .. (cur_composite_tag=="" and "" or "_") .. tag)
							else
								tagButtonPressed(tag, tag_color)()
							end
						end}
			i=i+1
		end
	end
	
	dlg:separator{}
	-- dlg:color{ id="selected_color", color=tag_color}
	dlg:button{ id="add_tag", text="New tag", 
				onclick=function() 
					generateAddDialog()
				end
				}
	dlg:button{ id="del_tag", text="Delete", 
				onclick=function() 
					generateDelDialog()
				end
				}
	dlg:button{ id="cancel", text="Cancel", focus=true}
	dlg:show()
	

	return dlg
end

--------------------------------------------------------------------------------

function createTag(spr, firstframe, lastframe, tagname)
	local tag = spr:newTag(firstframe, lastframe)
	-- tag.color = Color{ r=255, g=255, b=255, a=255 }
	tag.name = tagname
	
	return tag
end

function tagButtonPressed(tagname, tagcolor)
	return function()
		global_tagname = tagname
		global_tagcolor = tagcolor
		tag_pressed = true
		dlg:close()
		end
end

-- Script begins

			
local spr = app.activeSprite			
local cel = app.activeCel
local frm = app.activeFrame
local rng = app.range

local firstframe
local lastframe

if rng.isEmpty then
	firstframe = frm.frameNumber
	lastframe = frm.frameNumber
else
	firstframe = rng.frames[1].frameNumber
	lastframe = rng.frames[#rng.frames].frameNumber
end


--Loading config from the config file
compositemode=false
tags = {}
if file_exists(getScriptPath() .. "quicktag.conf") then
	loadfile(getScriptPath() .. "quicktag.conf")()
end
-----------------------------------

global_tagname = "Tag"
global_tagcolor = Color{ r=0, g=0, b=0 }
tag_pressed = false


generateMainDialog(tostring(firstframe), tostring(lastframe), "")

local data = dlg.data
if tag_pressed then

	app.transaction(
		function()
			local tag = createTag(spr, data.fframe, data.lframe, global_tagname)
		end
	)
	
	
end

saveConfig()