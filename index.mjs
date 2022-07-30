import { loadStdlib, ask } from '@reach-sh/stdlib';
import * as backend from './build/index.main.mjs';
const stdlib = loadStdlib();

console.log("**********************Starting RPS***************************")

// define global variables to define the hand Played and Outcome
const HAND = ['Rock', 'Paper', 'Scissors'];
const HANDS = {
  'Rock': 0, 'R': 0, 'r': 0,
  'Paper': 1, 'P': 1, 'p': 1,
  'Scissors': 2, 'S': 2, 's': 2,
};
const OUTCOME = ['Bob wins', 'Draw', 'Alice wins'];

// define some helper functions
const fmt = (x) => stdlib.formatCurrency(x, 4);
const getBalance = async (acc) => fmt(await stdlib.balanceOf(acc));

const isAlice = await ask.ask(
  `Are you Alice?`,
  ask.yesno
);
const who = isAlice ? 'Alice' : 'Bob';

console.log(`Starting Rock, Paper, Scissors! as ${who}`);

// define starting balance to be used by both participants 
// const startingBalance = stdlib.parseCurrency(100);
// create new test accounts for both participants
// const accAlice = await stdlib.newTestAccount(startingBalance);
// const accBob = await stdlib.newTestAccount(startingBalance);
// get the balances of both accounts

let acc = null;
const createAcc = await ask.ask(
  `Would you like to create an account? (only possible on devnet)`,
  ask.yesno
);
if (createAcc) {
  acc = await stdlib.newTestAccount(stdlib.parseCurrency(1000));
} else {
  const secret = await ask.ask(
    `What is your account secret?`,
    (x => x)
  );
  acc = await stdlib.newAccountFromSecret(secret);
}

// const beforeAlice = await getBalance(accAlice);
// const beforeBob = await getBalance(accBob);
// // initialize the contract(Alice) and attach to it using Bob's account
// const ctcAlice = accAlice.contract(backend);
// const ctcBob = accBob.contract(backend, ctcAlice.getInfo());

// initiate/ attach to an existing contract
let ctc = null;
if (isAlice) {
  ctc = acc.contract(backend);
  ctc.getInfo().then((info) => {
    console.log(`The contract is deployed as = ${JSON.stringify(info)}`); });
} else {
  const info = await ask.ask(
    `Please paste the contract information:`,
    JSON.parse
  );
  ctc = acc.contract(backend, info);
}

const before = await getBalance(acc);
console.log(`Your balance is ${before}`);

const interact = { ...stdlib.hasRandom };


interact.informTimeout = () => {
  console.log(`There was a timeout.`);
  process.exit(1);
};

if (isAlice) {
  const amt = await ask.ask(
    `How much do you want to wager?`,
    stdlib.parseCurrency
  );
  interact.wager = amt;
  interact.deadline = { ETH: 100, ALGO: 100, CFX: 1000 }[stdlib.connector];
} else {
  interact.acceptWager = async (amt) => {
    const accepted = await ask.ask(
      `Do you accept the wager of ${fmt(amt)}?`,
      ask.yesno
    );
    if (!accepted) {
      process.exit(0);
    }
  };
}


// define the gethand method to be called using interact
interact.getHand = async () => {
  const hand = await ask.ask(`What hand will you play?`, (x) => {
    const hand = HANDS[x];
    if ( hand === undefined ) {
      throw Error(`Not a valid hand ${hand}`);
    }
    return hand;
  });
  console.log(`You played ${HAND[hand]}`);
  return hand;
};

// define the seeOutcome method to be called using interact
interact.seeOutcome = async (outcome) => {
  console.log(`The outcome is: ${OUTCOME[outcome]}`);
};

const part = isAlice ? ctc.p.Alice : ctc.p.Bob;
await part(interact);

const after = await getBalance(acc);
console.log(`Your balance is now ${after}`);
ask.done();

// // define the front player interact object
// const Player = (Who) => ({
//   ...stdlib.hasRandom,
//   getHand: () => {
//     // get a random int which is less than 3 
//     const hand = Math.floor(Math.random() * 3);
//     // use the HAND options above to show the hand choosen by the user with random number
//     console.log(`${Who} played ${HAND[hand]}`);
//     // return the integer number representing the chosen number
//     return hand;
//   },
//   seeOutcome: (outcome) => {
//     console.log(`${Who} saw outcome ${OUTCOME[outcome]}`)
//   },
//   informTimeout: (Who) => {
//     console.log(`${Who} observed a timeout`);
//   }
// });


// await Promise.all([
//   ctcAlice.p.Alice({
//     // inherit the Player interact object
//     ...Player('Alice'),
//     wager: stdlib.parseCurrency(5),
//     deadline: 10,
//   }),

//   ctcBob.p.Bob({
//     // inherit the Player interact object
//     ...Player('Bob'),
//     acceptWager: (amt) => {
//       // function that allows Bob to accept the wager amount
//       console.log(`Bob accepts the wager of ${fmt(amt)}.`);
//     }
//   }),
// ]);

// const afterAlice = await getBalance(accAlice);
// const afterBob = await getBalance(accBob);
// console.log(`Alice went from ${beforeAlice} to ${afterAlice}.`);
// console.log(`Bob went from ${beforeBob} to ${afterBob}.`);