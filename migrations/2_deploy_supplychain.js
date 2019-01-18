var SupplyChain = artifacts.require("./SupplyChain.sol");

module.exports = function(deployer,n,a) {
  console.log(a);
  deployer.deploy(SupplyChain);
};
