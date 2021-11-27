# ETH current price: 4112.68
# We want to charge $50 for the lottery
# 50 / 4112.68 = 0.012157522588677 = 0.012
# $0.012 ETH = 12000000000000000 WEI
from brownie import Lottery, accounts, network, config
from web3 import Web3

def test_get_entrance_fee():
    account = accounts[0]
    lottery = Lottery.deploy(
        config["networks"][network.show_active()]["eth_usd_price_feed"],
        {"from": account},
    )
    assert lottery.getEntranceFee() > Web3.toWei(0.011, "ether")
    assert lottery.getEntranceFee() < Web3.toWei(0.013, "ether")
