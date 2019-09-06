const expectThrow = require('./helpers/expectThrow');
const encoder = require('../encoder.js');

const LoanApplicationsContract = artifacts.require("LoanApplicationsContract");

contract('LoanApplicationsContract', ([ owner, acct1, acct2, acct3, acct4, acct5 ]) => {
    let loanContract;

    before('get the deployed contract', async () => {
        loanContract = await LoanApplicationsContract.deployed();
    });

    it('contracts should be deployed', async () => {
        assert.strictEqual(typeof LoanApplicationsContract.address, 'string');
    });

    it('should createApplication', async () => {
        await loanContract.createApplication(1000, { from: acct1 });
        let app = await loanContract.applications(0);
        assert.strictEqual(app.amountRequested.toNumber(), 1000);
        assert.strictEqual(app.borrower, acct1);
    });

    it('should delegatedCreateApplication', async () => {
        let privKey = '0x' + '0dbbe8e4ae425a6d2687f1a7e3ba17bc98c673636790f1b8ad91193c05875ef1';
        let nonce = 1;
        let amount = 1111;
        let res = encoder(privKey, nonce, amount);
        let hash = res[0];
        let signature = res[1];
        
        await loanContract.delegatedCreateApplication(acct2, nonce, amount, hash, signature, { from: acct1 });
        let app = await loanContract.applications(1);
        assert.strictEqual(app.amountRequested.toNumber(), amount);
        assert.strictEqual(app.borrower, acct2);
    });

});
