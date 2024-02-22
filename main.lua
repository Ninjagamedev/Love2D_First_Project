
function love.load()

    
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
    objects.ground.fixture:setUserData("Ground") -- Setar um nome para o chão

    objects.wallLeft = {}
    objects.wallLeft.body = love.physics.newBody(world, 50, 650/2)
    objects.wallLeft.shape = love.physics.newRectangleShape(50, 650)
    objects.wallLeft.fixture = love.physics.newFixture(objects.wallLeft.body, objects.wallLeft.shape)
    objects.wallLeft.fixture:setUserData("Ground") -- Setar um nome para a parede esquerda


    animation = newAnimation(love.graphics.newImage("oldHero.png"), 16, 18, 1)

    Jumps = 0


    --! Alterar todas as instancias de player para player
    player = {}
    player.scaleX = 0.2
    player.scaleY = 0.2
    player.image = love.graphics.newImage("player.png")
    player.height = player.image:getHeight() * player.scaleY
    player.width = player.image:getWidth() * player.scaleX
    player.body = love.physics.newBody(world, 650/2, 650/2, "dynamic")
    player.shape = love.physics.newRectangleShape(player.width, player.height)
    player.fixture = love.physics.newFixture(player.body, player.shape, 1) -- Um fixture é um objeto que liga uma forma a um corpo e pode ser usado para testar colisões.
    player.fixture:setUserData("Player") -- Setar um nome para o jogador
    player.inBoosterRange = false
    player.currentBooster = nil
    player.isOnGround = false

    boosters = {} -- Tabela de Boosters

    table.insert(boosters, {
        x = 650/1.5,
        y = 650/1.5,
        radius = 20,
        hitbox = {}
    })
    boosters[1].hitbox.body = love.physics.newBody(world, boosters[1].x, boosters[1].y, "static")
    boosters[1].hitbox.shape = love.physics.newCircleShape(50)
    boosters[1].hitbox.fixture = love.physics.newFixture(boosters[1].hitbox.body, boosters[1].hitbox.shape, 1)
    boosters[1].hitbox.fixture:setUserData("BoosterHitbox")
    boosters[1].hitbox.fixture:setSensor(true)

    
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
    objects.block1.fixture:setUserData("Ground") -- Setar um nome para o bloco

    objects.block2 = {}
    objects.block2.body = love.physics.newBody(world, 200, 400, "dynamic")
    objects.block2.shape = love.physics.newRectangleShape(0, 0, 100, 50)
    objects.block2.fixture = love.physics.newFixture(objects.block2.body, objects.block2.shape, 0.1)
    objects.block2.fixture:setUserData("Ground") -- Setar um nome para o bloco

      --initial graphics setup
  love.graphics.setBackgroundColor(0.41, 0.53, 0.97) --set the background color to a nice blue
  love.window.setMode(650, 650) --set the window dimensions to 650 by 650 with no fullscreen, vsync on, and no antialiasing
  world:setCallbacks(beginContact, endContact) -- Chamada de funções para colisões
end


function newAnimation(image, width, height, duration)
    local animation = {}
    animation.spriteSheet = image;
    animation.quads = {}

    for y = 0, image:getHeight() - height, height do
        for x = 0, image:getWidth() - width, width do
            table.insert(animation.quads, love.graphics.newQuad(x, y, width, height, image:getDimensions()))
        end
    end

    animation.duration = duration or 1
    animation.currentTime = 0

    return animation
end

