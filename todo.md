
#TO DO

## QUICK LINKS
- mainnet infura
----> https://mainnet.infura.io/v3/1cad81887e224784a4d2ad2db5c0587a <----

- ETH whale address
----> 0x99C85bb64564D9eF9A99621301f22C9993Cb89E3 <----

- DAI checksumed address
----> 0x6B175474E89094C44Da98b954EedeAC495271d0F <----

- wETH whale address
----> 0x1e3d6eab4bcf24bcd04721caa11c478a2e59852d  <----

### DOING
 - Protocol REDESIGN
    - redoing how shorts are handled on the back end, will function more like a loan
    - swaps are now implemented in a uniV2 design rather than v3
        - this will allow for integration into other chains much easier and also allow for dex aggregator
    -

### TO DO
  - TWAP Oracles need to be done to function with univ2
  - liquidation logic needs to be redone
I think that's it?? then just front end stuff design, name (possible Doom Protocol)

## FRONT END
- make sure all coins are being pulled in by name or are accessible by address
- UI/UX design
- hook up contracts to front end
- art!
- paginated api response from the graph for all tokens //not possible due to limited actual pools with dai    base pair
- bring up price of token on selection // lot of work, fuck it bro, not doing it rn //




## BACK END
- High Risk Pool contract
- look into Optimism compatibility
- Uniswap TWAP oracle  

- Voting System TBD
- Test voting and token contracts (TO DO LATER)
