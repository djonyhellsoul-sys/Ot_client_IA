local clientSocket = nil
local kirieWindow = nil
local kirieButton = nil
local iaActive = false

function init()
  -- CORREÇÃO AQUI: Mudado de 'kirie.otui' para 'game_kirie.otui'
  kirieWindow = g_ui.displayUI('game_kirie.otui')
  if kirieWindow then
    kirieWindow:show()
    kirieWindow:raise()
    kirieWindow:focus()
    
    kirieWindow:getChildById('buttonStartPause').onClick = onClickStartPause
    kirieWindow:getChildById('buttonSaveClose').onClick = onClickSaveClose
    kirieWindow:getChildById('buttonToggleWindow').onClick = toggle
  else
    print("[Kirie Erro] Nao foi possivel carregar o arquivo game_kirie.otui")
  end

  clientSocket = g_network.createSocket()
  clientSocket.onConnect = function() 
    print("[Kirie Client] Vinculo de rede estabelecido!")
    g_game.talk("Oi Djony")
  end
  clientSocket.onRecv = onIncomingPythonCommand
  clientSocket:connect("127.0.0.1", 9000)

  connect(g_game, { onTextMessage = onMessageReceived })
end
function terminate()
  disconnect(g_game, { onTextMessage = onMessageReceived })
  if clientSocket then clientSocket:disconnect() end
  if kirieWindow then kirieWindow:destroy() end
end

function toggle()
  if kirieWindow:isVisible() then kirieWindow:hide() else kirieWindow:show() kirieWindow:raise() end
end

function onClickStartPause()
  local btn = kirieWindow:getChildById('buttonStartPause')
  if not iaActive then
    iaActive = true
    btn:setText("Pausar IA")
    sendActionToPython("SYSTEM:START")
    g_game.talk("[Kirie] Modulo Cognitivo Ativado.")
  else
    iaActive = false
    btn:setText("Iniciar IA")
    sendActionToPython("SYSTEM:PAUSE")
    g_game.talk("[Kirie] Modulo Cognitivo Pausado.")
  end
end

function onClickSaveClose()
  g_game.talk("[Kirie] Salvando dados e encerrando...")
  sendActionToPython("SYSTEM:SAVE_CLOSE")
  kirieWindow:hide()
  iaActive = false
  kirieWindow:getChildById('buttonStartPause'):setText("Iniciar IA")
end

function sendActionToPython(action)
  if clientSocket and clientSocket:isConnected() then
    clientSocket:send(action .. "\n")
  end
end

function onMessageReceived(mode, text)
  if not iaActive then return end
  local channel = "local"
  if mode == MessageModes.DamageDealt or mode == MessageModes.DamageReceived then channel = "damage" end
  sendActionToPython(channel .. "|Player|" .. text)
end

function onIncomingPythonCommand(socket, data)
  if data then
    local separator = data:find(":")
    if separator then
      local command = data:sub(1, separator - 1)
      local value = data:sub(separator + 1):gsub("\n", ""):gsub("\r", "")
      if command == "WALK" then
        if value == "North" then g_game.walk(Directions.North)
        elseif value == "South" then g_game.walk(Directions.South)
        elseif value == "East" then g_game.walk(Directions.East)
        elseif value == "West" then g_game.walk(Directions.West)
        end
      end
    end
  end
end
