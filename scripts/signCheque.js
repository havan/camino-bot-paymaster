require('dotenv').config();
const { ethers, computeAddress } = require('ethers');

// Create a .env file by copying .env.example to .env and set the address and private key variables
// 
// Use the NON-PREFIXED signature with the BotPayMaster contract's cashCheque function

if (process.argv.length < 5) {
    console.log('Usage: node script.js <to> <amount> <nonce>');
    console.log('Example: node script.js 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db 1000000000000000000 1');
    process.exit(1);
}

const from = process.env.FROM_ADDRESS;
const privateKey = process.env.PRIVATE_KEY;
const wallet = new ethers.Wallet(privateKey);

console.log("------ WALLET ------")
console.log("PUBKEY\t\t:", wallet.signingKey.publicKey)
console.log("COMPRESSED\t:", wallet.signingKey.compressedPublicKey)
console.log("--------------------")

console.log()


const to = process.argv[2];
const amount = process.argv[3];
const nonce = process.argv[4];

const chequeHash = ethers.solidityPackedKeccak256(
    ["address", "address", "uint256", "uint256"],
    [from, to, amount, nonce]
);

console.log("------ CHEQUE ------")
console.log('FROM\t:', from)
console.log('TO\t:', to)
console.log('AMOUNT\t:', amount)
console.log('NONCE\t:', nonce)
console.log('HASH\t:', chequeHash);
console.log("--------------------")

console.log()

console.log("------ SIGNATURES & COMPUTED PUBKEY & ADDRESS ------")
async function signCheque(from, to, amount, nonce) {
    const signature = await wallet.signMessage(ethers.getBytes(chequeHash));
    console.log('PREFIXED SIGNATURE:\n', signature);
    console.log()
    return signature
}

// Sign the hash directly without adding a prefix
async function signHashDirectly(from, to, amount, nonce) {
    const signature = await wallet.signingKey.sign(chequeHash);
    signatureSerialized = ethers.Signature.from(signature).serialized
    console.log('NON-PREFIXED SIGNATURE (Use this with BotPayMaster):\n', signatureSerialized);
    console.log()
    return signatureSerialized;
}

signCheque(from, to, amount, nonce).then(
    nonPrefixedSignature => console.log("RECOVER PUBKEY (PREFIXED):\n", ethers.SigningKey.recoverPublicKey(chequeHash, nonPrefixedSignature), "\n")
)

signHashDirectly(from, to, amount, nonce).then(
    nonPrefixedSignature => {
        pubkey = ethers.SigningKey.recoverPublicKey(chequeHash, nonPrefixedSignature);
        console.log("RECOVER PUBKEY (NON-PREFIXED):\n", pubkey);
        console.log();
        console.log("COMPUTED ADDR (Should be same with 'from' address):\n", ethers.computeAddress(pubkey));
    }
)
