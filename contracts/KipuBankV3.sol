//contrato principal (depósitos, swaps a USDC, bankCap)

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/v4.8.0/contracts/token/ERC20/IERC20.sol";
import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/v4.8.0/contracts/token/ERC20/utils/SafeERC20.sol";
import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/v4.8.0/contracts/security/ReentrancyGuard.sol";
import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/v4.8.0/contracts/access/Ownable.sol";

interface IUniswapV2Router02 {
    function WETH() external view returns (address);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);
}

contract KipuBankV3 is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IUniswapV2Router02 public router;
    address public USDC; // USDC token address (6 decimals in mocks)
    uint256 public bankCap; // expressed in USDC smallest units
    uint256 public totalUSDC;
    mapping(address => uint256) public balances;

    event Deposit(address indexed user, address indexed token, uint256 amountIn, uint256 usdcReceived);
    event WithdrawUSDC(address indexed to, uint256 amount);

    constructor(address _router, address _usdc, uint256 _bankCap) {
        require(_router != address(0) && _usdc != address(0), "zero addr");
        router = IUniswapV2Router02(_router);
        USDC = _usdc;
        bankCap = _bankCap;
    }

    // deposit ERC20 token; if token != USDC, swap to USDC via router
    function depositERC20(address token, uint256 amountIn, uint256 minOut, uint256 deadline) external nonReentrant {
        require(amountIn > 0, "amount 0");
        IERC20(token).safeTransferFrom(msg.sender, address(this), amountIn);

        if (token == USDC) {
            require(totalUSDC + amountIn <= bankCap, "bank cap exceeded");
            totalUSDC += amountIn;
            balances[msg.sender] += amountIn;
            emit Deposit(msg.sender, token, amountIn, amountIn);
            return;
        }

        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = USDC;

        uint[] memory amountsOut = router.getAmountsOut(amountIn, path);
        uint estimatedUSDC = amountsOut[amountsOut.length - 1];
        require(totalUSDC + estimatedUSDC <= bankCap, "bank cap after swap");

        // approve router the needed amount
        IERC20(token).safeApprove(address(router), 0);
        IERC20(token).safeApprove(address(router), amountIn);

        uint[] memory amounts = router.swapExactTokensForTokens(amountIn, minOut, path, address(this), deadline);
        uint got = amounts[amounts.length - 1];

        totalUSDC += got;
        balances[msg.sender] += got;
        emit Deposit(msg.sender, token, amountIn, got);
    }

    // deposit native ETH -> swap to USDC through WETH -> USDC path
    function depositETH(uint256 minOut, uint256 deadline) external payable nonReentrant {
        require(msg.value > 0, "no eth");
        address weth = router.WETH();
        address[] memory path = new address[](2);
        path[0] = weth;
        path[1] = USDC;

        uint[] memory amountsOut = router.getAmountsOut(msg.value, path);
        uint estimatedUSDC = amountsOut[amountsOut.length - 1];
        require(totalUSDC + estimatedUSDC <= bankCap, "bank cap after swap");

        uint[] memory amounts = router.swapExactETHForTokens{value: msg.value}(minOut, path, address(this), deadline);
        uint got = amounts[amounts.length - 1];

        totalUSDC += got;
        balances[msg.sender] += got;
        emit Deposit(msg.sender, address(0), msg.value, got);
    }

    // owner withdraw USDC from contract (example)
    function withdrawUSDC(address to, uint256 amount) external onlyOwner {
        require(amount <= totalUSDC, "amount > stored");
        IERC20(USDC).safeTransfer(to, amount);
        totalUSDC -= amount;
        emit WithdrawUSDC(to, amount);
    }

    // helper view
    function balanceOf(address user) external view returns (uint256) {
        return balances[user];
    }
}