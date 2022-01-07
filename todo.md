
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
 - REFACTOR
    - code base is pretty dogshit and unoptimized
    - probably takes a week or two?  

### TESTING
  - Standard Pool Testing:
      - Swapping not allowed in pool unless collateral has been deposited //WORKS

      - Deposits: //KIND OF FUNCTIONAL (with minor bugs)

        - ISSUES:
          - Need to keep track of depositBalance in conjunction with shortAmount
              - currently users can deposit once and then use those funds to open more positions with those //FIXED
                funds. ie, deposit 1000 dai once and use it numerous times to open 1000 dai positions
          - Deposits are not stored as 1e18 for userDepositBalance and will fuck up distribution //FIXED
        - WHAT WORKS
          - basic deposit
          - addresses are being pushed into array as intended
              - public dynamic arrays require a uint to be passed into them as a parameter in web3?
              - this could possibly be the size of the array? maybe keep track of it somewhere to pass to
                frontend function
          - depositCollateralBalance is being updated as intended
          - pool address is receiving the funds as intended


      - Swap Short: //COMPLETE REDESIGN
          - Standard Risk pool accepts only 0.3 and 0.05 pools only High risk will accept all
          - Check that users are receiving dai back from the pool on open
          - check that proper fees are taken
          - use swap price as price to return DAI


        - On close:
          - We swap back for dai and then transfer that amount from users wallet, which will revert if they
            do not have enough dai in their wallet to send back to the protocol. 





      - Withdraws:
          - withdraw is not possible unless userPositionNumber is closed as intended
          -

      - Oracle:
          - Oracle is retrieving data, but not sure how decimals are going to work
          - most erc20 have 18 but it can be arbitrary, so will have to make a call to token contract
            and retrieve the decimals from the token itself? Just look into this later



# MVP RELEASE
    - The standard Pool will be the only pool released at initial launch, high risk pool will follow
      shortly after, maybe 1-2 months after kinks are ironed out of standard pool
    -




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
