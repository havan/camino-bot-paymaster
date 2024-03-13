import { ethers } from 'ethers';

// The parameters for getMessageHash
const from = '0xYourFromAddress';
const to = '0xYourToAddress';
const amount = ethers.utils.parseUnits('1', 'ether'); // Example: sending 1 ether
const nonce = 1; // Nonce, ensure it's incremented for each transaction to prevent replay attacks

// Your Ethereum private key (Use environment variables or secure storage!)
const privateKey = 'your-private-key-here';

// Connect to the Ethereum network (This example uses the Rinkeby test network, change as needed)
const provider = new ethers.providers.JsonRpcProvider('https://api.camino.network/ext/bc/C/rpc');

// Create a new Wallet instance
const wallet = new ethers.Wallet(privateKey, provider);

// Generate the message hash
// Replicate getMessageHash function's logic here
const messageHash = ethers.utils.solidityKeccak256(
    ['address', 'address', 'uint256', 'uint256'],
    [from, to, amount, nonce]
);

// Sign the message hash
async function signMessage() {
    // Note: ethers.js handles message prefixing internally
    const signature = await wallet.signMessage(ethers.utils.arrayify(messageHash));
    console.log('Signature:', signature);
    return signature;
}

async function signHashDirectly() {
    // Sign the hash directly without adding a prefix
    const signature = await wallet._signingKey().signDigest(hashToSign);
    console.log('Signature:', signature);
    return signature;
}

// With prefix
signMessage().then(signature => console.log(signature)).catch(error => console.error(error));

// Without prefix
signHashDirectly().then(signature => console.log(signature)).catch(error => console.error(error));

