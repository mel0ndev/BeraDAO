
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

### NEW //TODO
  - Constants.sol
        - STORE ALL CONSTANTS IN HERE -- SAVE GAS
        - lots of reused globals can be put into one file and reused everywhere, gonna make things much
          easier later on
        - also acts as a deployer so all contracts can have access to each other

### TESTING
  - Standard Pool Testing:
      - Swapping not allowed in pool unless collateral has been deposited //WORKS

      - Deposits:


      - Swap Short: //COMPLETE REDESIGN

        - swaps are now functional, need to test ERC1155 and decide if I want the amount to be in the ERC1155

          - Standard Risk pool accepts only 0.3 and 0.05 pools only High risk will accept all
          - Check that users are receiving dai back from the pool on open
          - check that proper fees are taken
          - use swap price as price to return DAI
          - add to their shortID by 1
          - check if they have collateral
              - if they do, we check that the total amount is not exceeded by their total amount already in   shorts
          - take a 1% fee and add it to global controlled by protocol
          - execute swap on BeraSwapper
          - get twap for price at wrap  
          - execute BeraWrapper postionWrap()
          - update account details for other parts of protocol to use


        - On close:
          - we check that they have the nft in their wallet to redeem for their profits
          - we check that the position is still active
          -
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
