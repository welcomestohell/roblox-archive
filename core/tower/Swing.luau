const activation = require "@libs/activation"
const character = require "@libs/character"
const mounts = require "@libs/mounts"
const std = require "@libs/std"

const Swing = std.Mechanic {
	emoji = "🏌️",
	name = "Swing",
	description = "",
	instanceType = std.gt.instanceTree {
		Base = std.isA.BasePart(),
		Handle = std.isA.BasePart(),
	},

	Mode = std.Attribute("Mode", std.gt.literals("Hinge", "Omnidirectional"), "Hinge"),
	AnchorHandle = std.Attribute("AnchorHandle", std.gt.boolean(), true),
	Cooldown = std.Attribute("Cooldown", std.gt.number(), 1),

	std.AttributeSection "User Control",
	UserControlEnabled = std.Attribute("UserControlEnabled", std.gt.boolean(), true),
	UserControlForce = std.Attribute("UserControlForce", std.gt.positiveNumber, 750),
	UserControlMaximumVelocity = std.Attribute("UserControlMaximumVelocity", std.gt.positiveNumber, 75),

	std.AttributeSection "Activation",
	Activation = activation.useAttributes(),

	std.AttributeSection "Dismount",
	KeepMomentum = std.Attribute("KeepMomentum", std.gt.boolean(), true),
	JumpOnDismount = std.Attribute("JumpOnDismount", std.gt.boolean(), true),
	Dismount = activation.useAttributes "Dismount",
}

export type SwingMechanic = std.Mechanic<typeof(Swing)>

function Swing.onActivate(
	self: typeof(Swing),
	swing: SwingMechanic,
	level: std.Level,
	event: activation.ActivationEvent
)
	const activator = event.kind == "Touch" and event.toucher or character.getHumanoidRootPart()
	const toucher = activator and character.isFromCharacter(activator) and character.getHumanoidRootPart() or activator
	if not toucher or mounts.isMechanicMounted(toucher, swing) then return end

	const activationLife = swing.life:extend()
	activationLife:destroyOn(mounts.mountMechanic(toucher, swing))
end

return Swing

-- local Players = game:GetService("Players")
-- local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- local Workspace = game:GetService("Workspace")

-- local _T = require(ReplicatedStorage.Framework.ClientTypes)
-- local camera = Workspace.CurrentCamera

-- local UPDATE_INTERVAL = 1 / 60

-- local Swing = {
--     CanQueue = true,
--     RunOnStart = false,
-- }

-- local CONTROL_CONFIG_TEMPLATE = {
--     CanControl = false,
--     Force = 750,
--     MaxVelocity = 75,
-- }

-- local SequencerSupport = require(script.SequencerSupport)
-- local function handleCache(rootScope: _T.Scope, utility: _T.Utility)
--     local cache = {} :: { [Instance]: () -> () }
--     SequencerSupport(rootScope, utility, cache)
--     return cache
-- end

-- local player = Players.LocalPlayer
-- function Swing.Run(scope: _T.Scope, utility: _T.Utility)
--     local JumpButton = utility.JumpButton
--     local swingConfig = scope.instance
--     if not swingConfig or not swingConfig.Parent then
--         return
--     end

--     local playerModule = player.PlayerScripts:WaitForChild("PlayerModule")
--     local controls = require(playerModule.ControlModule)

--     if not scope.shared.mountedCOs then
--         scope.shared.mountedCOs = {}
--     end
--     local mountedCOs = scope.shared.mountedCOs :: { [BasePart]: { [Instance]: string } }

--     local Config = utility.Config
--     local configuration = Config.GetConfig(scope, swingConfig, SWING_CONFIG_TEMPLATE):ObserveChanges()
--     local controlConfiguration =
--         Config.GetConfig(scope, swingConfig:FindFirstChild("ControlConfiguration"), CONTROL_CONFIG_TEMPLATE)
--             :ObserveChanges()
--     local touchConfiguration =
--         Config.GetConfig(scope, swingConfig:FindFirstChild("TouchConfiguration"), Config.TOUCH_CONFIG):ObserveChanges()

--     local soundsFolder = swing:FindFirstChild("Sounds")
--         or (function()
--             local newSounds = Instance.new("Folder")
--             newSounds.Parent = swing
--             return newSounds
--         end)()

--     local dontDelete = swing:FindFirstChild("DontDelete")
--     if dontDelete then
--         dontDelete:Destroy()
--     else
--         scope:log({ swing.Name .. ' needs the "DontDelete" weld to avoid desyncing!', type = "warn" })
--         return
--     end

