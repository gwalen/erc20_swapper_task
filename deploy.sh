source .env

# echo $ETHERSCAN_API_KEY

# forge script script/MainDeployer.s.sol:MainDeployer $script_name --fork-url $SEPOLIA_RPC_URL  --private-key $DEPLOYER_PRIVATE_KEY --etherscan-api-key=$ETHERSCAN_API_KEY --broadcast --verify
forge script script/MainDeployer.s.sol:MainDeployer $script_name --fork-url $SEPOLIA_RPC_URL  --private-key $DEPLOYER_PRIVATE_KEY --etherscan-api-key=$ETHERSCAN_API_KEY --broadcast --verify --resume