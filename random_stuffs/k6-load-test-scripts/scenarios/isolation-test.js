// scenarios/isolation-test.js
import { generateUserData } from '../modules/feeders/userDataGenerator.js';

// A very simple options object, no thresholds needed
export const options = {
  vus: 1,
  iterations: 5,
};

export default function() {
  console.log("--- Starting Isolation Test Iteration ---");
  const userData = generateUserData();
  console.log("Successfully generated userData:", JSON.stringify(userData));
  console.log("--- Finished Isolation Test Iteration ---");
}