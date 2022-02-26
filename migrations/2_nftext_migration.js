// Help Truffle find `NFText.sol` in the `/contracts` directory
const NFText = artifacts.require("NFText");

module.exports = function(deployer) {
  // Command Truffle to deploy the Smart Contract
  deployer.deploy(NFText);
};