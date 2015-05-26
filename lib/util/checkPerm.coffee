module.exports = (mode, mask) ->
    if mask in [256, 128, 64]
        mask >>= 6
        !!(mask & parseInt(mode & parseInt('777', 8), 10).toString(8)[0])
    else if mask in [32, 16, 8]
        mask >>= 3
        !!(mask & parseInt(mode & parseInt('777', 8), 10).toString(8)[1])
    else if mask in [4, 2, 1]
        mask >>= 0
        !!(mask & parseInt(mode & parseInt('777', 8), 10).toString(8)[2])
    else
        throw new Error "invalid mask: #{mask}"

module.exports.U_RD = 256
module.exports.U_WR = 128
module.exports.U_EX = 64
module.exports.G_RD = 32
module.exports.G_WR = 16
module.exports.G_EX = 8
module.exports.W_RD = 4
module.exports.W_WR = 2
module.exports.W_EX = 1
