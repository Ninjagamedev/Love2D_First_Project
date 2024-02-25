
local anim8 = require 'lib/anim8'

function love.load()
    --Categoria das colisões
    CATEGORY_PLAYER = 1
    CATEGORY_GROUND = 2
    CATEGORY_BOOSTER_HITBOX = 3

    --Jump Buffer Time
    JUMP_BUFFER_TIME = 0.1

    --Friction
    GROUND_FRICTION = 300
    AIR_FRICTION = 10
    
    love.physics.setMeter(64)
    world = love.physics.newWorld(0, 9.81*64, true)

    source = love.audio.newSource("AbsoluteBanger.wav", "static")
    --Lista de objetos
    objects = {}

    --Criando chão
    objects.ground = {}
    objects.ground.body = love.physics.newBody(world, 650/2, 600-50/2)
    objects.ground.shape = love.physics.newRectangleShape(650, 50)
    objects.ground.fixture = love.physics.newFixture(objects.ground.body, objects.ground.shape)
    objects.ground.fixture:setCategory(CATEGORY_GROUND)
    objects.ground.fixture:setFriction(1) -- Faz com que a bola pare de deslizar
    --objects.ground.fixture:setUserData("Ground") -- Setar um nome para o chão

    objects.wallLeft = {}
    objects.wallLeft.body = love.physics.newBody(world, 50, 650/2)
    objects.wallLeft.shape = love.physics.newRectangleShape(50, 650)
    objects.wallLeft.fixture = love.physics.newFixture(objects.wallLeft.body, objects.wallLeft.shape)
    objects.wallLeft.fixture:setCategory(CATEGORY_GROUND) -- Setar um nome para a parede esquerda



    Jumps = 0


    --! Alterar todas as instancias de player para player
    player = {
        states = {
            idle = false,
            grounded = false,
            moving = false,
            jumping = false
        }
    }
    player.scaleX = 2
    player.scaleY = 2
    --player.image = love.graphics.newImage("player.png")
    --Importar a sprite sheet

    --! VERIFICAR COMO RAIOS ISTO FUNCIONA EM TERMOS DA SPRITESHEETSSSSSSSSSSSSSSSSSSSS
    player.spriteSheet = love.graphics.newImage('Sprites/running_dino.png')
    player.widthV = 24
    player.heightV = player.spriteSheet:getHeight() - 4
    player.height = player.heightV * player.scaleX
    player.width = player.widthV * player.scaleY
    player.body = love.physics.newBody(world, 650/2, 650/2, "dynamic")
    player.shape = love.physics.newRectangleShape(player.width, player.height)
    player.fixture = love.physics.newFixture(player.body, player.shape, 1) -- Um fixture é um objeto que liga uma forma a um corpo e pode ser usado para testar colisões.
    player.fixture:setCategory(CATEGORY_PLAYER) -- Categoria para o jogador para tratar das colisões
    player.jumpBuffer = 0
    player.inBoosterRange = false
    player.currentBooster = nil
    player.maxSpeed = 300
    player.acceleration = 600


    --Tamanho de cada frame na sprite sheet
    spriteHeight = 24
    spriteWidth = 24
    player.grid = anim8.newGrid(spriteWidth, spriteHeight, player.spriteSheet:getWidth(), player.spriteSheet:getHeight())


    player.animations = {}
    player.animations.walk = anim8.newAnimation(player.grid('1-6', 1), 0.05)

    -- Replace player stuff with player States, check love library to do that

        --[[
        List of stuff that will be replaced:
            player.isOnGround
            player.isOnAir
            player.inBoosterRange
            player.isJumping
        ]]--


    boosters = {} -- Tabela de Boosters

    table.insert(boosters, {
        x = 650/1.5,
        y = 650/1.5,
        radius = 20,
        hitbox = {}
    })

    table.insert(boosters, {
        x = 650/1.5,
        y = 100/1.5,
        radius = 20,
        hitbox = {}
    })


    for i, booster in ipairs(boosters) do
        booster.hitbox.body = love.physics.newBody(world, booster.x, booster.y, "static")
        booster.hitbox.shape = love.physics.newCircleShape(50)
        booster.hitbox.fixture = love.physics.newFixture(booster.hitbox.body, booster.hitbox.shape, 1)
        booster.hitbox.fixture:setCategory(CATEGORY_BOOSTER_HITBOX)
        booster.hitbox.fixture:setUserData(booster) -- Setar um nome para o hitbox do booster
        booster.hitbox.fixture:setSensor(true)
    end
    
    --Criar uma bola
    objects.ball = {}
    objects.ball.body = love.physics.newBody(world, 650/1.5, 650/1.5, "dynamic")
    player.body:setFixedRotation(true)
    objects.ball.shape = love.physics.newCircleShape(20) --Bola com um raio de 20
    objects.ball.fixture = love.physics.newFixture(objects.ball.body, objects.ball.shape, 1) -- Um fixture é um objeto que liga uma forma a um corpo e pode ser usado para testar colisões.
    objects.ball.fixture:setUserData("Ball") -- Setar um nome para a bola
    objects.ball.fixture:setRestitution(0) -- Faz com que a bola seja elástica

    world:setCallbacks(beginContact, endContact)

    --let's create a couple blocks to play around with
    objects.block1 = {}
    objects.block1.body = love.physics.newBody(world, 200, 550, "dynamic")
    objects.block1.shape = love.physics.newRectangleShape(0, 0, 50, 100)
    objects.block1.fixture = love.physics.newFixture(objects.block1.body, objects.block1.shape, 0.1) -- A higher density gives it more mass.
    objects.block1.fixture:setCategory(CATEGORY_GROUND) -- Setar um nome para o bloco

    objects.block2 = {}
    objects.block2.body = love.physics.newBody(world, 200, 400, "dynamic")
    objects.block2.shape = love.physics.newRectangleShape(0, 0, 100, 50)
    objects.block2.fixture = love.physics.newFixture(objects.block2.body, objects.block2.shape, 0.1)
    objects.block2.fixture:setCategory(CATEGORY_GROUND) -- Setar um nome para o bloco

      --initial graphics setup
  love.graphics.setBackgroundColor(0.41, 0.53, 0.97) --set the background color to a nice blue
  love.window.setMode(650, 650) --set the window dimensions to 650 by 650 with no fullscreen, vsync on, and no antialiasing
  world:setCallbacks(beginContact, endContact) -- Chamada de funções para colisões
