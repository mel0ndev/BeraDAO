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
- hook up SCs to front end //ON HOLD UNTIL REFACTOR IS FINISHED


#CURRENT ISSUES
- Swaps require several approvals and several actual swaps when they are probably not necessary

    - the easiest thing to do would be to have the pool itself swap the 5% of the trade kept into eth to pay
      for gas fees. The issue is how expensive this would be, and would it actually function in production?

    - Alternatively, we could launch with the current system of having users approve and pay for gas fees
      for the pool which could potentially disincentivize using the platform. Paying $100 for a swap? nah.

- Do best to avoid high gas, but it shouldn't be a priority.
    - Priority 1 is shipping the product and have it work as intended. This is software at the end of the day.
      v2 will have many improvements to the code, along with more eyes (hopefully) to look at the project.
      I think that I am focusing too much on minor things that are not important to the overall project and it is
      detrimental to the actual work able to get done.

    - What is important now is getting the project into the hands of users.



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
- POOL CONTRACT:
    - incentives for depositors is being on opposite end of losing shorts
    - GTT depositors earn extra GTT which collect fees  
    - GTT holders earn GVR, which allows holders to vote in protocol proposals  
    - Bonus GVR is distributed to the top 25% of holders every 2nd week

- Voting System TBD
- Test voting and token contracts (TO DO LATER)
