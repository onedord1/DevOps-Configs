// scenarios/inline-test.js
import { randomInt, randomString } from 'k6';

// --- FUNCTION REWRITTEN TO BYPASS THE BUG ---
function getRandomEmail(baseName) {
  return `${baseName}_${randomInt(100000, 999999)}@demo.com`;
}

function getRandomPhone() {
  return `+8801${randomString(9, '0123456789')}`;
}

function generateUserData() {
  // Use a random number from 0 to 5 instead of array access
  const randomNumber = randomInt(0, 6); // Generates an integer from 0 to 5
  let userType;

  switch (randomNumber) {
    case 0:
      userType = 'bd-lead';
      break;
    case 1:
      userType = 'bd-incharge';
      break;
    case 2:
      userType = 'bdo';
      break;
    case 3:
      userType = 'cro';
      break;
    case 4:
      userType = 'company-admin';
      break;
    case 5:
      userType = 'bmd-admin';
      break;
    default:
      // This should technically never happen, but it's good practice.
      userType = 'bd-lead';
  }

  console.log(`DEBUG: generateUserData selected userType: ${userType}`);

  const baseUsername = userType.replace('-', '_');
  const timestamp = new Date().getTime();
  const randomSuffix = randomInt(1000, 9999);

  const commonData = {
    password: '123456',
    lineManager: `LineManager_${randomSuffix}`,
  };

  let payload;
  switch (userType) {
    case 'bd-lead':
      payload = {
        ...commonData,
        username: `${baseUsername}_${timestamp}_${randomSuffix}`,
        email: getRandomEmail(baseUsername),
        phoneNumber: getRandomPhone(),
      };
      break;
    case 'bd-incharge':
    case 'bdo':
    case 'cro':
      payload = {
        ...commonData,
        username: `${baseUsername}_${timestamp}_${randomSuffix}`,
        email: getRandomEmail(baseUsername),
        phoneNumber: getRandomPhone(),
        bdTerritoryIds: [],
      };
      break;
    case 'company-admin':
      payload = {
        ...commonData,
        username: `${baseUsername}_${timestamp}_${randomSuffix}`,
        email: getRandomEmail(baseUsername),
        phoneNumber: getRandomPhone(),
        orgId: 2,
      };
      break;
    case 'bmd-admin':
      payload = {
        ...commonData,
        username: `${baseUsername}_${timestamp}_${randomSuffix}`,
        email: getRandomEmail(baseUsername),
        phoneNumber: getRandomPhone(),
      };
      break;
    default:
      throw new Error(`Unknown userType: ${userType}`);
  }

  const result = { userType, payload };
  return result;
}
// --- END OF REWRITTEN FUNCTION ---


export const options = {
  vus: 1,
  iterations: 5,
};

export default function() {
  console.log("--- Starting Bypass Test Iteration ---");
  const userData = generateUserData();
  console.log("Successfully generated userData:", JSON.stringify(userData));
  console.log("--- Finished Bypass Test Iteration ---");
}