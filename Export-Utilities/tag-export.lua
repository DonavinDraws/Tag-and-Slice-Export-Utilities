function init(plugin)

    if plugin.preferences.tagsize == nil then
        plugin.preferences.tagsize = "%100"
      end
    if plugin.preferences.tagprefix == nil then
        plugin.preferences.tagprefix = ""
      end

    plugin:newCommand{
        id="ExportTags",
        title="Export Tags",
        group="file_export_1",
        onclick=function()
            local scales = {"%25", "%50"}
            for i = 1,10,1 
            do
                table.insert(scales, "%" .. tostring(i*100)) 
            end

            local mouse = {position = Point(0, 0), leftClick = false}

            local focusedWidget = nil

            local customWidgets = {}

            local selectedTags = {}

            spr = app.activeSprite

            for i = 1, #spr.tags do
                local customButton = {
                    bounds = Rectangle(5+math.fmod(i-1,4)*80, -15+math.ceil(i/4)*20, 80, 20),
                    state = {
                        normal = {part = "button_normal", color = "button_normal_text"},
                        hot = {part = "button_hot", color = "button_hot_text"},
                        selected = {part = "button_selected", color = "button_selected_text"},
                        focused = {part = "button_focused", color = "button_normal_text"}
                    },
                    selected = false,
                    tag = spr.tags[i],
                }
                table.insert(customWidgets, customButton)
            end

            local dlg = Dialog{
                title = "Export Tags...",
                hexpand=false,
                vexpand=false}
            dlg:file{ id="prefix", 
                label="Sprite Prefix", 
                title="Choose Directory", 
                open=false, 
                save=true, 
                filename=plugin.preferences.tagprefix, 
                filetypes = {"png", "jpeg", "jpg", "ase", "aseprite"},
                entry = true, 
                focus = false}

            dlg:combobox{ id="scale",
                label="Resize %",
                option=plugin.preferences.tagsize,
                options=scales}

            dlg:label{ id="label",
                label="Choose Tags:"}
                
            dlg:button{ id="selectAll", text="Select All",
            onclick = function()
                selectedTags = {}
                for _, widget in ipairs(customWidgets) do
                    widget.selected = true
                    table.insert(selectedTags, widget.tag)
                end
                dlg:repaint()
                end}
                
            dlg:button{ id="deselectAll", text="Deselect All",
                onclick = function()
                    for _, widget in ipairs(customWidgets) do
                        widget.selected = false
                    end
                    selectedTags = {}
                    dlg:repaint()
                    end}

            dlg:canvas{
                id = "canvas",
                width = 10+math.min(4,#spr.tags)*80,
                height = 10+math.ceil(#spr.tags/4)*20,
                hexpand = false,
                vexpand = false,
                onpaint = function(ev)
                    local ctx = ev.context
            
                    -- Draw each custom widget
                    for _, widget in ipairs(customWidgets) do
                        local state = widget.state.normal
            
                        if widget == focusedWidget then
                            state = widget.state.focused
                        end     
            
                        local isMouseOver = widget.bounds:contains(mouse.position)
            
                        if isMouseOver then
                            state = widget.state.hot or state
                        end

                        if widget.selected then
                            state = widget.state.selected
                        end
            
                        ctx:drawThemeRect(state.part, widget.bounds)
            
                        local center = Point(widget.bounds.x + widget.bounds.width / 2,
                                                widget.bounds.y + widget.bounds.height / 2)
            
                        local size = ctx:measureText(widget.tag.name)
        
                        ctx.color = app.theme.color[state.color]
                        ctx:fillText(widget.tag.name, center.x - size.width / 2,
                                        center.y - size.height / 2)
                    end
                end,
                onmousemove = function(ev)
                    -- Update the mouse position
                    mouse.position = Point(ev.x, ev.y)
            
                    dlg:repaint()
                end,
                onmousedown = function(ev)
                    -- Update information about left mouse button being pressed
                    mouse.leftClick = ev.button == MouseButton.LEFT
            
                    dlg:repaint()
                end,
                onmouseup = function(ev)
                    -- When releasing left mouse button over a widget, call `onclick` method
                    if mouse.leftClick then
                        for _, widget in ipairs(customWidgets) do
                            local isMouseOver = widget.bounds:contains(mouse.position)
                            if isMouseOver then
                                widget.selected = not widget.selected
                                local inSet = false
                                for i = 1, #selectedTags do
                                    if  widget.tag == selectedTags[i] then
                                        inSet = true
                                        if not widget.selected then table.remove(selectedTags, i) end
                                        break
                                    end
                                end
                                if widget.selected and not inSet then
                                    table.insert(selectedTags, widget.tag)
                                end
                                -- Last clicked widget has focus on it
                                focusedWidget = widget
                            end
                        end
                    end
            
                    -- Update information about left mouse button being released
                    mouse.leftClick = false
            
                    dlg:repaint()
                end
            }

            dlg:button{ id="export", text="Export" }
            dlg:button{ id="cancel", text="Cancel" }
            dlg:show()

            local data = dlg.data
            
            if data.export then
                spr = app.activeSprite
                rescale = tonumber(string.match(data.scale, "%d+"))/100
                pre = data.prefix
                plugin.preferences.tagsize = data.scale
                plugin.preferences.tagprefix = data.prefix

                for i, tag in ipairs(selectedTags) do
                    local tagname = tag.name
                    local fcount = tag.frames
                    local newfile = Image(spr.width*fcount, spr.height)
                    
                    for j = 0, fcount do
                        local p = Point(spr.width*j, 0);
                        newfile:drawSprite(spr, tag.fromFrame.frameNumber + j ,  p  )
                        end

                    if newfile:isEmpty() == false then
                        newfile:resize(newfile.width*rescale, newfile.height*rescale)
                        newfile:saveAs(app.fs.filePathAndTitle(pre) .. tagname .."_strip" .. fcount .. "." .. app.fs.fileExtension(pre))
                    end
                end       
            end
        end
    }
end  