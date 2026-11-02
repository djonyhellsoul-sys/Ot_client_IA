-- Módulo de comunicação interna do OTClient com o cérebro da Kirie
local clientSocket = nil

function init()
  -- Cria o conector de rede local
  clientSocket = g_network.createSocket()
  
  -- Tenta conectar na porta 9000 aberta pelo Python
  clientSocket:connect("127.0.0.1", 9000)

  -- Conecta os gatilhos nativos do chat do Tibia
  connect(g_game, { onTextMessage = onMessageReceived })
  print("[Kirie Client] Modulo conectado com o script Python em segundo plano.")
end

function terminate()
  disconnect(g_game, { onTextMessage = onMessageReceived })
  if clientSocket then
    clientSocket:disconnect()
  end
end

function onMessageReceived(mode, text)
  -- Identifica se a mensagem é de dano, npc ou chat local e repassa limpo
  local channel = "local"
  if mode == MessageModes.DamageDealt or mode == MessageModes.DamageReceived then
    channel = "damage"
  elseif mode == MessageModes.NpcFrom or mode == MessageModes.NpcTo then
    channel = "npc"
  end
  
  if clientSocket and clientSocket:isConnected() then
    -- Manda para o Python no formato correto: CHANNEL|SPEAKER|MESSAGE
    clientSocket:send(channel .. "|Server|" .. text)
  end
end
