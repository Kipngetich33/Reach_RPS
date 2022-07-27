import { loadStdlib } from '@reach-sh/stdlib';
import * as backend from './build/index.main.mjs';
const stdlib = loadStdlib();
const startingBalance = stdlib.parseCurrency(100);
const accAlice = await stdlib.newTestAccount(startingBalance);
const accBob = await stdlib.newTestAccount(startingBalance);
const ctcAlice = accAlice.contract(backend);
const ctcBob = accBob.contract(backend, ctcAlice.getInfo());

// define global variables to define the hand Played and Outcome
const HAND = ['Rock', 'Paper', 'Scissors'];
const OUTCOME = ['Bob wins', 'Draw', 'Alice wins'];

console.log("**********************Starting RPS***************************")

// define the front player interact object
const Player = (Who) => ({
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
  }),

  ctcBob.p.Bob({
    // inherit the Player interact object
    ...Player('Bob'),
  }),

]);