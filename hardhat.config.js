require("@nomicfoundation/hardhat-ethers");
require("@openzeppelin/hardhat-upgrades");
const dotenv = require("dotenv");
dotenv.config();
function getRemappings() {
  return fs
      .readFileSync("remappings.txt", "utf8")
      .split("\n")
      .filter(Boolean)
      .map((line) => line.trim().split("="));
}

module.exports = {
  solidity: {
    version: "0.8.24",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  paths: {
    sources: "./src/", 
    artifacts: "./artifacts",
    cache: "./cache",
  },
  networks: {
    sepolia: {
      live: false,
      saveDeployments: false,
      tags: ["local", "test"],
      url: "https://sepolia.infura.io/v3/9aa3d95b3bc440fa88ea12eaa4456161",
      chainId: 11155111,
      accounts: [process.env.PRIVATE_KEY || ""],
    }
  },
  preprocess: {
    eachLine: (hre) => ({
      transform: (line) => {
        if (line.match(/^\s*import /i)) {
          getRemappings().forEach(([find, replace]) => {
            if (line.match(find)) {
              line = line.replace(find, replace);
            }
          });
        }
        return line;
      },
    }),
  },
};