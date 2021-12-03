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

#DOING
 - Moving all router logic to pool contracts, makes things much easier
    - Currently migrating swap and short functions


#TESTING
  - Standard Pool Testing:
      - Swapping not allowed in pool unless collateral has been deposited //WORKS

      - Deposits: //FULLY FUNCTIONAL ##(with minor bug)

        - ISSUES:
          - Need to keep track of depositBalance in conjunction with shortAmount
              - currently users can deposit once and then use those funds to open more positions with those
                funds. ie, deposit 1000 dai once and use it numerous times to open 1000 dai positions
          - Deposits are not stored as 1e18 and will fuck up distribution
        - WHAT WORKS
          - basic deposit
          - addresses are being pushed into array as intended
              - public dynamic arrays require a uint to be passed into them as a parameter?
              - this could possibly be the size of the array? maybe keep track of it somewhere to pass to
                web3 function
          - depositCollateralBalance is being updated as intended
          - pool address is receiving the funds as intended


      - Swap and Short : //FULLY FUNCTIONAL
          - swapandshort is storing each short separately as intended
          - is working as one function call
          - is sending an erc1155 //double check


      - Closing Position:
          -

          
      - Withdraws:
          - withdraw is not possible unless userPositionNumber is closed
          -



#TODO ABSOLUTE MUST HAVE FEATURES FOR MVP

- TWAP Oracle contract is 100% necessary
- Pool rewards must be 100% functional
-




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

- Voting System TBD
- Test voting and token contracts (TO DO LATER)
