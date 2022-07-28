'reach 0.1';

const [ isHand, ROCK, PAPER, SCISSORS ] = makeEnum(3);
const [ isOutcome, B_WINS, DRAW, A_WINS ] = makeEnum(3);

// function to determine the winner based entered hands
const winner = (handAlice, handBob) =>((handAlice + (4 - handBob)) % 3);

// check that the winner function works as expected
assert(winner(ROCK, PAPER) == B_WINS);
assert(winner(PAPER, ROCK) == A_WINS);
assert(winner(ROCK, ROCK) == DRAW);

// also check that the winner function will always give a valid output
forall(UInt, handAlice =>
  forall(UInt, handBob => 
    assert(
      isOutcome(winner(handAlice, handBob))
    )
  )
)

// assertion for a DRAW
forall(UInt, (hand) =>
  assert(winner(hand, hand) == DRAW)
);

// define the player interact  to be used by both players
const Player = {
  ...hasRandom, // to create ambiquity for salt
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
    // get alice's wager from the frontend
    const wager = declassify(interact.wager)
    // get the hand played by Alice
    const _handAlice = interact.getHand()
    const [_commitAlice, _saltAlice ] = makeCommitment(interact,_handAlice)
    const commitALice = declassify(_commitAlice);
    
  });
  // publish Alice's wager and commitment in place of hand 
  Alice.publish(commitALice, wager)
    .pay(wager); //pay the wager
  // commit changes to the network
  commit();

  // add an assertion to ensure that Bob doesn't know Alice's hand 
  unknowable(Bob, Alice(_handAlice, _saltAlice));

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

  // commit changes from Bob's local step
  commit();

  Alice.only( () => {
    const saltAlice = declassify(_saltAlice);
    const handAlice = declassify(_handAlice);
  });
  Alice.publish(saltAlice, handAlice)
  // verify that the hand and salt are the same as the ones Alice 
  // commited to earlier
  checkCommitment(commitALice, saltAlice, handAlice)

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