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
  });
  const Bob   = Participant('Bob', {
    // inherit the Player interact
    ...Player,
  });

  // initialiaze contract
  init();
  

  // start a local step for Alice
  Alice.only(() => {
    // get the hand played by Alice
    const handAlice = declassify(interact.getHand()) 
  });
  // publish Alice hand to the network
  Alice.publish(handAlice)
  // commit changes to the network
  commit();

  // start a Bob local step
  Bob.only(() => {
    // get bob's hand
    const handBob = declassify(interact.getHand()) 
  })
  // publish Bob hand to the network
  Bob.publish(handBob)

  //now calculate the winner of the game
  const outcome = (handAlice + (4 - handBob)) % 3;
  commit();

  // display the outcome of the game to both player
  each([Alice,Bob], () => {
    // call the see outcome function
    interact.seeOutcome(outcome)
  })

});