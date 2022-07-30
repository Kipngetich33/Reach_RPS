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
  seeOutcome: Fun([UInt],Null),
  informTimeout: Fun([], Null),
};

export const main = Reach.App(() => {

  const Alice = Participant('Alice', {
    // inherit the Player interact
    ...Player,
    wager: UInt,
    deadline: UInt,
  });

  const Bob = Participant('Bob', {
    // inherit the Player interact
    ...Player,
    acceptWager: Fun([UInt],Null),
  });

  // initialiaze contract
  init();

  // helper functions
  const informTimeout = () => {
    each([Alice, Bob], () => {
      interact.informTimeout();
    });
  };
  
  // start a local step for Alice
  Alice.only(() => {
    // get alice's wager from the frontend
    const wager = declassify(interact.wager);
    const deadline = declassify(interact.deadline);    
  });

  // publish Alice's wager and deadline
  Alice.publish(wager,deadline)
    .pay(wager);
  // commit changes to the network
  commit();

  // start a Bob local step
  Bob.only(() => {
    // ask Bob to accept the wager
    interact.acceptWager(wager); 
  })
  // publish pay wager
  Bob.pay(wager)
    .timeout(relativeTime(deadline), () => closeTo(Alice, informTimeout));

  var outcome = DRAW;
  invariant( balance() == 2 * wager && isOutcome(outcome) );
  while(outcome == DRAW) {
    // commit within the while loop so that the while loop is within a consensus step
    commit();

    // Alice local step
    Alice.only(() => {
      // get the hand played by Alice
      const _handAlice = interact.getHand()
      const [_commitAlice, _saltAlice ] = makeCommitment(interact,_handAlice)
      const commitAlice = declassify(_commitAlice);
    });
    
    // now publish Alice's commitment in the place of hand
    Alice.publish(commitAlice)
      .timeout(relativeTime(deadline), () => closeTo(Bob, informTimeout))
    commit();

  //   // add an assertion to ensure that Bob doesn't know Alice's hand 
    unknowable(Bob, Alice(_handAlice, _saltAlice));

    // Bob's local step
    Bob.only(() => {
      const handBob = declassify(interact.getHand());
    });
    Bob.publish(handBob)
      .timeout(relativeTime(deadline), () => closeTo(Alice, informTimeout))
    commit();
 
    // Alice step to reveal hand
    Alice.only(() => {
      const saltAlice = declassify(_saltAlice);
      const handAlice = declassify(_handAlice);
    });
    // now publish hand and salt to the network
    Alice.publish(saltAlice, handAlice)
      .timeout(relativeTime(deadline), () => closeTo(Bob, informTimeout))
    
    // check that the hand revealed by Alice is the same as what she commited to
    checkCommitment(commitAlice,saltAlice,handAlice);
    //now determine the winner of the game
    outcome = winner(handAlice,handBob)
    // explicitly adda a continue so that the loop can continue
    continue;
  }

  // add a test to ensure that there will never be draw at this point
  assert(outcome == A_WINS || outcome == B_WINS);

  // // transfer all the funds to the winner of the game
  transfer(2 * wager).to(outcome == A_WINS ? Alice: Bob)
  // commit the changes in this steps above
  commit();

  // display the outcome of the game to both player
  each([Alice,Bob], () => {
    // call the see outcome function
    interact.seeOutcome(outcome)
  })
});