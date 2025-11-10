//router mock (getAmountsOut 1:1, swaps)

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IERC20Minimal {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract MockUniswapV2Router {
    address public immutable USDC;
    address public immutable WETH_ADDR;

    constructor(address _usdc, address _weth) {
        USDC = _usdc;
        WETH_ADDR = _weth;
    }

    // naive pricing: returns [amountIn, amountIn]
    function getAmountsOut(uint amountIn, address[] calldata path) external pure returns (uint[] memory amounts) {
        amounts = new uint[](2);
        amounts[0] = amountIn;
        amounts[1] = amountIn;
    }

    // token -> token swap: pulls tokenIn from caller and pushes tokenOut (must be funded)
    function swapExactTokensForTokens(
        uint amountIn,
        uint /* amountOutMin */,
        address[] calldata path,
        address to,
        uint /* deadline */
    ) external returns (uint[] memory amounts) {
        address tokenIn = path[0];
        address tokenOut = path[path.length - 1];

        require(IERC20Minimal(tokenIn).transferFrom(msg.sender, address(this), amountIn), "transferFrom failed");
        require(IERC20Minimal(tokenOut).transfer(to, amountIn), "transfer to recipient failed");

        amounts = new uint[](2);
        amounts[0] = amountIn;
        amounts[1] = amountIn;
    }

    // ETH -> token: accept ETH and send tokenOut from router balance
    receive() external payable {}

    function swapExactETHForTokens(
        uint /* amountOutMin */,
        address[] calldata path,
        address to,
        uint /* deadline */
    ) external payable returns (uint[] memory amounts) {
        uint amountIn = msg.value;
        address tokenOut = path[path.length - 1];
        require(IERC20Minimal(tokenOut).transfer(to, amountIn), "router transfer failed");

        amounts = new uint[](2);
        amounts[0] = amountIn;
        amounts[1] = amountIn;
    }

    function WETH() external view returns (address) {
        return WETH_ADDR;
    }
}