end


function love.draw()
    love.graphics.setColor(0.28, 0.63, 0.05)
    love.graphics.polygon("fill", objects.ground.body:getWorldPoints(objects.ground.shape:getPoints())) -- Desenha o chão
    love.graphics.polygon("fill", objects.wallLeft.body:getWorldPoints(objects.wallLeft.shape:getPoints())) -- Desenha a parede esquerda
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Current FPS: "..tostring(love.timer.getFPS( )), 10, 10)
    --Desenha o circulo
    love.graphics.setColor(1,1,1)
    --love.graphics.draw(player.image, player.body:getX(), player.body:getY(), player.body:getAngle(), player.scaleX, player.scaleY, player.image:getWidth()/2, player.image:getHeight()/2)
    --Tamanho do sprite
    --local spriteWidth, spriteHeight = player.animations.walk:getDimensions()
    --Calcular metade da distancia para centrar o sprite na hitbox

    --Centrar o sprite quando desenhado
    player.animations.walk:draw(player.spriteSheet, player.body:getX(), player.body:getY(), player.body:getAngle(), player.scaleX, player.scaleY, spriteWidth / 2, spriteHeight / 2)


    love.graphics.setColor(1, 0, 0) -- Set the color to red
    love.graphics.line(player.rayStartX, player.rayStartY, player.rayEndX, player.rayEndY)

    --Mostrar jumps no ecrã
    love.graphics.print("Jumps: " .. Jumps, 10, 10)


    love.graphics.circle("fill", objects.ball.body:getX(), objects.ball.body:getY(), objects.ball.shape:getRadius())
    love.graphics.setColor(0, 1, 0) -- Set the color to red   
    for i, booster in ipairs(boosters) do
        love.graphics.circle("fill", booster.x, booster.y, booster.radius) -- Desenha o booster
        love.graphics.setColor(1, 0, 0) -- Set the color to red
        love.graphics.circle("line", booster.hitbox.body:getX(), booster.hitbox.body:getY(), booster.hitbox.shape:getRadius()) -- Desenha o hitbox do booster
      
    end
    --Desenha os blocos
    love.graphics.setColor(0.20, 0.20, 0.20) -- set the drawing color to grey for the blocks
    love.graphics.polygon("fill", objects.block1.body:getWorldPoints(objects.block1.shape:getPoints()))
    love.graphics.polygon("fill", objects.block2.body:getWorldPoints(objects.block2.shape:getPoints()))