--     local rideDebounce = false
--     local handleCFrame = handle.CFrame
--     local difference = handle.CFrame:ToObjectSpace(top.CFrame):Inverse()

--     scope:attach(swing)

--     ----------------------------------------------------------------------------
--     --> Set up constraints
--     local constraint: Constraint = nil
--     local vectorForce = nil
--     local platform = platformTemplate:Clone()
--     local attachment0 = top:FindFirstChild("SwingAttachment") :: Attachment
--         or (function()
--             local newAtt = Instance.new("Attachment")
--             newAtt.Name = "SwingAttachment"
--             newAtt.Parent = top
--             return newAtt
--         end)()
--     local attachment1 = platform:FindFirstChild("Attachment1")
--     local platformWeld = platform:FindFirstChild("PlatformWeld")
--     if not (platformWeld and attachment1) then
--         scope:log({ `The {script.Name} script's constraint platform is not set up properly.`, type = "warn" })
--         return
--     end

--     if configuration.BallSocketMode then
--         constraint = Instance.new("BallSocketConstraint")
--     else
--         constraint = Instance.new("HingeConstraint")
--     end
--     constraint.Attachment0 = attachment0
--     constraint.Attachment1 = attachment1
--     constraint.Parent = top

--     platform.CFrame = top.CFrame
--     platformWeld.Part1 = handle
--     platform.Anchored = false
--     platform.Parent = swing

--     local anchorWeld = Instance.new("WeldConstraint")
--     anchorWeld.Part0 = top
--     anchorWeld.Part1 = handle
--     anchorWeld.Enabled = configuration.Anchor
--     anchorWeld.Parent = top
--     handle.Anchored = false

--     if controlConfiguration.CanControl then
--         local forceAttachment = Instance.new("Attachment")
--         forceAttachment.Name = "ForceAttachment"
--         forceAttachment.Parent = handle

--         vectorForce = Instance.new("VectorForce")
--         vectorForce.Attachment0 = forceAttachment
--         vectorForce.Force = Vector3.zero
--         vectorForce.RelativeTo = Enum.ActuatorRelativeTo.World
--         vectorForce.Parent = handle
--     end

--     ----------------------------------------------------------------------------
--     --> Mount swing
--     local rideScope = scope:inherit()
--     local function mount(attachedRoot: BasePart, isPlayer: boolean)
--         if handle:GetAttribute("Activated") == false or rideDebounce then
--             return
--         end

--         local humanoid = utility.Character.getHumanoid()

--         rideDebounce = true
--         if not mountedCOs[attachedRoot] then
--             mountedCOs[attachedRoot] = {}
--         end
--         mountedCOs[attachedRoot][swing] = "Swing"

--         utility.Functions.playSoundFromInstance(attachedRoot, soundsFolder, "Grab")

--         if configuration.Anchor then
--             anchorWeld.Enabled = false
--         end

--         if configuration.Boost == 0 then
--             handle.AssemblyLinearVelocity = attachedRoot.AssemblyLinearVelocity
--         else
--             handle.AssemblyLinearVelocity = handle.CFrame.LookVector * configuration.Boost
--         end

--         attachedRoot.AssemblyLinearVelocity = Vector3.zero
--         attachedRoot.CFrame = handle.CFrame - handle.CFrame.UpVector * (attachedRoot.Size.Y / 2)
--         if isPlayer and humanoid then
--             humanoid.PlatformStand = true
--             utility.Character.carryPart(true, handle, not configuration.HandleAnimation)
--         else
--             local handleWeld = Instance.new("WeldConstraint")
--             handleWeld.Part0 = handle
--             handleWeld.Part1 = attachedRoot
--             handleWeld.Parent = handle
--             rideScope:attach(handleWeld)
--         end

--         ----------------------------------------------------------------------------
--         --> Dismount function
--         local function dismountSwing()
--             rideScope:cleanup(true)

--             if attachedRoot then
--                 local momentum = if configuration.KeepMomentum then handle.AssemblyLinearVelocity * 2 else Vector3.zero
--                 attachedRoot.AssemblyLinearVelocity = momentum
--                 attachedRoot.CFrame = CFrame.new(attachedRoot.Position)
--                     * CFrame.Angles(0, math.rad(attachedRoot.Orientation.Y), 0)
--             end

