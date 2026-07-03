local RunService = game:GetService "RunService"

-- gng cooking up straight POISON
return (
	if RunService:IsClient()
		then (require)(game:GetService("Players").LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild "PlayerModule")
		else {}
) :: typeof((function()
	return require "@playermodule"
end)())
