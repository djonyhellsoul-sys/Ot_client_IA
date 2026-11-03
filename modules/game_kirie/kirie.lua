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
-- Adicione esta rotina para escutar o que o Python manda de volta
function onIncomingPythonCommand()
  if clientSocket and clientSocket:isConnected() then
    local data = clientSocket:receive()
    if data then
      -- Separa o comando e o valor (Ex: WALK:North)
      local separator = data:find(":")
      if separator then
        local command = data:sub(1, separator - 1)
        local value = data:sub(separator + 1):gsub("\n", ""):gsub("\r", "")
        
        if command == "WALK" then
          -- Executa a caminhada nativa em segundo plano sem mexer no mouse!
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
  -- Agenda a próxima checagem em 50 milissegundos para manter o reflexo rápido
  scheduleEvent(onIncomingPythonCommand, 50)
end