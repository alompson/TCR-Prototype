# Consistent Debate System (CDS)

## Overview
The Consistent Debate System (CDS) is a blockchain-based platform designed to decentralize the code review process in software development. Leveraging the Ethereum blockchain, the DCRS introduces a Token Curated Registry (TCR) model to ensure transparent and unbiased code reviews. This system shifts the responsibility from a central maintainer to a distributed network of reviewers.

## Features
- **Smart Contract-based System**: Utilizes Ethereum smart contracts for decentralized decision-making.
- **Token Curated Registry**: Incentivizes honest reviews and participation through a token-based system.
- **Decentralized Voting**: Allows for a transparent and democratic code review process.
- **Complexity Metrics**: Uses Cyclomatic Complexity and Halstead Difficulty to determine review time spans.

## Requirements
- A modern web browser with JavaScript enabled.
- MetaMask extension installed for interacting with Ethereum blockchain.
- Some Ether in your MetaMask wallet for transaction fees (if deploying or interacting with the contract on the mainnet or testnet).

## Using Remix for Testing
1. **Open Remix**: Visit [Remix IDE](https://remix.ethereum.org/) in your web browser.
2. **Create a New File**: In the File Explorer tab, create a new file named `TCR.sol`.
3. **Paste the Smart Contract**: Copy the content of the `TCR.sol` smart contract and paste it into the newly created file in Remix.
4. **Compile the Contract**: Go to the Solidity Compiler tab and compile the `TCR.sol` smart contract.
5. **Deploy the Contract**: 
   - Switch to the Deploy & Run Transactions tab.
   - Ensure that your environment is set to `Injected Web3` to use MetaMask.
   - Click on the `Deploy` button to deploy the smart contract to the selected Ethereum network.

## Interacting with the Smart Contract
- **Assign to Group**: Assign yourself to a group to participate in the review process.
- **Vote**: Cast your votes on the code submissions in each round.
- **Create Objections and Rebuttals**: Raise objections and rebuttals during the review process.
- **Reclaim Tokens**: Reclaim tokens as rewards based on your contributions and voting outcomes.

## Contributing
We welcome contributions to the DCRS project. To contribute:
1. Fork the repository.
2. Create a new feature branch (`git checkout -b feature/YourFeature`).
3. Commit your changes (`git commit -am 'Add YourFeature'`).
4. Push to the branch (`git push origin feature/YourFeature`).
5. Create a new Pull Request.

## License
This project is licensed under the GPL-3.0 License - see the [LICENSE](LICENSE) file for details.

---

**Note**: This README is a template and should be adjusted to fit the specifics of your project.
