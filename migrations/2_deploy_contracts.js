const LoanApplicationsContract = artifacts.require("LoanApplicationsContract");

module.exports = async function(deployer) {
    deployer.then(async () => {
        await deployer.deploy(LoanApplicationsContract);
    });
};

