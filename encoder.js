var Web3 = require('web3');

if (typeof web3 !== 'undefined') {
    web3 = new Web3(web3.currentProvider);
} else {
    web3 = new Web3(new Web3.providers.HttpProvider('http://localhost:8545'));
}

// const PUBLIC_KEY = '0x627306090abaB3A6e1400e9345bC60c78a8BEf57';
// const PRIVATE_KEY = '0x' + 'c87509a1c067bbde78beb793e6fa76530b6382a4c0241e5e4a9ec0a0f44dc0d3';


// var res = web3.eth.accounts.sign('Create Application, Nonce: 1, Amount: 1000', PRIVATE_KEY)
// console.log(res)

// var res = web3.eth.accounts.recover(res);
// console.log(res);

// var res = web3.eth.accounts.sign('Accept Application, Id: 1', PRIVATE_KEY)
// console.log(res)

// var res = web3.eth.accounts.recover(res);
// console.log(res);

module.exports = function (privKey, nonce, amount) {
    var res = web3.eth.accounts.sign(`Create Application, Nonce: ${nonce}, Amount: ${amount}`, privKey);
    var hash = res.messageHash;
    var signature = res.signature;
    return [hash, signature]
}