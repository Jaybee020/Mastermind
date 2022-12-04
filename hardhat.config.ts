/** @type import('hardhat/config').HardhatUserConfig */
require("@nomiclabs/hardhat-waffle");
module.exports = {
  solidity: "0.8.17",
};

const PRIVATE_KEY = String(process.env.PRIVATE_KEY);

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: "0.8.0",
  networks: {
    hardhat: {
      chainId: 1337,
    },
    // mainnet: {
    //   url: "", //url link for mainnet
    //   accounts: [PRIVATE_KEY],
    // },
    mumbai: {
      url: `https://rpc-mumbai.maticvigil.com/`, //link for rpcUrl of devnet
      accounts: [
        ``, //input your private key
      ],
    },
  },
};
