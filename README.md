## KipuBankV3 – Proyecto Final del Módulo 4

KipuBankV3 es la evolución del proyecto **KipuBankV2**, incorporando funcionalidades DeFi mediante la integración con **Uniswap V2**.  
Esta versión permite depósitos con múltiples tokens, realiza swaps automáticos a USDC y mantiene la lógica central del banco, incluyendo el límite máximo (*bankCap*).

---

## ✨ Mejoras Implementadas

- **Soporte para múltiples tokens ERC-20:**  
  Los usuarios pueden depositar cualquier token disponible en Uniswap V2, no solo ETH o USDC.

- **Swaps automáticos a USDC:**  
  Los tokens depositados se convierten dentro del smart contract mediante el router de Uniswap V2, unificando el balance en USDC.

- **Preservación de la lógica de KipuBankV2:**  
  Se mantienen los depósitos, retiros y reglas de ownership.

- **Control del `bankCap`:**  
  El valor total en USDC no puede superar el límite establecido, incluso luego del swap. Si se excede, la transacción revierte.

---

## 🚀 Despliegue

**Remix**

1) Abrir https://remix.ethereum.org
2) Crear carpeta /contracts y pegar los archivos: KipuBankV3.sol, MockUSDC.sol, MockToken.sol, MockUniswapV2Router.sol.
3) Compiler -> Solidity 0.8.17 -> enable optimizer (runs 200) -> Compile all.
4) Conectar MetaMask en Sepolia.
5) Desplegar mocks::
   - Deploy MockUSDC args: "USDC","USDC",6
   - Deploy MockUniswapV2Router args: (mockUSDCAddress, 0x0000000000000000000000000000000000000000)
   - Mint USDC to router: MockUSDC.mint(routerAddress, 1000000 * 10**6)
6) Deploy KipuBankV3 args:
   - _router = router address
   - _usdc = mockUSDC address
   - _bankCap = 1000000 * 10**6 => 1000000000000
7) Probar flow:
   - Deploy MockToekn args: "TOK", "TOK", 6 
   - Mint MockToken to user and approve KipuBankV3
   - Call depositERC20(token, amount, minOut=0, deadline=unix+3600)
   - Call depositETH with value and minOut=0 (if router funded)
8) Verificar:
   - KipuBankV3.balanceOf(user), totalUSDC, contract USDC balance
