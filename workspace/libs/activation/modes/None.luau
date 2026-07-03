local types = require "../types"

local None = {} :: types.ActivationMode

function None.implement(_: types.ActivationContext) end

return None
