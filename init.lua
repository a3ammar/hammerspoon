-- General Hammerspoon configurations
hs.window.animationDuration = 0.1
hs.application.enableSpotlightForNameSearches(true)
hs.hints.hintChars = { "J", "K", "L", ";", "A", "S", "D", "F", "H", "G" }


-- Window size and position history
local windowHistory = {}

function windowHistory:save()
  local window = hs.window.focusedWindow()

  if not self[window:id()] then
    self[window:id()] = {}
  end

  table.insert(self[window:id()], window:frame())
end

function windowHistory:restore()
  local window = hs.window.focusedWindow()

  if not self[window:id()] then
    return
  end

  if #self[window:id()] > 0 then
    window:setFrame(table.remove(self[window:id()]))
  end
end

-- Remove window history of no longer existing windows
function windowHistory:clean()
  for id in pairs(self) do
    if type(id) == "number" and hs.window.get(id) == nil then
      self[id] = nil
    end
  end
end

-- Clean the window history every 5 minutes to avoid memory leaks
hs.timer.doEvery(hs.timer.minutes(5), function() windowHistory:clean() end)


-- setFocusedWindow set the current window frame according to the return value of
-- `layoutfn`, which should be a function that takes three arguments:
--   `screen`: The screen's frame
--   `window`: The current window's frame
--   `isExternal`: Whether it's not on the built in display or not
function setFocusedWindow(layoutfn)
  -- Return a function so we could use it easily with `bind()`
  return function()
    local window = hs.window.focusedWindow()
    local screen = window:screen()
    local isExternal = false

    if screen:name() == "Thunderbolt Display" then
      isExternal = true
    end

    windowHistory:save()
    window:setFrame(hs.geometry(layoutfn(screen:frame(), window:frame(), isExternal)))
  end
end


-- Focus an application, toggling between its windows
function focus(appName)
  -- Return a function so we could use it easily with `bind()`
  return function()
    local app = hs.application.get(appName)
    if app then
      if not app:isFrontmost() then
        app:mainWindow():focus()
      else
        -- Filter windows without title (workaround a Chrome issue)
        local windows = hs.fnutils.filter(app:allWindows(), function(w) return w:title() ~= "" end)
        if #windows > 1 and app:mainWindow() == windows[1] then
          windows[2]:focus()
        else
          windows[1]:focus()
        end
      end
    end
  end
end


-- Bind a key to the hyper key
function bind(key, fn)
  hs.hotkey.bind({"ctrl", "alt", "cmd", "shift"}, key, fn)
end



-- Hammersppon hints
bind("h", hs.hints.windowHints)


-- Focus specific applications
bind("j", focus("Google Chrome"))
bind("k", focus("Emacs"))
bind("l", focus("Terminal"))
bind("u", focus("Dash"))


-- Focus a bindable application
local bindableFocus = nil
-- Set the application to focus
bind("8", function() bindableFocus = hs.window.focusedWindow() end)
-- Focus the application
bind("i", function()
  if bindableFocus then
    bindableFocus:focus()
  end
end)


-- Start screensave
hs.hotkey.bind({}, "f20", hs.caffeinate.startScreensaver)


-- Sending windows to different monitors
bind("1", function() hs.window:focusedWindow():centerOnScreen(hs.screen.allScreens()[1], true) end)
bind("2", function() hs.window:focusedWindow():centerOnScreen(hs.screen.allScreens()[2], true) end)

-- Laptop layout ratios
local rightRatio = 0.4443
local leftRatio  = 0.5556

-- Restore layout history
bind("z", function() windowHistory:restore() end)

-- Left window
bind("a", setFocusedWindow(function(screen, window, isExternal)
  if isExternal then
    return {
      x = screen.x + 20,
      y = screen.y + 20,
      w = 1100,
      h = screen.h - 40,
    }
  else
    return {
      x = screen.x,
      y = screen.y,
      w = screen.w * leftRatio,
      h = screen.h,
    }
  end
end))

-- Middle window
bind("s", setFocusedWindow(function(screen, window, isExternal)
  if isExternal then
    return {
      x = screen.x + 20,
      y = screen.y + 20,
      w = screen.w - 40,
      h = screen.h - 40,
    }
  else
    return {
      x = screen.x + 20,
      y = screen.y,
      w = screen.w - 40,
      h = screen.h,
    }
  end
end))

-- Right window
bind("d", setFocusedWindow(function(screen, window, isExternal)
  if isExternal then
    return {
      x = screen.x + screen.w - 1420,
      y = screen.y + 20,
      w = 1400,
      h = screen.h - 40,
    }
  else
    return {
      x = screen.x + screen.w * leftRatio,
      y = screen.y,
      w = screen.w * rightRatio,
      h = screen.h,
    }
  end
end))

-- Center window
bind("c", setFocusedWindow(function(screen, window)
  return {
    x = screen.x + (screen.w - window.w) / 2,
    y = screen.y + (screen.h - window.h) / 2,
    w = window.w,
    h = window.h,
  }
end))

-- Upper center window
bind("v", setFocusedWindow(function(screen, window)
  return {
    x = screen.x + (screen.w - window.w) / 2,
    y = screen.y + 40,
    w = window.w,
    h = window.h,
  }
end))

-- Finder sized window
bind("f", setFocusedWindow(function(screen, window)
  return {
    x = window.x,
    y = window.y,
    h = 640,
    w = 600,
  }
end))

-- Right middle window, suitable for DevTools
bind("r", setFocusedWindow(function(screen)
  return {
    x = screen.x + screen.w - 1320,
    y = screen.y + 120,
    w = 1200,
    h = screen.h - 240,
  }
end))

-- Tall window
bind("w", setFocusedWindow(function(screen, window)
  return {
    x = window.x,
    y = screen.y + 20,
    w = window.w,
    h = screen.h - 40,
  }
end))


-- Application specific configuration
-- A helper function that converts an event to key code: { modifiers.., characters... }
function toKey(event)
  local key = {}
  for modifier, _ in pairs(event:getFlags()) do
    table.insert(key, modifier)
  end

  table.insert(key, hs.keycodes.map[event:getKeyCode()])
  return key
end

-- Swap meta and alt keys in Terminal.app
local swapMeta = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(event)
  -- Ignore those keys when swaping the meta
  local ignoredKeys = hs.fnutils.map({
      { "cmd", "tab" },
      { "cmd", "space" },
      { "alt", "space" },
      { "cmd", "q" },
      { "cmd", "c" },
      { "cmd", "alt", "c" },
      { "cmd", "shift", "c" },
      { "cmd", "," },
      { "cmd", "shift", "4" },
      { "cmd", "shift", "3" },
      { "cmd", "ctrl", "\\" },
    }, table.concat)
  local modifiers = event:getFlags()

  -- Ignore hyper key presses
  if modifiers.cmd and modifiers.alt and modifiers.ctrl and modifiers.shift then
    return false, {}
  end

  -- Ignore keys that are in ignoredKeys
  if hs.fnutils.contains(ignoredKeys, table.concat(toKey(event))) then
    return false, {}
  end

  if modifiers.alt then
    return true, { event:setFlags({ cmd = true, alt = nil }) }
  end

  if modifiers.cmd then
    return true, { event:setFlags({ cmd = nil, alt = true }) }
  end
end)

-- Attach the eventtap to the Terminal app only when it's focused
hs.window.filter.new("Terminal")
  :subscribe(hs.window.filter.windowFocused, function() swapMeta:start() end)
  :subscribe(hs.window.filter.windowUnfocused, function() swapMeta:stop() end)
