# Home assignment

## How to test

Test are written using forge. To run please execute this command with your rpc url 
```
forge test --fork-url <rpc url> -vv

eg.:
forge test --fork-url https://mainnet.infura.io/v3/<your infura id here> -vv
```

## How to deploy

First you need to setup .env variables 
```
RPC_URL=
UNI_V3_ROUTER=
WETH_ADDRESS=
ETHERSCAN_API_KEY=
OWNER_ADDRESS=
KEEPER_ADDRESS=
DEPLOYER_PRIVATE_KEY=
```

To deploy run `deploy.sh` script. It will use Forge scripts to deploy Timelock and Swapper(with proxy) contracts and perform initialization.

## Deployed contracts:

Addresses of contracts deployed to Sepolia test-net:
```
| Contract Name          | Contract Address                                 |
|------------------------|--------------------------------------------------|
| ERC1967Proxy.sol       | 0xCedaDE86709930cF36608F5daeE2E7cc4A690b06       |
| Swapper.sol            | 0x724D48e4D0213A66A534A1BB808CF013714e554a       |
| TimelockController.sol | 0xaC706B78F925F3249960681b95dB50198a6Bc1cE       |
```

Interaction with contract happens through proxy contract `0xCedaDE86709930cF36608F5daeE2E7cc4A690b06`

Contract have been **verified** with forge during deployment and **proxy was linked** to implementation using etherscan.
You can check it here:
- https://sepolia.etherscan.io/address/0xcedade86709930cf36608f5daee2e7cc4a690b06#code

## Design discussion

Here is a short description how each of evaluation points was met but this solution:

#### 1. Safety and trust minimization. Are user's assets kept safe during the exchange transaction? Is the exchange rate fair and correct? Does the contract have an owner?

* Are user's assets kept safe during the exchange transaction?

Assets are safe during the whole transaction (including exchange interaction with external exchange) thanks to check after the call to external swap that 
ensures if correct amount of output tokens is returned (in `Swapper.sol`):
```
uint tokenBalanceBefore = IERC20(token).balanceOf(msg.sender);
swapWithDex(token, msg.sender, msg.value);
uint tokenBalanceDiff = IERC20(token).balanceOf(msg.sender) - tokenBalanceBefore;

if (tokenBalanceDiff < minAmount) {
    revert AmountOutTooSmall();
}
```
If there is any error transaction reverts and user assets are untouched.

In this case there is not danger of reentrancy attack but if contract would grow with new functionalities 
it could be necessary to add special checks. Reentracy guards could be added using ReentrancyGuard impl from OpenZeppelin libs.

* Is the exchange rate fair and correct?

Parameter `minAmount` of `swapEtherToToken` function makes sure of that. This parameter is set by user and includes max slippage
user can handle. If exchange would return smaller amount than expected the method will revert.

* Does the contract have an owner?

In this case contract has an owner which could be considered as potential security issue because contract owner could update the impl
and for example send funds to himself. To prevent it Timelock was added as the contract owner with 48h timelock period before the proxy can be updated.
This should give users enough time to notice and stop using it.

To make contract even more secure the Timelock executor could be set to Multisig eg.: 3/5 so prevent just one EOA from being able to perform update.

Another option could be to add intermediary contract that is not upgradable and which only calls `Swapper.swapEtherToToken` and performs the output token balance check.
Than timelock would not be needed as primary security issue when contract is not making correct swaps would be guarded by immutable contract serving as a facade.
This would add another layer of indirection and with extra gas cost but additional security measures.

#### 2. Performance. 

* How much gas will the swapEtherToToken execution and the deployment take?

Deployment has extra cost of deploying timelock contract and proxy in addition to Swapper contract. Those contracts are light and should 
not introduce substantial cost increase.

Execution cost is mainly the wrapping of ether into WETH and cost of external call to dex.

#### 3. Upgradeability. 

* How can the contract be updated if e.g. the DEX it uses has a critical vulnerability and/or the liquidity gets drained?

Swapper smart contract implement UUPSProxy pattern. Owner (timelock) can update the implementation if needed.
Keeper role of Swapper can additional pause the contract if there is major bug and trading must stop immediately.

#### 4. Usability and interoperability.  Are other contracts able to interoperate with it?

* Is the contract usable for EOAs?

Yes contract is usable for EOAs either manually using etherscan or with UI written in for eg.: typescript.

* Are other contracts able to interoperate with it?

Yes other contracts can use it. There are not there are no obstacles do it.

#### 5. Readability and code quality. Are the code and design understandable and error-tolerant? Is the contract easily testable?

* Are the code and design understandable and error-tolerant?

I did my best to make in understandable and error-tolerant adding comments and using OpenZeppelin libraries which are widely used and audited.

* Is the contract easily testable?

To make sure of it I have provided a simple test suite written in forge.
