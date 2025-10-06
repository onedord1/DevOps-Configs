// modules/feeders/userDataGenerator.js
import { randomInt, randomString } from 'k6';

const USER_TYPES = ['bd-lead', 'bd-incharge', 'bdo', 'cro', 'company-admin', 'bmd-admin'];

function getRandomEmail(baseName) {
  return `${baseName}_${randomInt(100000, 999999)}@demo.com`;
}

function getRandomPhone() {
  return `+8801${randomString(9, '0123456789')}`;
}

export function generateUserData() {
  if (!USER_TYPES || USER_TYPES.length === 0) {
    console.error("CRITICAL: USER_TYPES array is not available or empty. Cannot generate user.");
    throw new Error("USER_TYPES array is not available or empty.");
  }

  const randomIndex = Math.floor(Math.random() * USER_TYPES.length);
  let userType = USER_TYPES[randomIndex];

  // --- THE FIX ---
  // Explicitly convert userType to a string to prevent the "Value is not an object: null" error.
  // This handles the edge case where the variable might become null between checks.
  const safeUserType = String(userType);
  // ----------------

  console.log(`DEBUG: generateUserData selected userType: ${safeUserType}`);

  // Use the safe, guaranteed-to-be-a-string variable
  const baseUsername = safeUserType.replace('-', '_');
  const timestamp = new Date().getTime();
  const randomSuffix = randomInt(1000, 9999);

  const commonData = {
    password: '123456',
    lineManager: `LineManager_${randomSuffix}`,
  };

  let payload;
  // Use the safe variable in the switch statement as well
  switch (safeUserType) {
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
      throw new Error(`Unknown userType: ${safeUserType}`);
  }

  const result = { userType: safeUserType, payload };
  // You can remove this debug log now that the issue is fixed
  // console.log('DEBUG generateUserData: returning result =', JSON.stringify(result));
  return result;
}