function love.draw()
    love.graphics.setColor(0.28, 0.63, 0.05)
    love.graphics.polygon("fill", objects.ground.body:getWorldPoints(objects.ground.shape:getPoints())) -- Desenha o chão
    love.graphics.polygon("fill", objects.wallLeft.body:getWorldPoints(objects.wallLeft.shape:getPoints())) -- Desenha a parede esquerda
    --Desenha o circulo
    love.graphics.setColor(0.76, 0.18, 0.05)
    love.graphics.draw(player.image, player.body:getX(), player.body:getY(), player.body:getAngle(), player.scaleX, player.scaleY, player.image:getWidth()/2, player.image:getHeight()/2)
    
    love.graphics.setColor(1, 0, 0) -- Set the color to red
    love.graphics.line(player.rayStartX, player.rayStartY, player.rayEndX, player.rayEndY)

    local spriteNum = math.floor(animation.currentTime / animation.duration * #animation.quads) + 1
    love.graphics.draw(animation.spriteSheet, animation.quads[spriteNum], 0, 100, 0, 1)

    --Mostrar jumps no ecrã
    love.graphics.print("Jumps: " .. Jumps, 10, 10)


    love.graphics.circle("fill", objects.ball.body:getX(), objects.ball.body:getY(), objects.ball.shape:getRadius())
    love.graphics.setColor(0, 1, 0) -- Set the color to red   
    love.graphics.circle("fill", boosters[1].x, boosters[1].y, boosters[1].radius) -- Desenha o booster
    --Draw hitbox
    love.graphics.setColor(1, 0, 0) -- Set the color to red
    love.graphics.circle("line", boosters[1].hitbox.body:getX(), boosters[1].hitbox.body:getY(), boosters[1].hitbox.shape:getRadius()) -- Desenha o hitbox do booster
    --Desenha os blocos
    love.graphics.setColor(0.20, 0.20, 0.20) -- set the drawing color to grey for the blocks
    love.graphics.polygon("fill", objects.block1.body:getWorldPoints(objects.block1.shape:getPoints()))
    love.graphics.polygon("fill", objects.block2.body:getWorldPoints(objects.block2.shape:getPoints()))

end





function love.update(dt)
    world:update(dt) --this puts the world into motion

    if not source:isPlaying() then
        source:play()
    end

    animation.currentTime = animation.currentTime + dt
    if animation.currentTime >= animation.duration then
        animation.currentTime = animation.currentTime - animation.duration
    end




      -- Add drag to the player's movement
      local vx, vy = player.body:getLinearVelocity()
      local drag = 1 -- Adjust this value to get the desired drag effect
      player.body:setLinearVelocity(vx * (1 - drag * dt), vy)
    
        -- Check if the player is grounded
        rayCastGround()

        -- Update the player's position
        ControllerHandler()
end

function beginContact(a, b, coll)



    --Quando o jogador entra em contacto com um objeto
    local aData = a:getUserData()
    local bData = b:getUserData()
    --Verifica se o jogador está em contacto com um booster
    --Verificar se é um "BoosterHitbox" e um "Player" que estão em contacto
    if isCollidingWithBooster(aData, bData) then
        print("Player entered the large circle's area!")
        for i, booster in ipairs(boosters) do
            print("Checking booster " .. i)
            if isCollidingWithBooster(aData, bData, booster) then
                print("Player entered the large circle's area!")
                player.inBoosterRange = true
                player.currentBooster = booster -- Remember the booster the player is currently in range of
            end
        end
    end
end


function endContact(a, b, coll)
    local aData = a:getUserData()
    local bData = b:getUserData()
    if isCollidingWithBooster(aData, bData) then
        print("Player left the large circle's area!")
        player.inBoosterRange = false
        player.currentBooster = nil -- Booster ends contacto
    end
end


function isCollidingWithBooster(aData, bData, booster)
    return (aData == "Player" and bData == "BoosterHitbox") or (aData == "BoosterHitbox" and bData == "Player")
end


function incrementJumps()
    Jumps = Jumps + 1
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
        if fixture:getUserData() == "Ground" then
            groundFound = true
            return 0 -- Stop the raycast
        end
        return 1 -- Continue the raycast
    end)
    player.isOnGround = groundFound

    player.rayStartX = rayStartX
    player.rayStartY = rayStartY
    player.rayEndX = rayEndX
    player.rayEndY = rayEndY
end


function ControllerHandler()
    local maxSpeed = 200
    local acceleration = 500
    local fallSpeed = 50
    local vx, vy = player.body:getLinearVelocity()
    if (love.keyboard.isDown("d")) then
        if vx < maxSpeed then
            player.body:applyForce(acceleration, 0)
        end
        player.scaleX = 0.2
    end
    if (love.keyboard.isDown("a")) then
        if vx > -maxSpeed then
            player.body:applyForce(-acceleration, 0)
        end
        player.scaleX = -0.2
    end
    if (love.keyboard.isDown("s")) then
        player.body:applyLinearImpulse(0, fallSpeed)
    end
    if (love.keyboard.isDown('escape')) then
        love.event.quit()
    end
end




function love.keypressed(key)
    if key == "w" and player.isOnGround then
        print ("Jumping!")
        local vx, vy = player.body:getLinearVelocity()
        local jumpSpeed = 500
        player.body:setLinearVelocity(vx, -jumpSpeed)
        incrementJumps()
    end
    if key == "space" and player.inBoosterRange then
        Boost()
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
            


