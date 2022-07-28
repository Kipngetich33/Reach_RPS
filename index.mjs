import { loadStdlib } from '@reach-sh/stdlib';
import * as backend from './build/index.main.mjs';
const stdlib = loadStdlib();

// define some helper functions
const fmt = (x) => stdlib.formatCurrency(x, 4);
const getBalance = async (who) => fmt(await stdlib.balanceOf(who));

// define starting balance to be used by both participants 
const startingBalance = stdlib.parseCurrency(100);
// create new test accounts for both participants
const accAlice = await stdlib.newTestAccount(startingBalance);
const accBob = await stdlib.newTestAccount(startingBalance);
// get the balances of both accounts
const beforeAlice = await getBalance(accAlice);
const beforeBob = await getBalance(accBob);
// initialize the contract(Alice) and attach to it using Bob's account
const ctcAlice = accAlice.contract(backend);
const ctcBob = accBob.contract(backend, ctcAlice.getInfo());

// define global variables to define the hand Played and Outcome
const HAND = ['Rock', 'Paper', 'Scissors'];
const OUTCOME = ['Bob wins', 'Draw', 'Alice wins'];

console.log("**********************Starting RPS***************************")

// define the front player interact object
const Player = (Who) => ({
  ...stdlib.hasRandom,
  getHand: () => {
    // get a random int which is less than 3 
    const hand = Math.floor(Math.random() * 3);
    // use the HAND options above to show the hand choosen by the user with random number
    console.log(`${Who} played ${HAND[hand]}`);
    // return the integer number representing the chosen number
    return hand;
  },
  seeOutcome: (outcome) => {
    console.log(`${Who} saw outcome ${OUTCOME[outcome]}`)
  }
});


await Promise.all([
  ctcAlice.p.Alice({
    // inherit the Player interact object
    ...Player('Alice'),
    wager: stdlib.parseCurrency(5),
  }),

  ctcBob.p.Bob({
    // inherit the Player interact object
    ...Player('Bob'),
    acceptWager: (amt) => {
      // function that allows Bob to accept the wager amount
      console.log(`Bob accepts the wager of ${fmt(amt)}.`);
    }
  }),

]);

const afterAlice = await getBalance(accAlice);
const afterBob = await getBalance(accBob);
console.log(`Alice went from ${beforeAlice} to ${afterAlice}.`);
console.log(`Bob went from ${beforeBob} to ${afterBob}.`);