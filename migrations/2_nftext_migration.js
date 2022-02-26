// Help Truffle find `NFTText.sol` in the `/contracts` directory
const NFTText = artifacts.require("NFTText");

module.exports = function(deployer) {
  // Command Truffle to deploy the Smart Contract
  deployer.deploy(NFTText);
};