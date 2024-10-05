--// Nurysium last build  💖
--// Be happy about it

local RobloxReplicatedStorage = cloneref(game:GetService('RobloxReplicatedStorage'))
local RbxAnalyticsService = cloneref(game:GetService('RbxAnalyticsService'))
local ReplicatedStorage = cloneref(game:GetService('ReplicatedStorage'))
local UserInputService = cloneref(game:GetService('UserInputService'))
local NetworkClient = cloneref(game:GetService("NetworkClient"))
local TweenService = cloneref(game:GetService('TweenService'))
local VirtualUser = cloneref(game:GetService('VirtualUser'))
local HttpService = cloneref(game:GetService('HttpService'))
local RunService = cloneref(game:GetService('RunService'))
local LogService = cloneref(game:GetService('LogService'))
local Lighting = cloneref(game:GetService('Lighting'))
local CoreGui = cloneref(game:GetService('CoreGui'))
local Players = cloneref(game:GetService('Players'))
local Debris = cloneref(game:GetService('Debris'))
local Stats = cloneref(game:GetService('Stats'))

if not game:IsLoaded() then
    game.Loaded:Wait()
end

local crypter = loadstring(game:HttpGet(('https://raw.githubusercontent.com/Egor-Skriptunoff/pure_lua_SHA/master/sha2.lua'), true))()
local notify = loadstring(game:HttpGet('https://raw.githubusercontent.com/flezzpe/Nurysium/main/notify_UI.lua'))()

notify.__init({
	parent = cloneref(game:GetService('CoreGui'))
})

setfpscap(200)

local LocalPlayer = Players.LocalPlayer
local client_id = RbxAnalyticsService:GetClientId()

local names_map = {
	['protected'] = crypter.sha3_384(client_id, 'sha3-256'),
	
	['Pillow'] = crypter.sha3_384(client_id .. 'Pillow', 'sha3-256'),
	['Touhou'] = crypter.sha3_384(client_id .. 'Touhou', 'sha3-256'),
	['Shion'] = crypter.sha3_384(client_id .. 'Shion', 'sha3-256'),
	['Miku'] = crypter.sha3_384(client_id .. 'Miku', 'sha3-256'),
	['Sino'] = crypter.sha3_384(client_id .. 'Sino', 'sha3-256'),
	['Soi'] = crypter.sha3_384(client_id .. 'Soi', 'sha3-256')
}

local interface = loadstring(game:HttpGet('https://raw.githubusercontent.com/flezzpe/EvadeAutoBHOP/main/libs/ef.java'))()

local assets = game:GetObjects('rbxassetid://98657300657778')[1]

assets.Parent = RobloxReplicatedStorage
assets.Name = names_map['protected']

local effects_folder = assets.effects
local objects_folder = assets.objects
local sounds_folder = assets.sounds
local gui_folder = assets.gui

local watermark_asset = gui_folder.watermark
local watermark = watermark_asset:Clone()

local color_shift_effect = Instance.new('ColorCorrectionEffect', assets)

local RunTime = workspace.Runtime
local Alive = workspace.Alive
local Dead = workspace.Dead

local AutoParry = {
	ball = nil,
	target = nil,
	entity_properties = nil
}

local Player = {
	Entity = nil,

	properties = {
		grab_animation = nil
	}
}

Player.Entity = {
    properties = {
		sword = '',
		server_position = Vector3.zero,
		velocity = Vector3.zero,
		position = Vector3.zero,
        is_moving = false,
		speed = 0,
		ping = 0
    }
}

local World = {}

AutoParry.ball = {
	training_ball_entity = nil,
	client_ball_entity = nil,
    ball_entity = nil,
    
    properties = {
		aero_dynamic_time = tick(),
		hell_hook_completed = true,
		last_position = Vector3.zero,
		rotation = Vector3.zero,
		position = Vector3.zero,
		last_warping = tick(),
        parry_remote = nil,
		is_curved = false,
		last_tick = tick(),
        auto_spam = false,
        cooldown = false,
		respawn_time = 0,
        parry_range = 0,
        spam_range = 0,
        maximum_speed = 0,
		old_speed = 0,
        parries = 0,
		direction = 0,
        distance = 0,
        velocity = 0,
        last_hit = 0,
		lerp_radians = 0,
		radians = 0,
		speed = 0,
		dot = 0
    }
}

