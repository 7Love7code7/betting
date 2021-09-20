const BettingNFT = artifacts.require("BettingNFT");
require('dotenv').config();

module.exports = function (deployer) {
  deployer.deploy(BettingNFT);
};
