import assertRevert from '../test/assertRevert';
const { ethGetBalance } = require("../test/web3");

const BigNumber = web3.BigNumber;

const should = require('chai')
  .use(require('chai-as-promised'))
  .use(require('chai-bignumber')(BigNumber))
  .should();

const TPXCrowdsale = artifacts.require('TPXCrowdsale_TEST_ONLY');
const TPXToken = artifacts.require('TPXToken');

contract('TPXCrowdsale', function (accounts) {
  let wallet = accounts[5];
  let investor = accounts[2];
  let notinvestor = accounts[3];
  const rate = new BigNumber(1);
  const value = new BigNumber(web3.toWei(1, 'ether'));
  const usd100K = new BigNumber(web3.toWei(2, 'ether'));
  const tokenSupply = 0;
  let expectedTokenAmount = 12;

  let token;
  let crowdsale;

  beforeEach(async function () {
      token = await TPXToken.new();
      crowdsale = await TPXCrowdsale.new(wallet, token.address);
      await token.approve(crowdsale.address, "1000000000000000000000000");
      await crowdsale.addAddressToWhitelist(investor);
      await crowdsale.__callback(46000, 1);// Eth price in USD cents (only for test)
      await crowdsale.__callback(122898250000, 2);// Eth price in USD cents (only for test)
  });

  describe('high-level purchase', function () {
    it('should log purchase', async function () {
      const { logs } = await crowdsale.buyTokens({ value: value, from: investor });
      const event = logs.find(e => e.event === 'TokenPurchase');
      should.exist(event);
      event.args.purchaser.should.equal(investor);
      event.args.value.should.be.bignumber.equal(value);
      Math.round(event.args.amount/10**18).should.be.equal(expectedTokenAmount);
    });

    it('should log purchase for fiat', async function () {
      const { logs } = await crowdsale.buyForFiat(investor, value);
      const event = logs.find(e => e.event === 'TokenPurchase');
      should.exist(event);
      event.args.purchaser.should.equal(investor);
      event.args.value.should.be.bignumber.equal(value);
      Math.round(event.args.amount/10**18).should.be.equal(expectedTokenAmount);
    });

    it('should assign tokens to sender', async function () {
      const { logs } = await crowdsale.sendTransaction({ value: value, from: investor });
      let balance = await token.balanceOf(investor);
      Math.round(balance.valueOf()/10**18).should.be.equal(expectedTokenAmount);
    });

    it('should forward funds to the wallet', async function () {
      const pre = await ethGetBalance(investor);
      const txInfo = await crowdsale.buyTokens({ value:value, from: investor });
      const tx = await web3.eth.getTransaction(txInfo.tx);
      const gasCost = tx.gasPrice.mul(txInfo.receipt.gasUsed);
      const post = await ethGetBalance(investor);
      pre.minus(post).minus(gasCost).should.be.bignumber.equal(value);
    });
  });

  describe('control functions', function () {

    it('should revert buying tokens after the finish of crowdsale', async function () {
      await crowdsale.sendTransaction({ value: value, from: investor });
      const pre = await ethGetBalance(investor);
      await crowdsale.finishCrowdsale();
      await assertRevert(crowdsale.buyTokens({ value: value, from: investor }));
      await assertRevert(crowdsale.sendTransaction({ value: value, from: investor }));
      await assertRevert(crowdsale.finishCrowdsale());
    });

    it('should revert buying tokens from not-whitelisted buyer', async function () {
      await assertRevert(crowdsale.sendTransaction({ value: value, from: notinvestor }));
    });

    it('should revert the purchase when crowdsale is paused and then process one when unpaused', async function () {
      await crowdsale.pause();
      await assertRevert(crowdsale.sendTransaction({ value: value, from: investor }));
      await crowdsale.unpause();
      await crowdsale.sendTransaction({ value: value, from: investor });
    });

    it('another functionality', async function () {
      await crowdsale.sendTransaction({ value: usd100K, from: investor });
      await assertRevert(crowdsale.withdrawFunds(investor, value));
      await crowdsale.payToContract({value: value});
      await crowdsale.transferOwnership(investor);
      await crowdsale.claimOwnership({from: investor});
      await token.pause();
      await assertRevert(token.transfer(accounts[0], 100, {from: investor}));
      await token.unpause();
      await token.transfer(accounts[0], 100, {from: investor});
      await token.transferOwnership(investor);
      await token.claimOwnership({from: investor});

    });
  });
});
