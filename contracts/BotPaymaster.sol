// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";

// TODO: Optimize for gas 

// Partner deploys this contract to manage funds of the their bots.
contract BotPayMaster is Ownable {

    struct BotTransaction {
        uint256 lastNonce;
        uint256 lastAmount;
    }

    mapping(address => mapping(address => BotTransaction)) private botTransactionsStore;

    mapping(address => bool) public approvedBots;

    // Events
    event BotApproved(address indexed bot);
    event BotRevoked(address indexed bot);
    event ChequeCashed(address indexed from, address indexed to, uint256 amount, uint256 nonce);

    function approveBot(address bot) public onlyOwner {
        approvedBots[bot] = true;
        emit BotApproved(bot);
    }

    function revokeBot(address bot) public onlyOwner {
        approvedBots[bot] = false;
        emit BotRevoked(bot);
    }

    function isBotApproved(address bot) public view returns (bool) {
        return approvedBots[bot];
    }

    function getChequeHash(address from, address to, uint256 amount, uint256 nonce) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(from, to, amount, nonce));
    }

    function recoverSigner(bytes32 chequeHash, bytes memory signature) public pure returns (address) {
        // Cheque the signature's length
        require(signature.length == 65, "Invalid signature length");

        bytes32 r;
        bytes32 s;
        uint8 v;

        // Split the signature into r, s, and v
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }

        // Adjust the v value if necessary
        if (v < 27) {
            v += 27;
        }

        // Ensure the signature is valid
        require(v == 27 || v == 28, "Invalid signature 'v' value");

        // Recover the signer address
        return ecrecover(chequeHash, v, r, s);
    }

    function cashCheque(
        address from, 
        address to, 
        uint256 amount, 
        uint256 nonce, 
        bytes memory signature
    ) public {
        require(approvedBots[from], "Bot not approved");
        require(to != address(0), "Invalid recipient address");

        BotTransaction memory botTx = botTransactionsStore[from][to];
        
        require(nonce > botTx.lastNonce, "Nonce too low");
        require(amount > botTx.lastAmount, "Amount not greater than last known amount");

        bytes32 chequeHash = getChequeHash(from, to, amount, nonce);

        // Cheque if the signature matches the from address. This proves that the
        // bot has created a signature with the correct from, to, amount, and nonce.
        // Which in our context is a valid cheque.
        require(recoverSigner(chequeHash, signature) == from, "Invalid signature");

        // Calculate the amount to transfer
        uint256 previousAmount = botTx.lastAmount;
        uint256 transferAmount = amount - previousAmount;

        // Update the stored values in the struct
        botTransactionsStore[from][to] = BotTransaction(nonce, amount);

        // Transfer the funds to the "to" address
        payable(to).transfer(transferAmount);

        emit ChequeCashed(from, to, amount, nonce);
    }

    function isChequeValid(
        address from,
        address to,
        uint256 amount,
        uint256 nonce,
        bytes memory signature
    ) public view returns (bool) {
        // Check if the bot is approved
        if (!approvedBots[from]) {
            return false;
        }

        // Check if the recipient address is valid
        if (to == address(0)) {
            return false;
        }

        // Retrieve the last transaction for this bot and recipient
        BotTransaction memory botTx = botTransactionsStore[from][to];

        // Check if the nonce is valid (greater than the last used nonce)
        if (nonce <= botTx.lastNonce) {
            return false;
        }

        // Check if the amount is valid (greater than the last known amount)
        if (amount <= botTx.lastAmount) {
            return false;
        }

        // Generate the cheque hash from the parameters
        bytes32 chequeHash = getChequeHash(from, to, amount, nonce);

        // Check if the signature is valid and matches the 'from' address
        if (recoverSigner(chequeHash, signature) != from) {
            return false;
        }

        // If all checks pass, return true
        return true;
    }

    function getBotTransaction(address _from, address _to) public view returns (BotTransaction memory) {
        return botTransactionsStore[_from][_to];
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}
}