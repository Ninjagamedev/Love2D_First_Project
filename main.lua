
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

    --Criar o jogador
    objects.player = {}
    objects.player.scaleX = 0.2
    objects.player.scaleY = 0.2
    objects.player.image = love.graphics.newImage("player.png")
    objects.player.body = love.physics.newBody(world, 650/2, 650/2, "dynamic")
    objects.player.shape = love.physics.newRectangleShape(objects.player.image:getWidth() * objects.player.scaleX, objects.player.image:getHeight() * objects.player.scaleY)
    objects.player.fixture = love.physics.newFixture(objects.player.body, objects.player.shape, 1) -- Um fixture é um objeto que liga uma forma a um corpo e pode ser usado para testar colisões.
    objects.player.fixture:setUserData("Player") -- Setar um nome para o jogador
    objects.player.isOnGround = false

    
    --Criar uma bola
    objects.ball = {}
    objects.ball.body = love.physics.newBody(world, 650/1.5, 650/1.5, "dynamic")
    objects.player.body:setFixedRotation(true)
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
end

function love.draw()
    love.graphics.setColor(0.28, 0.63, 0.05)
    love.graphics.polygon("fill", objects.ground.body:getWorldPoints(objects.ground.shape:getPoints())) -- Desenha o chão
    love.graphics.polygon("fill", objects.wallLeft.body:getWorldPoints(objects.wallLeft.shape:getPoints())) -- Desenha a parede esquerda
    --Desenha o circulo
    love.graphics.setColor(0.76, 0.18, 0.05)
    love.graphics.draw(objects.player.image, objects.player.body:getX(), objects.player.body:getY(), objects.player.body:getAngle(), objects.player.scaleX, objects.player.scaleY, objects.player.image:getWidth()/2, objects.player.image:getHeight()/2)
    
    love.graphics.setColor(1, 0, 0) -- Set the color to red
    love.graphics.line(objects.player.rayStartX, objects.player.rayStartY, objects.player.rayEndX, objects.player.rayEndY)



    love.graphics.circle("fill", objects.ball.body:getX(), objects.ball.body:getY(), objects.ball.shape:getRadius())
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


      -- Add drag to the player's movement
      local vx, vy = objects.player.body:getLinearVelocity()
      local drag = 1 -- Adjust this value to get the desired drag effect
      objects.player.body:setLinearVelocity(vx * (1 - drag * dt), vy)
    
        -- Check if the player is grounded
        rayCastGround()

        -- Update the player's position
        ControllerHandler()
end

function rayCastGround()
    local playerX, playerY = objects.player.body:getPosition()
    local playerWidth = objects.player.image:getWidth() * objects.player.scaleX
    local playerHeight = objects.player.image:getHeight() * objects.player.scaleY
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
    objects.player.isOnGround = groundFound

    objects.player.rayStartX = rayStartX
    objects.player.rayStartY = rayStartY
    objects.player.rayEndX = rayEndX
    objects.player.rayEndY = rayEndY
end


function ControllerHandler()
    local maxSpeed = 200
    local acceleration = 500
    local fallSpeed = 50
    local vx, vy = objects.player.body:getLinearVelocity()
    if (love.keyboard.isDown("d")) then
        if vx < maxSpeed then
            objects.player.body:applyForce(acceleration, 0)
        end
        objects.player.scaleX = 0.2
    end
    if (love.keyboard.isDown("a")) then
        if vx > -maxSpeed then
            objects.player.body:applyForce(-acceleration, 0)
        end
        objects.player.scaleX = -0.2
    end
    if (love.keyboard.isDown("s")) then
        objects.player.body:applyLinearImpulse(0, fallSpeed)
    end
    if (love.keyboard.isDown('escape')) then
        love.event.quit()
    end
end




function love.keypressed(key)
    if key == "w" and objects.player.isOnGround then
        print ("Jumping!")
        local vx, vy = objects.player.body:getLinearVelocity()
        local jumpSpeed = 350
        objects.player.body:setLinearVelocity(vx, -jumpSpeed)
    end
end
