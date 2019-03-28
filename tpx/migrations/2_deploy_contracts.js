const TPXTokenContract = artifacts.require("./TPXToken.sol");
const TPXCrowdsaleContract = artifacts.require("./TPXCrowdsale_TEST_ONLY.sol");

module.exports = async function(deployer, network, accounts) {
    let wallet = '0xfe814ca17a55497a993a2d7656d440812b98b375';

    deployer.then(async () => {
      
        await deployer.deploy(TPXTokenContract);

        await deployer.link(TPXTokenContract, TPXCrowdsaleContract);
        console.log('TPXTokenContract!');
        await deployer.deploy(TPXCrowdsaleContract, wallet, TPXTokenContract.address);
        console.log('TPXCrowdsaleContract!');
        return console.log('Contracts are deployed!');
    });


};
