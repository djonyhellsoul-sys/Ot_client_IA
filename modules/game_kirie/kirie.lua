local clientSocket = nil
local kirieWindow = nil
local kirieButton = nil -- Botão na barra superior do jogo

local iaActive = false

function init()
  -- 1. Cria a interface visual
  kirieWindow = g_ui.displayUI('kirie.otui')
  kirieWindow:hide()

  -- 2. Cria um botão de atalho na barra superior do OTClient para abrir/fechar o painel
  kirieButton = modules.client_topmenu.addLeftGameButton('kirieButton', 'Kirie IA', '/images/topbuttons/minimap', toggle)

  -- 3. Configura as ações dos botões do painel
  kirieWindow:getChildById('buttonStartPause').onClick = onClickStartPause
  kirieWindow:getChildById('buttonSaveClose').onClick = onClickSaveClose
  kirieWindow:getChildById('buttonToggleWindow').onClick = toggle

  -- 4. Inicializa a conexão de rede com o Python
  clientSocket = g_network.createSocket()
  clientSocket.onConnect = function() 
    print("[Kirie Client] Vinculo de rede estabelecido!")
    g_game.talk("Oi Djony")
  end
  clientSocket.onRecv = onIncomingPythonCommand
  clientSocket:connect("127.0.0.1", 9000)

  -- Gatilhos de chat e mensagens
  connect(g_game, { onTextMessage = onMessageReceived })
end

function terminate()
  disconnect(g_game, { onTextMessage = onMessageReceived })
  
  if clientSocket then
    clientSocket:disconnect()
  end
  
  if kirieWindow then
    kirieWindow:destroy()
  end
  
  if kirieButton then
    kirieButton:destroy()
  end
end

function toggle()
  if kirieWindow:isVisible() then
    kirieWindow:hide()
  else
    kirieWindow:show()
    kirieWindow:raise()
    kirieWindow:focus()
  end
end

-- Função do botão Iniciar / Pausar
function onClickStartPause()
  local btn = kirieWindow:getChildById('buttonStartPause')
  if not iaActive then
    iaActive = true
    btn:setText("Pausar IA")
    sendActionToPython("SYSTEM:START")
    g_game.talk("[Kirie] Módulo Cognitivo Ativado.")
  else
    iaActive = false
    btn:setText("Iniciar IA")
    sendActionToPython("SYSTEM:PAUSE")
    g_game.talk("[Kirie] Módulo Cognitivo Pausado.")
  end
end

-- Função do botão Salvar e Fechar
function onClickSaveClose()
  g_game.talk("[Kirie] Salvando dados e encerrando...")
  sendActionToPython("SYSTEM:SAVE_CLOSE")
  
  -- Fecha o painel visual
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
  if not iaActive then return end -- Se estiver pausado, não envia dados de sensores/chat para o Python
  
  local channel = "local"
  if mode == MessageModes.DamageDealt or mode == MessageModes.DamageReceived then
    channel = "damage"
  elseif mode == MessageModes.NpcFrom or mode == MessageModes.NpcTo then
    channel = "npc"
  end
  
  sendActionToPython(channel .. "|Player|" .. text)
end

function onIncomingPythonCommand(socket, data)
  -- Mantém a sua lógica original de receber ordens (WALK, TALK, etc.)
end
