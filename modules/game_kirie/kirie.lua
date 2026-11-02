-- Módulo de comunicação interna do OTClient com o cérebro da Kirie
local clientSocket = nil

function init()
  -- Conecta na porta local aberta pelo script em Python
  clientSocket = g_network.createSocket()
  clientSocket:connect("127.0.0.1", 9000)

  -- Conecta o sensor de logs nativos do chat do jogo
  connect(g_game, { onTextMessage = onMessageReceived })
  print("[Kirie Client] Módulo conectado com o script Python em segundo plano.")
end

function terminate()
  disconnect(g_game, { onTextMessage = onMessageReceived })
  if clientSocket then
    clientSocket:disconnect()
  end
end

function onMessageReceived(mode, text)
  -- Identifica o tipo do canal e repassa limpo para o Python
  local channel = "local"
  if mode == MessageModes.DamageDealt or mode == MessageModes.DamageReceived then
    channel = "damage"
  elseif mode == MessageModes.NpcFrom or mode == MessageModes.NpcTo then
    channel = "npc"
  end
  
  if clientSocket and clientSocket:isConnected() then
    -- Envia no formato esperado pelo nosso Parser em Python: CHANNEL|SPEAKER|MESSAGE
    clientSocket:send(channel .. "|Server|" .. text)
  end
end
