const ERC1155Token = artifacts.require("ERC1155Token");

module.exports = function (deployer) {
  deployer.deploy(ERC1155Token);
};
