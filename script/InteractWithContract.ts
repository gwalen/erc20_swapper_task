import { BigNumber, ethers } from 'ethers';

// Define the manual ABI inline for the function signatures you're interested in
const contractABI = [
  "function admin() view returns (address)",
  "function counterValue() view returns (uint256)",
  "function increment() public",
  "function addUserToWhitelist(address) public",
  "function removeUserFromWhiteList(address) public",
];

// Define the contract address
const contractAddress = '0x4278C5d322aB92F1D876Dd7Bd9b44d1748b88af2';

// Define the network you want to connect to (e.g., Mainnet, Ropsten, a local Ethereum node, etc.)
const provider = new ethers.providers.JsonRpcProvider('http://127.0.0.1:8545');

// contract deployer: 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 : 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
// Private key (replace with your private key, keep it secure!)
const aliceTestPrivateKey = '0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80';
const bobTestPrivateKey = '0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d'
// const bobAddress = '0x70997970C51812dc3A010C7d01b50e0d17dc79C8';

// Create a wallet instance from a private key
const aliceWallet = new ethers.Wallet(aliceTestPrivateKey, provider);
const bobWallet = new ethers.Wallet(bobTestPrivateKey, provider);

// The contract instance with signer (wallet)
const contractAliceSigner = new ethers.Contract(contractAddress, contractABI, aliceWallet);
const contractBobSigner = new ethers.Contract(contractAddress, contractABI, bobWallet);

async function makeTransaction() {
    try {
      const admin = await contractAliceSigner.admin();
      console.log("admin: ", admin);

      const tx = await contractAliceSigner.addUserToWhitelist(bobWallet.address);
      console.log("Bob address:", bobWallet.address);
      const receipt = await tx.wait(); // Wait for the transaction to be mined
      console.log('Transaction addUserToWhiteList successful with hash:', receipt.transactionHash);

      const incTx = await contractBobSigner.increment();
      const incReceipt = await incTx.wait(); // Wait for the transaction to be mined
      console.log('Transaction increment successful with hash:', receipt.transactionHash);

      const counterValue: BigNumber = await contractAliceSigner.counterValue();
      console.log("counter value: ", counterValue.toNumber());

    } catch (error) {
      console.error('Transaction failed:', error);
    }
  }
  
  // Make the contract interaction
  makeTransaction();