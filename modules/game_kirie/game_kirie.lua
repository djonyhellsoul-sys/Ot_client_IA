kirieWindow = nil
kirieButton = nil
iaActive = false
kirieActionTimer = nil

function init()
  kirieWindow = g_ui.displayUI('/modules/game_kirie/game_kirie.otui')
  if kirieWindow then
    kirieWindow:hide()
    kirieWindow:getChildById('buttonStartPause').onClick = onClickStartPause
    kirieWindow:getChildById('buttonSaveClose').onClick = onClickSaveClose
    kirieWindow:getChildById('buttonToggleWindow').onClick = toggle
  end

  kirieButton = modules.client_topmenu.addLeftGameButton('kirieButton', 'Kirie IA', '/game_kirie/kirie_icon', toggle)
  if kirieButton then kirieButton:hide() end

  connect(g_game, { onGameStart = onOnline, onGameEnd = onOffline, onTextMessage = onMessageReceived })
  
  if g_game.isOnline() then onOnline() end

  -- Ativa o loop do motor a cada 100ms
  kirieActionTimer = cycleEvent(checkKirieActions, 100)
end

function terminate()
  disconnect(g_game, { onGameStart = onOnline, onGameEnd = onOffline, onTextMessage = onMessageReceived })
  if kirieActionTimer then removeEvent(kirieActionTimer) end
  if kirieWindow then kirieWindow:destroy() end
  if kirieButton then kirieButton:destroy() end
end

function onOnline()
  if kirieButton then kirieButton:show() end
  if kirieWindow then kirieWindow:show() kirieWindow:raise() end
end

function onOffline()
  if kirieWindow then kirieWindow:hide() end
  if kirieButton then kirieButton:hide() end
  iaActive = false
end

function toggle()
  if not g_game.isOnline() or not kirieWindow then return end
  if kirieWindow:isVisible() then kirieWindow:hide() else kirieWindow:show() end
end

function onClickStartPause()
  local btn = kirieWindow:getChildById('buttonStartPause')
  if not iaActive then
    iaActive = true
    btn:setText("Pausar IA")
    sendActionToPython("SYSTEM-START")
  else
    iaActive = false
    btn:setText("Iniciar IA")
    sendActionToPython("SYSTEM-PAUSE")
  end
end

function onClickSaveClose()
  sendActionToPython("SYSTEM-SAVE_CLOSE")
  kirieWindow:hide()
  iaActive = false
  kirieWindow:getChildById('buttonStartPause'):setText("Iniciar IA")
end

function sendActionToPython(action)
  -- Envia comandos de botões direto no arquivo de comandos rápidos
  g_resources.writeFile("/modules/game_kirie/kirie_command.txt", action)
end

function checkKirieActions()
  if not g_game.isOnline() then return end

  -- 1. ATUALIZA SENSORES REAIS EM ARQUIVO DE PONTE COMPARTILHADA
  local localPlayer = g_game.getLocalPlayer()
  if localPlayer then
    local pos = localPlayer:getPosition()
    local hp = localPlayer:getHealth()
    local mp = localPlayer:getMana()
    local cap = localPlayer:getFreeCapacity()
    
    if pos then
      -- Cospe tudo em uma única string na linha (X|Y|Z|HP|MP|CAP)
    local sensorData = pos.x .. "|" .. pos.y .. "|" .. pos.z .. "|" .. hp .. "|" .. mp .. "|" .. cap
    g_resources.writeFile("/modules/game_kirie/kirie_bridge.txt", sensorData)

    end
  end

  if not iaActive then return end

  -- 2. LEITURA DE MOVIMENTOS DA IA (kirie_actions.txt)
  local filename = "/modules/game_kirie/kirie_actions.txt"
  if g_resources.fileExists(filename) then
    local content = g_resources.readFileContents(filename)
    if content and #content > 0 then
      g_resources.writeFile(filename, "") -- Limpa buffer na hora
      
      local parts = content:split("|")
      if #parts >= 2 then
        local actionType = parts[1]
        local payload = parts[2]
        
        if actionType == "WALK" then
          g_game.walk(tonumber(payload))
        elseif actionType == "TALK" then
          g_game.talk(payload)
        end
      end
    end
  end
end

function onMessageReceived(mode, text)
  if not iaActive then return end
  if mode == MessageModes.Talk or mode == MessageModes.Whisper then
    sendActionToPython("CHAT-local-Player-" .. text)
  end
end
