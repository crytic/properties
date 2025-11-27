const urlOverride = process.env.ETH_PROVIDER_URL;
const chainId = parseInt(process.env.CHAIN_ID ?? "31337", 10);

export default {
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
            runs: 200,
          },
        },
      },
      {
        version: "0.8.17",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
    ],
  },
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {
      type: "edr-simulated",
      chainId,
      loggingEnabled: false,
    },
    localhost: {
      chainId,
      url: urlOverride || "http://localhost:8545",
    },
  },
};
