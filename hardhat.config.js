const urlOverride = process.env.ETH_PROVIDER_URL;
const chainId = parseInt(process.env.CHAIN_ID ?? "31337", 10);

module.exports = {
  paths: {
    artifacts: "./artifacts",
    sources: "./contracts",
    tests: "./tests",
  },
  solidity: {
    compilers: [
      {
        version: "0.8.1",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200
          }
        }
      },
      {
        version: "0.8.17",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200
          }
        }
      },

    ],
  },
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {
      chainId,
      loggingEnabled: false,
      saveDeployments: false,
    },
    localhost: {
      chainId,
      url: urlOverride || "http://localhost:8545",
    },
  },
};
