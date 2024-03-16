source .env

forge script script/MainDeployer.s.sol:MainDeployer $script_name --fork-url $RPC_URL  --private-key $DEPLOYER_PRIVATE_KEY --etherscan-api-key=$ETHERSCAN_API_KEY --broadcast --verify
# forge script script/MainDeployer.s.sol:MainDeployer $script_name --fork-url $RPC_URL  --private-key $DEPLOYER_PRIVATE_KEY --etherscan-api-key=$ETHERSCAN_API_KEY --broadcast --verify --resume    