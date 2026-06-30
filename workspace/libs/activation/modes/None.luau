const types = require "../types"

const None = {} :: types.ActivationMode

function None.implement(_: types.ActivationContext) end

return None