end

function drawDebugHitboxes()
    --Calcular o tamanho da hitbox com o tamanho do sprite * a scale
    local hitboxWidth = spriteWidth * player.scaleX
    local hitboxHeight = spriteHeight * player.scaleY
    --Como o sprite é colocado no canto superior esquerdo temos de o centrar dividindo por 2 tanto na altura como na largura
    local halfWidth = hitboxWidth / 2
    local halfHeight = hitboxHeight / 2
    love.graphics.setColor(0,1,0)
    --Hitbox do proprio sprite
    love.graphics.rectangle("line", player.body:getX() - halfWidth, player.body:getY() - halfHeight, hitboxWidth, hitboxHeight)
    love.graphics.setColor(0,0,1)
    --Vamos buscar os pontos de onde está o shape ligado ao player que consequentemente está ligado ao body
    local x1, y1, x2, y2, x3, y3, x4, y4 = player.body:getWorldPoints(player.shape:getPoints())
    --Com todos os pontos criamos a hitbox que é a hitbox de colisão do player
    love.graphics.polygon("line", x1, y1, x2, y2, x3, y3, x4, y4)
end






function love.update(dt)
    world:update(dt) --this puts the world into motion

    if not source:isPlaying() then
        source:play()
    end

    
        -- Check if the player is grounded
        rayCastGround()

        for state, isActive in pairs(player.states) do
            if isActive then
                print("Active state: " .. state)
            end
        end

        -- Update the player's position
        ControllerHandler(dt)
        if player.jumpBuffer ~= 0 then
            jump()
        end

        player.animations.walk:update(dt)

end


function setState(state, value)
    print ("STATE MUDADO")
    if player.states[state] ~= nil then
        player.states[state] = value
    end
end



function checkState()
    for state in pairs(player.states) do
    if state == player.state then   
        player.states[state] = true
    else
        player.states[state] = false
    end
    end
end


--Gestão das colisões entre o jogador e os boosters --

function isCollidingWithBooster(aData, bData, booster)
    return (aData == CATEGORY_PLAYER and bData == CATEGORY_BOOSTER_HITBOX) or (aData == CATEGORY_BOOSTER_HITBOX and bData == CATEGORY_PLAYER)
end

function beginContact(a, b, coll)



    --Quando o jogador entra em contacto com um objeto
    local objectACategory = a:getCategory()
    local objectBCategory = b:getCategory()
    local objectAUserData = a:getUserData()
    local objectBUserData = b:getUserData()
    --Verifica se o jogador está em contacto com um booster
    --Verificar se é um "BoosterHitbox" e um "Player" que estão em contacto
    if isCollidingWithBooster(objectACategory, objectBCategory) then
        print("Player entered the large circle's area!")
        for i, booster in ipairs(boosters) do
            print("Checking booster " .. i)
            if objectAUserData == booster or objectBUserData == booster then
                print("Player entered the large circle's area!")
                player.inBoosterRange = true
                player.currentBooster = booster -- Remember the booster the player is currently in range of
            end
        end
    end
end

function endContact(a, b, coll)
    local objectACategory = a:getCategory()
    local objectBCategory = b:getCategory()
    if isCollidingWithBooster(objectACategory, objectBCategory) then
        print("Player left the large circle's area!")
        player.inBoosterRange = false
        player.currentBooster = nil -- Booster ends contacto
    end
end
-- Fim da gestão das colisões entre o jogador e os boosters -- 




