///////////////////////////
#TO DO
///////////////////////////

#QUICK LINKS
- mainnet infura
----> https://mainnet.infura.io/v3/1cad81887e224784a4d2ad2db5c0587a <----

- ETH whale address
----> 0x99C85bb64564D9eF9A99621301f22C9993Cb89E3 <----

- DAI checksumed address
----> 0x6B175474E89094C44Da98b954EedeAC495271d0F <----

- wETH whale address
----> 0x1e3d6eab4bcf24bcd04721caa11c478a2e59852d  <----

#TODO
- Launch basic swapping and shorting feature, more features to come later
- Swap and short standard works, but how can it be improved and how can it not cost a billion gas?
- add ability to use L2s?
- hook up SCs to front end
- test a shitcoin swap and short, something harder to borrow 



#FRONT END
- make sure all coins are being pulled in by name or are accessible by address
- UI/UX design
- hook up contracts to front end
- art!
- paginated api response from the graph for all tokens //not possible due to limited actual pools with dai    base pair
- bring up price of token on selection // lot of work, fuck it bro, not doing it rn //




#BACK END
- High Risk Pool contract
- look into Optimism compatibility
- Uniswap TWAP oracle  
- POOL CONTRACT:
    - incentives for depositors is being on opposite end of losing shorts
    - GTT depositors earn extra GTT which collect fees  
    - GTT holders earn GVR, which allows holders to vote in protocol proposals  
    - Bonus GVR is distributed to the top 25% of holders every 2nd week

- Voting System TBD
- Test voting and token contracts (TO DO LATER)