AutoParry.target = {
    current = nil,
    from = nil,
    aim = nil,
}

AutoParry.entity_properties = {
    server_position = Vector3.zero,
	velocity = Vector3.zero,
	is_moving = false,
	direction = 0,
	distance = 0,
	speed = 0,
	dot = 0
}


function create_animation(object: Instance, info: TweenInfo, value: table)
	local animation = TweenService:Create(object, info, value)

	animation:Play()
			
	task.wait(info.Time)
	
	Debris:AddItem(animation, 0)
	animation:Destroy()
	animation = nil
end

local ConnectionsManager = {}

function ConnectionsManager:disconnect()
    if not ConnectionsManager[self] then
        return
    end

    ConnectionsManager[self]:Disconnect()
    ConnectionsManager[self] = nil
end


function ConnectionsManager:abadone()
	interface.flags = {}
	
	for _, connection in ConnectionsManager do
		if typeof(connection) == 'function' then
			continue
		end

		connection:Disconnect()
		connection = nil
	end
end

ConnectionsManager['controller'] = RunService.Heartbeat:Connect(function()
	if not interface.disconnected then
		return
	end

	ConnectionsManager.abadone()
end)

local function linear_predict(a: any, b: any, time_volume: number)
    return a + (b - a) * time_volume
end

function World:get_pointer()
    local mouse_location = UserInputService:GetMouseLocation()
    local ray = workspace.CurrentCamera:ScreenPointToRay(mouse_location.X, mouse_location.Y, 0)

    return CFrame.lookAt(ray.Origin, ray.Origin + ray.Direction)
end

function AutoParry.get_ball()
    for _, ball in workspace.Balls:GetChildren() do
        if ball:GetAttribute("realBall") then
            return ball
        end
    end
end

function AutoParry.get_client_ball()
    for _, ball in workspace.Balls:GetChildren() do
        if not ball:GetAttribute("realBall") then
            return ball
        end
    end
end

function Player:get_aim_entity()
	local closest_entity = nil
	local minimal_dot_product = -math.huge
	local camera_direction = workspace.CurrentCamera.CFrame.LookVector

	for _, player in Alive:GetChildren() do
		if not player then
			continue
		end

		if player.Name ~= LocalPlayer.Name then
			if not player:FindFirstChild('HumanoidRootPart') then
				continue
			end

			local entity_direction = (player.HumanoidRootPart.Position - workspace.CurrentCamera.CFrame.Position).Unit
			local dot_product = camera_direction:Dot(entity_direction)
	
			if dot_product > minimal_dot_product then
				minimal_dot_product = dot_product
				closest_entity = player
			end
		end
	end

	return closest_entity
end

function Player:get_closest_player_to_cursor()
    local closest_player = nil
    local minimal_dot_product = -math.huge

    for _, player in workspace.Alive:GetChildren() do
        if player == LocalPlayer.Character then
            continue
        end
        
        if player.Parent ~= Alive then
            continue
        end

        local player_direction = (player.PrimaryPart.Position - workspace.CurrentCamera.CFrame.Position).Unit
        local pointer = World.get_pointer()
        local dot_product = pointer.LookVector:Dot(player_direction)

        if dot_product > minimal_dot_product then
            minimal_dot_product = dot_product
            closest_player = player
        end
    end

    return closest_player
end

function AutoParry.get_parry_remote()
	for _, object in { cloneref(game:GetService('AdService')), cloneref(game:GetService('SocialService')) }  do
		local temp_remote = object:FindFirstChildOfClass('RemoteEvent')

		if not temp_remote then
			continue
		end

		if not temp_remote.Name:find('\n') then
			continue
		end

		AutoParry.ball.properties.parry_remote = temp_remote
	end
end

AutoParry.get_parry_remote()

function AutoParry.perform_grab_animation()
	local animation = ReplicatedStorage.Shared.SwordAPI.Collection.Default:FindFirstChild('GrabParry')
	local currently_equipped = Player.Entity.properties.sword
    
	if not currently_equipped or currently_equipped == 'Titan Blade' then
        return
    end

	if not animation then
		return
	end

	local sword_data = ReplicatedStorage.Shared.ReplicatedInstances.Swords.GetSword:Invoke(currently_equipped)

	if not sword_data or not sword_data['AnimationType'] then
        return
    end

	local character = LocalPlayer.Character

	if not character or not character:FindFirstChild('Humanoid') then
		return
	end

	for _, object in ReplicatedStorage.Shared.SwordAPI.Collection:GetChildren() do
        if object.Name ~= sword_data['AnimationType'] then
            continue
        end
		
		if not (object:FindFirstChild('GrabParry') or object:FindFirstChild('Grab')) then
            continue
        end

		local sword_animation_type = 'GrabParry'

		if object:FindFirstChild('Grab') then
			sword_animation_type = 'Grab'
		end

        animation = object[type]
    end

	Player.properties.grab_animation = character.Humanoid:LoadAnimation(animation)
	Player.properties.grab_animation:Play()
