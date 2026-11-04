local clientSocket = nil
local kirieWindow = nil
local kirieButton = nil
local iaActive = false

function init()
  -- 1. Carrega o arquivo visual .otui
kirieWindow = g_ui.displayUI('/modules/game_kirie/game_kirie.otui')


  if kirieWindow then
    kirieWindow:hide() -- Mantém oculto até o login estar totalmente estabilizado
    
    kirieWindow:getChildById('buttonStartPause').onClick = onClickStartPause
    kirieWindow:getChildById('buttonSaveClose').onClick = onClickSaveClose
    kirieWindow:getChildById('buttonToggleWindow').onClick = toggle
  else
    print("[Kirie Erro] Nao foi possivel carregar o arquivo game_kirie.otui")
  end

  -- 2. Cria o botão de atalho na barra superior do OTClient (TopMenu)
  -- Nota: Usamos o ícone padrão do minimapa como teste visual para o botão da Kirie
kirieButton = modules.client_topmenu.addLeftGameButton('kirieButton', 'Kirie IA', '/modules/game_kirie/game_kirie', toggle)

  -- 3. Conecta ao Python na porta 9000
  clientSocket = g_network.createSocket()
  clientSocket.onConnect = function() 
    print("[Kirie Client] Vinculo de rede estabelecido!")
    g_game.talk("Oi Djony")
  end
  clientSocket.onRecv = onIncomingPythonCommand
  clientSocket:connect("127.0.0.1", 9000)

  -- Gatilho para abrir a janela automaticamente assim que o personagem entrar no mundo de fato
  connect(g_game, { onGameStart = onOnline, onTextMessage = onMessageReceived })
  
  -- Se você já estiver logado ao recarregar o módulo, força a exibição
  if g_game.isOnline() then
    onOnline()
  end
end

function terminate()
  disconnect(g_game, { onGameStart = onOnline, onTextMessage = onMessageReceived })
  if clientSocket then clientSocket:disconnect() end
  if kirieWindow then kirieWindow:destroy() end
  if kirieButton then kirieButton:destroy() end
end

function onOnline()
  if kirieWindow then
    kirieWindow:show()
    kirieWindow:raise()
    kirieWindow:focus()
  end
end

function toggle()
  if not kirieWindow then return end
  if kirieWindow:isVisible() then 
    kirieWindow:hide() 
  else 
    kirieWindow:show() 
    kirieWindow:raise() 
    kirieWindow:focus()
  end
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
  if not data then return end
  
  -- Itera sobre linhas caso múltiplos comandos cheguem juntos
  for line in data:gmatch("[^\r\n]+") do
    local separator = line:find(":")
    if separator then
      local command = line:sub(1, separator - 1)
      local value = line:sub(separator + 1)
      
      if command == "WALK" then
        if value == "North" then g_game.walk(Directions.North)
        elseif value == "South" then g_game.walk(Directions.South)
        elseif value == "East" then g_game.walk(Directions.East)
        elseif value == "West" then g_game.walk(Directions.West)
        end
      elseif command == "TALK" then
        g_game.talk(value)
      end
    end
  end
end
