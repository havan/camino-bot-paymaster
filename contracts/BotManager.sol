// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";

// TODO: Optimize for gas 

contract BotManager is Ownable {

    struct BotTransaction {
        uint256 lastNonce;
        uint256 lastAmount;
    }

    mapping(address => mapping(address => BotTransaction)) private botTransactions;

    mapping(address => bool) public approvedBots;

    // Events
    event BotApproved(address indexed bot);
    event BotRevoked(address indexed bot);
    event CheckCashed(address indexed from, address indexed to, uint256 amount, uint256 nonce);

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

    function getMessageHash(address from, address to, uint256 amount, uint256 nonce) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(from, to, amount, nonce));
    }

    function recoverSigner(bytes32 messageHash, bytes memory signature) public pure returns (address) {
        // Check the signature's length
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
        return ecrecover(messageHash, v, r, s);
    }

    function cashCheck(address from, address to, uint256 amount, uint256 nonce, bytes memory signature) public {
        require(approvedBots[from], "Bot not approved");
        require(to != address(0), "Invalid recipient address");

        BotTransaction memory botTx = botTransactions[from][to];
        
        require(nonce > botTx.lastNonce, "Nonce too low");
        require(amount > botTx.lastAmount, "Amount not greater than last known amount");

        bytes32 messageHash = getMessageHash(from, to, amount, nonce);
        // Check if the signature matches the from address. This proves that the
        // bot has created a signature with the correct nonce, amount and to
        // address, which in our context is a valid check.
        require(recoverSigner(messageHash, signature) == from, "Invalid signature");

        // Calculate the amount to transfer
        uint256 previousAmount = botTx.lastAmount;
        uint256 transferAmount = amount - previousAmount;

        // Update the stored values in the struct
        botTransactions[from][to] = BotTransaction(nonce, amount);

        // Transfer the funds to the "to" address
        payable(to).transfer(transferAmount);

        emit CheckCashed(from, to, amount, nonce);
    }

    function getBotTransaction(address _from, address _to) public view returns (BotTransaction memory) {
        return botTransactions[_from][_to];
    }
}