end

function AutoParry.perform_parry()
	local ball_properties = AutoParry.ball.properties
	
	if ball_properties.cooldown and not ball_properties.auto_spam then
		return
	end

	ball_properties.parries += 1
	AutoParry.ball.properties.last_hit = tick()

	local camera = workspace.CurrentCamera
	local camera_direction = camera.CFrame.Position
	
	local direction = camera.CFrame
	local target_position = AutoParry.entity_properties.server_position
	
    if not ball_properties.auto_spam then
		AutoParry.perform_grab_animation()

		ball_properties.cooldown = true
	
		local current_curve = interface.flags['curve_method']

		if current_curve == 'Linear' then
			direction = CFrame.new(LocalPlayer.Character.PrimaryPart.Position, target_position)
		end

		if current_curve == 'Backwards' then
			direction = CFrame.new(camera_direction, (camera_direction + (-camera.CFrame.LookVector * 10000)) + Vector3.new(0, 1000, 0))
		end
	
		if current_curve == 'Random' then
			direction = CFrame.new(LocalPlayer.Character.PrimaryPart.Position, Vector3.new(math.random(-1000, 1000), math.random(-350, 1000), math.random(-1000, 1000)))
		end
	
		if current_curve == 'Accelerated' then
			direction = CFrame.new(LocalPlayer.Character.PrimaryPart.Position, target_position + Vector3.new(0, 150, 0))
		end
	else
		direction = CFrame.new(camera_direction, target_position + Vector3.new(0, 60, 0))

		ball_properties.parry_remote:FireServer(
			0,
			direction,
			{ [AutoParry.target.aim.Name] = target_position },
			{ target_position.X, target_position.Y },
			false
		)
	
		task.delay(0.25, function()
			if ball_properties.parries > 0 then
				ball_properties.parries -= 1
			end
		end)

		return
	end

	ball_properties.parry_remote:FireServer(
		0.5,
		direction,
		{ [AutoParry.target.aim.Name] = target_position },
		{ target_position.X, target_position.Y },
		false
	)

    task.delay(0.25, function()
        if ball_properties.parries > 0 then
            ball_properties.parries -= 1
        end
    end)
end

function AutoParry.reset()
	AutoParry.ball.properties.is_curved = false
    AutoParry.ball.properties.auto_spam = false
    AutoParry.ball.properties.cooldown = false
    AutoParry.ball.properties.maximum_speed = 0
    AutoParry.ball.properties.parries = 0
	AutoParry.entity_properties.server_position = Vector3.zero
	AutoParry.target.current = nil
	AutoParry.target.from = nil
end

ReplicatedStorage.Remotes.PlrHellHooked.OnClientEvent:Connect(function(hooker: Model)
	if hooker.Name == LocalPlayer.Name then
		AutoParry.ball.properties.hell_hook_completed = true

		return
	end

	AutoParry.ball.properties.hell_hook_completed = false
end)

ReplicatedStorage.Remotes.PlrHellHookCompleted.OnClientEvent:Connect(function()
	AutoParry.ball.properties.hell_hook_completed = true
end)

