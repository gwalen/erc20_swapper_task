# Home assignment

## How to test

Tests are written using Forge. To run them, please execute the following command with your RPC URL for the Ethereum mainnet:
```
forge test --fork-url <rpc_url> -vv

eg.:
forge test --fork-url https://mainnet.infura.io/v3/<your_infura_key> -vv
```

## How to deploy

First you need to setup `.env` variables:
```
RPC_URL=
UNI_V3_ROUTER=
WETH_ADDRESS=
ETHERSCAN_API_KEY=
OWNER_ADDRESS=
KEEPER_ADDRESS=
DEPLOYER_PRIVATE_KEY=
```

To deploy run `deploy.sh` script. It will use Forge scripts to deploy Timelock and Swapper(with proxy) contracts with initialization and verification with Etherscan.

## Deployed contracts:

Addresses of contracts deployed to Sepolia test-net:
```
| Contract Name          | Contract Address                                 |
|------------------------|--------------------------------------------------|
| ERC1967Proxy.sol       | 0x352e2a9a0914365098646bcE2974D40cA1fD1F19       |
| Swapper.sol            | 0xEC75D289c33A6532bb92993E4464bBdB5C1b148A       |
| TimelockController.sol | 0x2DD0dBAc9fd4ED02cDB06Eb2Ecc70A16216E5847       |
```

Interaction with contract happens through proxy contract `0x352e2a9a0914365098646bcE2974D40cA1fD1F19`

Contract have been **verified** with forge during deployment and **proxy was linked** to implementation using etherscan.
You can check it here:
- verified & linked proxy: https://sepolia.etherscan.io/address/0x352e2a9a0914365098646bce2974d40ca1fd1f19
- example transaction on Sepolia testnet : https://sepolia.etherscan.io/tx/0xb7fa621b18c056df85e0c81085243c84e1e777482c6b46bee79da81becd765c0

## Design discussion

For testing purpose integration with Uniswap V3 was implemented using [IV3SwapRouter](https://github.com/Uniswap/swap-router-contracts/blob/main/contracts/interfaces/IV3SwapRouter.sol).

Here is a short description of how each of the evaluation points was met by this solution:

#### 1. Safety and trust minimization. Are the user's assets kept safe during the exchange transaction? Is the exchange rate fair and correct? Does the contract have an owner?

* Are the user's assets kept safe during the exchange transaction?

Assets are safe during the whole transaction (including the exchange interaction with an external exchange) thanks to a check after the call to the external swap that 
ensures the correct amount of output tokens is returned (in `Swapper.sol`):
```markdown
uint tokenBalanceBefore = IERC20(token).balanceOf(msg.sender);
swapWithDex(token, msg.sender, msg.value);
uint tokenBalanceDiff = IERC20(token).balanceOf(msg.sender) - tokenBalanceBefore;

if (tokenBalanceDiff < minAmount) {
    revert AmountOutTooSmall();
}
```
If there is an error, the transaction reverts and the user's assets are untouched.

In this case, there is no danger of a reentrancy attack, but if the contract were to grow with new functionalities, 
it could become necessary to add special checks. Reentrancy guards could be added using the ReentrancyGuard impl from the OpenZeppelin libraries.

* Is the exchange rate fair and correct?

The parameter `minAmount` of the `swapEtherToToken` function ensures fairness. This parameter is set by the user and includes the maximum slippage
the user can handle. If the exchange were to return a smaller amount than expected, the method would revert.

* Does the contract have an owner?

In this case, the contract has an owner, which could be considered a potential security issue because the contract owner could update the implementation
and, for example, send funds to themselves. To prevent this, a Timelock was added as the contract owner with a 48-hour timelock period before the proxy can be updated.
This should give users enough time to notice and stop using it.

To make the contract even more secure, the Timelock executor could be set to a Multisig, e.g., 3/5 to prevent just one EOA from being able to perform an update.

Another option could be to add an intermediary contract that is not upgradable and which only calls `Swapper.swapEtherToToken` and performs the output token balance check.
Then, a timelock would not be needed as the primary security issue—when the contract is not making correct swaps—would be guarded by an immutable contract serving as a facade.
This would add another layer of indirection and with extra gas cost, but would offer additional security measures.

#### 2. Performance

* How much gas will the `swapEtherToToken` execution and the deployment take?

Deployment incurs an extra cost from deploying the Timelock contract and the proxy in addition to the Swapper contract itself. These contracts are lightweight and should 
not introduce a substantial cost increase.

The execution cost is mainly from wrapping Ether into WETH and the cost of the external call to the DEX.

#### 3. Upgradeability

* How can the contract be updated if, for example, the DEX it uses has a critical vulnerability and/or the liquidity gets drained?

The Swapper smart contract implements the UUPS pattern. The owner (Timelock) can update the implementation if necessary.
Additionally, the Keeper role of Swapper can pause the contract if there is a major bug and trading must stop immediately.

#### 4. Usability and interoperability. Are other contracts able to interoperate with it?

* Is the contract usable for EOAs?

Yes, the contract is usable for EOAs, either manually using Etherscan or with any client (using for example ethers-js).

* Are other contracts able to interoperate with it?

Yes, other contracts can use it. There are no obstacles to doing so.

#### 5. Readability and code quality. Are the code and design understandable and error-tolerant? Is the contract easily testable?

* Are the code and design understandable and error-tolerant?

I have done my best to ensure they are understandable and error-tolerant by adding comments and utilizing OpenZeppelin libraries, which are widely used and audited.

* Is the contract easily testable?

To ensure testability, I have provided a simple test suite written in Forge.