--             if isPlayer and humanoid then
--                 utility.Character.carryPart(false, handle, not configuration.HandleAnimation)
--                 humanoid.PlatformStand = false
--                 if configuration.JumpOff then
--                     humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
--                     utility.Functions.playSoundFromInstance(attachedRoot, soundsFolder, "Jump")
--                 end
--             end

--             if controlConfiguration.CanControl then
--                 vectorForce.Force = Vector3.zero
--             end

--             if mountedCOs[attachedRoot] and mountedCOs[attachedRoot][swing] then
--                 mountedCOs[attachedRoot][swing] = nil
-- 				if utility.Table.IsEmpty(mountedCOs[attachedRoot]) then
--                     mountedCOs[attachedRoot] = nil
--                 end
--             end

--             task.delay(configuration.Cooldown, function()
--                 rideDebounce = false
--                 if configuration.Anchor then
--                     handle.CFrame = top.CFrame * difference
--                     anchorWeld.Enabled = true
--                     handle.AssemblyLinearVelocity = Vector3.zero
--                     handle.AssemblyAngularVelocity = Vector3.zero
--                     platform.AssemblyLinearVelocity = Vector3.zero
--                     platform.AssemblyAngularVelocity = Vector3.zero
--                 end
--             end)
--         end

--         if configuration.AllowJumpDismount then
--             rideScope:add(JumpButton.JumpEvent.Event:Connect(function(isPressed: boolean)
--                 if not isPressed then
--                     return
--                 end
--                 dismountSwing()
--             end))
--         end

--         ----------------------------------------------------------------------------
--         --> Swing control loop
--         rideScope:spawn(function()
--             while task.wait(UPDATE_INTERVAL) do
--                 debug.profilebegin("Swing Loop")
--                 if not attachedRoot or not attachedRoot.Parent then
--                     dismountSwing()
--                     break
--                 elseif not (mountedCOs[attachedRoot] and mountedCOs[attachedRoot][swing]) then
--                     dismountSwing()
--                     break
--                 end

--                 if isPlayer and humanoid and not humanoid.PlatformStand then
--                     -- fixes a weird bug where platformstand disables itself
--                     humanoid.PlatformStand = true
--                 end

--                 if controlConfiguration.CanControl and humanoid then
--                     local moveAmount = controls:GetMoveVector()
--                     local walkSpeed = humanoid.WalkSpeed
--                     local vector = camera.CFrame.LookVector
--                     local cframe = CFrame.new(Vector3.zero, Vector3.new(vector.X, 0, vector.Z))

--                     local force = controlConfiguration.Force
--                     local maxVelocity = controlConfiguration.MaxVelocity

--                     force = math.max(force - handle.AssemblyLinearVelocity.Magnitude * force / maxVelocity, 0)
--                     force *= walkSpeed / 16
--                     vectorForce.Force = (-cframe.LookVector * moveAmount.Z + cframe.RightVector * moveAmount.X) * force
--                 end
--                 debug.profileend()
--             end
--         end)
--     end

--     --> Activation
--     scope:add(handle.Touched:Connect(function(touch)
--         if not utility.ClientObjects.evaluateToucher(handle, touch, touchConfiguration) then
--             return
--         end

--         local characterInstances = utility.Character.getCharacter()
--         local character = characterInstances.character
--         local humanoid = characterInstances.humanoid
--         local rootPart = characterInstances.rootPart
--         if not rootPart then
--             return
--         end

--         local isPlayer = table.find(utility.Character.getHitbox("StaticWholeBody"), touch) ~= nil
--         local isBox = utility.ClientObjects.isPushbox(touch, true)
--         if not (isPlayer or isBox) then
--             return
--         end

--         local attachedRoot = if isPlayer then rootPart else touch
--         mount(attachedRoot, isPlayer)
--     end))

--     if touchConfiguration.canFlip then
--         handle:AddTag("DoNotFlipPlayer")
--         scope:add(utility.ClientObjects.bindToFlip(handle, function(rootPart)
--             mount(rootPart, true)
--         end))
--     end

--     --> Sequencer Cache Support
--     local cache = utility.Scope.getCached(scope, scope.scriptPath, handleCache)
--     cache[swing] = function()
--         local rootPart = utility.Character.getCharacter().rootPart
--         if not rootPart then
--             return
--         end
--         mount(rootPart, true)
--     end
--     scope:add(function()
--         cache[swing] = nil
--         cache = nil :: any
--     end)
-- end

-- return Swing
