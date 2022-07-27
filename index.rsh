'reach 0.1';

// define the player interact  to be used by both players
const Player = {
  getHand: Fun([],UInt),
  seeOutcome: Fun([UInt],Null)
};

export const main = Reach.App(() => {

  const Alice = Participant('Alice', {
    // inherit the Player interact
    ...Player,
    wager: UInt,
  });
  const Bob   = Participant('Bob', {
    // inherit the Player interact
    ...Player,
    acceptWager: Fun([UInt],Null)
  });

  // initialiaze contract
  init();
  

  // start a local step for Alice
  Alice.only(() => {
    // get the hand played by Alice
    const handAlice = declassify(interact.getHand()) 
    const wager = declassify(interact.wager)
  });
  // publish Alice hand and wager
  Alice.publish(handAlice, wager)
    .pay(wager); //pay the wager
  // commit changes to the network
  commit();

  // start a Bob local step
  Bob.only(() => {
    // ask Bob to accept the wager
    interact.acceptWager(wager);
    // get bob's hand
    const handBob = declassify(interact.getHand())  
  })
  // publish Bob hand to the network
  Bob.publish(handBob)
    .pay(wager)

  //now calculate the winner of the game
  const outcome = (handAlice + (4 - handBob)) % 3;
  // calculate the funds share percentages for both Participant
  // depending on who won
  const [forAlice, forBob] =
    outcome == 2 ? [       2,      0] :
    outcome == 0 ? [       0,      2] :
    /* tie      */ [       1,      1];

  // now transfer the funds based on the share ratio above
  transfer(forAlice * wager).to(Alice);
  transfer(forBob   * wager).to(Bob);  
  commit();

  // display the outcome of the game to both player
  each([Alice,Bob], () => {
    // call the see outcome function
    interact.seeOutcome(outcome)
  })

});