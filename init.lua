 -- Make animations faster (0.2 is the default value), set it to 0 to disable
hs.window.animationDuration = 0.1

-- These are the ratio of my left window and right window sizes. I don't want half/half
-- layout, I prefer Emacs and Terminal to be smaller than Browser/Dash
local leftRatio = 0.55556
local rightRatio = 0.44443

function left(screen)
  -- This is the left layout, it is bigger than the right layout in size. Used for
  -- browser and documentations and books.
  return hs.geometry({
      x = screen.x,
      y = screen.y,
      w = screen.w * leftRatio,
      h = screen.h
  })
end

function middle(screen)
  -- This is a main big window with 100px empty spaces at the endges. Mainly used for
  -- the main browser.
  return hs.geometry({
      x = screen.x + 100,
      y = screen.y,
      w = screen.w - 200,
      h = screen.h
  })
end

function right(screen)
  -- This is the right layout, which is smaller than the left layout size. Used for
  -- Emacs and terminal
  return hs.geometry({
      x = screen.x + screen.w * leftRatio,
      y = screen.y,
      w = screen.w * rightRatio,
      h = screen.h
  })
end

function center(screen)
  -- move the current window to the center of the screen
  local window = hs.window.focusedWindow():frame()
  return hs.geometry({
      x = screen.x + (screen.w - window.w) / 2,
      y = screen.y + (screen.h - window.h) / 2,
      w = window.w,
      h = window.h
  })
end

function hipsterCenter(screen)
  -- move the focused window to the top 25% of screen height and horizontal center
  local window = hs.window.focusedWindow():frame()
  return hs.geometry({
      x = screen.x + (screen.w - window.w) / 2,
      y = screen.y + (screen.h - window.h) / 4,
      w = window.w,
      h = window.h
  })
end

function finder(screen)
  local window = hs.window.focusedWindow():frame()
  return hs.geometry({
      x = window.x,
      y = window.y,
      w = 600,
      h = 640
  })
end

function setCurrent(fn, windowFrame)
  -- Set the size of the currently focused window according to `fn`
  -- `fn`: (right/middle/center/left etc)
  local window = hs.window.focusedWindow()

  windowFrame = windowFrame or window:screen():frame()
  window:setFrame(fn(windowFrame))
end

function itunes()
  -- Set the size of itunes MiniPlayer
  local screen = hs.screen.primaryScreen():frame()
  local size = hs.geometry({
      x = screen.x + 35,
      y = screen.y + 35,
      w = 400,
      h = screen.h - 60
  })

  hs.application.find("itunes"):findWindow("miniplayer"):setFrame(size)
end

function focus(appName)
  -- Focus the app in `appName`
  local app = hs.application.find(appName)

  if app then
    app:mainWindow():focus()
  end
end

function focusChrome()
  local focusedWindow = hs.window.focusedWindow()
  local chrome = hs.application.find("Google")
  local windows = chrome and chrome:allWindows()
  local activeWindows = {}

  for _, window in pairs(windows) do
    if window and window:title() ~= "" then
      table.insert(activeWindows, window)
    end
  end

  if #activeWindows > 1 and activeWindows[1] == focusedWindow then
    activeWindows[2]:focus()
  else
    activeWindows[1]:focus()
  end
end

function sendToScreen(screenNum, fn)
  local screen = hs.screen.allScreens()[screenNum]:frame()

  hs.window.focusedWindow():setFrame(fn(screen))
end

function sendToMainScreen()
  sendToScreen(1, center)
end

function sendToTv()
  sendToScreen(2, center)
end

-- I swaped capslock and control keys then used Seil and Karabinder to bind the capslock
-- (which is in the position of the control key) as a hyper key
local hyper = { "cmd", "alt", "ctrl", "shift" }

-- Window Hints
hs.hints.hintChars = { "J", "K", "L", ";", "A", "S", "D", "F", "H", "G" }
hs.hotkey.bind(hyper, "H", hs.hints.windowHints)

-- Size binding
hs.hotkey.bind(hyper, "A", function() setCurrent(left) end)
hs.hotkey.bind(hyper, "S", function() setCurrent(middle) end)
hs.hotkey.bind(hyper, "D", function() setCurrent(right) end)
hs.hotkey.bind(hyper, "C", function() setCurrent(center) end)
hs.hotkey.bind(hyper, "V", function() setCurrent(hipsterCenter) end)
hs.hotkey.bind(hyper, "F", function() setCurrent(finder) end)

hs.hotkey.bind(hyper, "T", itunes)
hs.hotkey.bind(hyper, "1", sendToMainScreen)
hs.hotkey.bind(hyper, "2", sendToTv)

-- Focus binding
hs.hotkey.bind(hyper, "J", focusChrome)
hs.hotkey.bind(hyper, "K", function() focus("Emacs") end)
hs.hotkey.bind(hyper, "L", function() focus("Terminal") end)
hs.hotkey.bind(hyper, "U", function() focus("Dash") end)

-- Automaticy apply size and position for these apps
local filter = hs.window.filter

filter.new("Emacs"):subscribe(
  hs.window.filter.windowCreated,
  function(window, name, event)
    local screen = window:screen():frame()

    window:setFrame(right(screen))
end)

filter.new("Terminal"):subscribe(
  hs.window.filter.windowCreated,
  function(window, name, event)
    local screen = window:screen():frame()

    if window:title() == "λ" then
      window:setFrame(right(screen))
    end
end)