function AutoParry.is_curved()
	local target = AutoParry.target.current

	if not target then
		return false
	end

	local ball_properties = AutoParry.ball.properties
	local current_target = AutoParry.target.current.Name

	if target.PrimaryPart:FindFirstChild('MaxShield') and current_target ~= LocalPlayer.Name and ball_properties.distance < 50 then
		return false
	end

	if AutoParry.ball.ball_entity:FindFirstChild('TimeHole1') and current_target ~= LocalPlayer.Name and ball_properties.distance < 100 then
		ball_properties.auto_spam = false
		
		return false
	end

	if AutoParry.ball.ball_entity:FindFirstChild('WEMAZOOKIEGO') and current_target ~= LocalPlayer.Name and ball_properties.distance < 100 then
		return false
	end

	if AutoParry.ball.ball_entity:FindFirstChild('At2') and ball_properties.speed <= 0 then
		return true
	end

	if AutoParry.ball.ball_entity:FindFirstChild('AeroDynamicSlashVFX') then
		Debris:AddItem(AutoParry.ball.ball_entity.AeroDynamicSlashVFX, 0)

		ball_properties.auto_spam = false
		ball_properties.aero_dynamic_time = tick()
	end

	if RunTime:FindFirstChild('Tornado') then
		if ball_properties.distance > 5 and (tick() - ball_properties.aero_dynamic_time) < (RunTime.Tornado:GetAttribute("TornadoTime") or 1) + 0.314159 then
			return true
		end
	end

	if not ball_properties.hell_hook_completed and target.Name == LocalPlayer.Name and ball_properties.distance > 5 - math.random() then
		return true
	end
	
	local ball_direction = ball_properties.velocity.Unit
	local ball_speed = ball_properties.speed
	
	local speed_threshold = math.min(ball_speed / 100, 40)
	local angle_threshold = 40 * math.max(ball_properties.dot, 0)

	local player_ping = Player.Entity.properties.ping

	local accurate_direction = ball_properties.velocity.Unit
	accurate_direction *= ball_direction

	local direction_difference = (accurate_direction - ball_properties.velocity).Unit
	local accurate_dot = ball_properties.direction:Dot(direction_difference)
	local dot_difference = ball_properties.dot - accurate_dot
	local dot_threshold = 0.5 - player_ping / 1000

	local reach_time = ball_properties.distance / ball_properties.maximum_speed - (player_ping / 1000)
	local enough_speed = ball_properties.maximum_speed > 100

	local ball_distance_threshold = 15 - math.min(ball_properties.distance / 1000, 15) + angle_threshold + speed_threshold
	
	if enough_speed and reach_time > player_ping / 10 then
        ball_distance_threshold = math.max(ball_distance_threshold - 15, 15)
    end
	
	if ball_properties.distance < ball_distance_threshold then
		return false
	end

	if dot_difference < dot_threshold then
		return true
	end

	if ball_properties.lerp_radians < 0.018 then
		ball_properties.last_curve_position = ball_properties.position
		ball_properties.last_warping = tick() 
	end

	if (tick() - ball_properties.last_warping) < (reach_time / 1.5) then
		return true
	end

	return ball_properties.dot < dot_threshold
end

local old_from_target = nil :: Model

function AutoParry:is_spam() --// im autistic 😁
	local target = AutoParry.target.current

	if not target then
		return false
	end

	if AutoParry.target.from ~= LocalPlayer.Character then
		old_from_target = AutoParry.target.from
	end

	if self.parries < 3 and AutoParry.target.from == old_from_target then
		return false
	end

	local player_ping = Player.Entity.properties.ping
	local distance_threshold = 18 + (player_ping / 80)

	local ball_properties = AutoParry.ball.properties
	local reach_time = ball_properties.distance / ball_properties.maximum_speed - (player_ping / 1000)

	if (tick() - self.last_hit) > 0.8 and self.entity_distance > distance_threshold and self.parries < 3 then
		self.parries = 1

		return false
	end

 	if ball_properties.lerp_radians > 0.028 then
		if self.parries > 3 then
			self.parries = 1
		end

		return false
	end

	if (tick() - ball_properties.last_warping) < (reach_time / 1.3) and self.entity_distance > distance_threshold and self.parries < 4 then
		if self.parries > 3 then
			self.parries = 1
		end

		return false
	end

	if math.abs(self.speed - self.old_speed) < 5.2 and self.entity_distance > distance_threshold and self.speed < 60 and self.parries < 3 then
		if self.parries > 3 then
			self.parries = 0
		end

		return false
	end
	
	if self.speed < 10 then
		self.parries = 1

		return false
	end

	if self.maximum_speed < self.speed and self.entity_distance > distance_threshold then
		self.parries = 1
		
		return false
	end

	if self.entity_distance > self.range and self.entity_distance > distance_threshold then
		if self.parries > 2 then
			self.parries = 1
		end

		return false
	end

	if self.ball_distance > self.range and self.entity_distance > distance_threshold then
		if self.parries > 2 then
			self.parries = 2
		end

		return false
	end

	if self.last_position_distance > self.spam_accuracy and self.entity_distance > distance_threshold then
		if self.parries > 4 then
			self.parries = 2
		end

		return false
	end

	if self.ball_distance > self.spam_accuracy and self.ball_distance > distance_threshold then
		if self.parries > 3 then
			self.parries = 2
		end

		return false
	end

	if self.entity_distance > self.spam_accuracy and self.entity_distance > (distance_threshold - math.pi) then
		if self.parries > 3 then
			self.parries = 2
		end

		return false
	end

    return true	
