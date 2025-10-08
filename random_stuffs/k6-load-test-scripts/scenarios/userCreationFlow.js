import { sleep } from 'k6';
import { getSuperAdminToken } from '../modules/api/auth.js';
import { createUser } from '../modules/api/users.js';
import { generateUserData } from '../modules/feeders/userDataGenerator.js';
import { userCreationThresholds } from '../thresholds/userCreationThresholds.js';

export const options = {
  stages: [
    { duration: '30s', target: 5 },
    { duration: '1m', target: 5 },
    { duration: '30s', target: 0 },
  ],
  thresholds: userCreationThresholds,
};

export function setup() {
  const token = getSuperAdminToken();
  if (!token) {
    throw new Error('Could not get super admin token.');
  }
  return { token };
}

export default function(data) {
  const token = data.token;


  try {
    console.log("upper")
    const userDataResult = generateUserData();
    if (!userDataResult || typeof userDataResult !== 'object') {
        console.error("CRITICAL: generateUserData did not return a valid object. Stopping iteration.");
        return;
    }
    const { userType, payload } = userDataResult;
    createUser(userType, token, payload);

    sleep(1);
    console.log(`Successfully created user of type: ${userType}`);
    
  } catch (error) {
    console.error("ERROR in userCreationFlow:", error.message);
    console.error("ERROR stack:", error.stack);
  }
}