function incrementJumps()
    Jumps = Jumps + 1
end

--Gestão do movimento do jogador e verificação de colisões --

function ControllerHandler(dt)

    local isMoving = love.keyboard.isDown("d") or love.keyboard.isDown("a")
    if (love.keyboard.isDown("d")) then
        movement("d")
    end

    if (love.keyboard.isDown("a")) then
        movement("a")
    end

    if not isMoving then

        movement("none")
    end


    if (love.keyboard.isDown("s")) then
        --player.body:applyLinearImpulse(0, fallSpeed)
    end
    if (love.keyboard.isDown('escape')) then
        love.event.quit()
    end
end


function movement(key)
    local maxSpeed = player.maxSpeed
    local acceleration = player.acceleration


    local vx, vy = player.body:getLinearVelocity()

    if key == "d" and vx < maxSpeed then
        player.body:applyForce(acceleration, 0)
        player.scaleX = 2
    end

    if key == "a" and vx > -maxSpeed then
        player.body:applyForce(-acceleration, 0)
        player.scaleX = -2
    end 

    if key == "none" and player.states.moving == true then
        --print("Not moving")
        local friction = GROUND_FRICTION
        if vx > 0 then
            player.body:applyForce(-friction, 0)
        elseif vx < 0 then
            player.body:applyForce(friction, 0)
        end
    end

    if vx == 0 then
        setState("moving", false)
        setState("idle", true)
    else
        setState("moving", true)
        setState("idle", false)
    end

    --print("Current Speed" .. vx)

end

function rayCastGround()
    local playerX, playerY = player.body:getPosition()
    local playerWidth = player.width
    local playerHeight = player.height
    local rayStartX = playerX
    local rayStartY = playerY + playerHeight / 2
    local rayEndX = playerX
    local rayEndY = playerY + playerHeight / 2 + 10
    local groundFound = false
    world:rayCast(playerX, playerY + playerHeight / 2, playerX, playerY + playerHeight / 2 + 10, function(fixture, x, y, xn, yn, fraction)
        if fixture:getCategory() == CATEGORY_GROUND then
            groundFound = true
            return 0 -- Stop the raycast
        end
        return 1 -- Continue the raycast
    end)
    setState("grounded", groundFound)
    player.rayStartX = rayStartX
    player.rayStartY = rayStartY
    player.rayEndX = rayEndX
    player.rayEndY = rayEndY
end

-- Fim da gestão do movimento do jogador e verificação de colisões -- 



function love.keypressed(key)
    if key == "w" then
        print ("Jump key pressed!")
        player.jumpBuffer = love.timer.getTime()
        print("Keypressed :" .. player.jumpBuffer)

    end
    if key == "space" and player.inBoosterRange then
        Boost()
    end
end

-- A função de salto funciona com um buffer que é dado um valor quando a tecla de salto é pressionada
-- Se o jogador estiver no chão e o buffer for menor que um determinado valor, o jogador salta
function jump()
    if (player.states.grounded == true and love.timer.getTime() - player.jumpBuffer <= JUMP_BUFFER_TIME) then
        print ("Jumping!")
        local vx, vy = player.body:getLinearVelocity()
        local jumpSpeed = 200
        player.body:applyLinearImpulse(0, -jumpSpeed)
        incrementJumps()
        player.jumpBuffer = 0
    end 
end

--TODO Melhorar o codigo do boost

function Boost()
    --Obter a posição do jogador e do booster  
    local playerX, playerY = player.body:getPosition()
    local booster = player.currentBooster
    --Calcular a direção do boost, localização do booster - localização do jogador
    local boostDirection = { x = booster.x - playerX, y = booster.y - playerY }
    --Normalizar a direção do boost, raiz quadrada de x^2 + y^2
    local magnitude = math.sqrt(boostDirection.x^2 + boostDirection.y^2)
    boostDirection.x = boostDirection.x / magnitude
    boostDirection.y = boostDirection.y / magnitude
    --Aplicar o boost
    local boostSpeed = 300
    player.body:applyLinearImpulse(boostDirection.x * boostSpeed, boostDirection.y * boostSpeed)

end 
            