end

function Player:claim_rewards()
	repeat
		task.wait(1)
	until not AutoParry.ball.properties.auto_spam

	local net = ReplicatedStorage:WaitForChild("Packages")['_Index']['sleitnick_net@0.1.0'].net

	ReplicatedStorage:WaitForChild("Remote"):WaitForChild("RemoteEvent"):FireServer('ClaimLoginReward')
	
	task.defer(function()
		for day = 1, 30 do
			task.wait()

			ReplicatedStorage.Remote.RemoteFunction:InvokeServer('ClaimNewDailyLoginReward', day)

			net:WaitForChild("RE/SummerWheel/ProcessRoll"):FireServer()
			net:WaitForChild("RE/SummerWheel/ClaimReward"):FireServer()

			net:WaitForChild("RE/ProcessTournamentEventRoll"):FireServer()
			net:WaitForChild("RE/CyborgWheel/ProcessRoll"):FireServer()
			net:WaitForChild("RE/SynthWheel/ProcessRoll"):FireServer()
			net:WaitForChild("RE/ProcessTournamentRoll"):FireServer()
			net:WaitForChild("RE/RolledReturnCrate"):FireServer()
			net:WaitForChild("RE/ProcessLTMRoll"):FireServer()
		end
	end)

	task.defer(function()
		for reward = 1, 6 do
			net:WaitForChild("RF/ClaimPlaytimeReward"):InvokeServer(reward)
			net:WaitForChild("RE/ClaimSeasonPlaytimeReward"):FireServer(reward)

			ReplicatedStorage:WaitForChild("Remote"):WaitForChild("RemoteFunction"):InvokeServer('SpinWheel')
			net:WaitForChild("RE/SpinFinished"):FireServer()
		end
	end)

	task.defer(function()
		for reward = 1, 5 do
			net:WaitForChild("RF/RedeemQuestsType"):InvokeServer('SummerClashEvent', 'Daily', reward)
		end
	end)

	task.defer(function()
		for reward = 1, 4 do
			net:WaitForChild("RE/SummerWheel/ClaimStreakReward"):FireServer(reward)
		end
	end)
end

RunService:BindToRenderStep('server position simulation', 1, function()
    local ping = Stats.Network.ServerStatsItem['Data Ping']:GetValue()

    if not LocalPlayer.Character then
        return
    end

    if not LocalPlayer.Character.PrimaryPart then
        return
    end

	local PrimaryPart = LocalPlayer.Character.PrimaryPart
    local old_position = PrimaryPart.Position

    task.delay(ping / 1000, function()
        Player.Entity.properties.server_position = old_position
	end)
end)

RunService.PreSimulation:Connect(function()
	NetworkClient:SetOutgoingKBPSLimit(math.huge)

	local character = LocalPlayer.Character
	
	if not character then
		return
	end

	if not character.PrimaryPart then
		return
	end

	local player_properties = Player.Entity.properties

	player_properties.sword = character:GetAttribute('CurrentlyEquippedSword')
    player_properties.ping = Stats.Network.ServerStatsItem['Data Ping']:GetValue()
    player_properties.velocity = character.PrimaryPart.AssemblyLinearVelocity
    player_properties.speed = Player.Entity.properties.velocity.Magnitude
    player_properties.is_moving = Player.Entity.properties.speed > 30
end)

AutoParry.ball.ball_entity = AutoParry.get_ball()
AutoParry.ball.client_ball_entity = AutoParry.get_client_ball()

RunService.PreSimulation:Connect(function()
	local ball = AutoParry.ball.ball_entity
	
	if not ball then
		return
	end

	local zoomies = ball:FindFirstChild('zoomies')

	local ball_properties = AutoParry.ball.properties

    ball_properties.position = ball.Position
	ball_properties.velocity = ball.AssemblyLinearVelocity

	if zoomies then
		ball_properties.velocity = ball.zoomies.VectorVelocity
      
