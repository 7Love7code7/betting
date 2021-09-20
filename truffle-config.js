require("dotenv").config();
const HDWalletProvider = require("truffle-hdwallet-provider");
const web3 = require("web3");
module.exports = {
  /**
   * Networks define how you connect to your ethereum client and let you set the
   * defaults web3 uses to send transactions. If you don't specify one truffle
   * will spin up a development blockchain for you on port 9545 when you
   * run `develop` or `test`. You can ask a truffle command to use a specific
   * network from the command line, e.g
   *
   * $ truffle test --network <network-name>
   */
  networks: {
    ganache: {
      host: "127.0.0.1",
      port: 8545,
      network_id: "5777", // match any network id
      from: process.env.FROM, // account address from which to deploy
      gas: 6721975,
    },
    main: {
      provider: function () {
        return new HDWalletProvider(
          process.env.PRIVATEKEY,
          process.env.MAINNET,
          0
        );
      },
      network_id: 1,
      gas: 4500000,
      gasPrice: 100000000000,
      timeoutBlocks: 200, // # of blocks before a deployment times out (minimum/default: 50)
      skipDryRun: true,
    },
    rinkeby: {
      provider() {
        return new HDWalletProvider(
          process.env.PRIVATEKEY,
          process.env.RINKEBY,
          0
        );
      },
      networkCheckTimeout: 100000,
      network_id: 4,
      gasPrice: 2000000000,
      gas: 4712388,
    },
  },
  plugins: ["truffle-plugin-verify"],
  api_keys: {
    etherscan: process.env.ETHERSCAN_API_KEY,
  },
  // Set default mocha options here, use special reporters etc.
  mocha: {
    timeout: 300000,
  },

  // Configure your compilers
  compilers: {
    solc: {
      version: "^0.6.0", // Fetch exact version from solc-bin (default: truffle's version)
      settings: {
        // See the solidity docs for advice about optimization and evmVersion
        optimizer: {
          enabled: true,
          runs: 200,
        },
      },
    },
  },
};
