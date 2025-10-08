import { randomString, randomIntBetween } from 'https://jslib.k6.io/k6-utils/1.2.0/index.js'
const USER_TYPES = ['bd-lead', 'bd-incharge', 'bdo', 'cro', 'company-admin', 'bmd-admin'];
function getRandomEmail(baseName) {
  return `${baseName}_${randomIntBetween(100000, 999999)}@demo.com`;
}
function getRandomPhone() {
  return `+8801${randomString(9, '0123456789')}`;
}
export function generateUserData() {
  console.log("generate user data1")
  if (!USER_TYPES || USER_TYPES.length === 0) {
    console.error("CRITICAL: USER_TYPES array is not available or empty. Cannot generate user.");
    throw new Error("USER_TYPES array is not available or empty.");
  }

  const randomIndex = Math.floor(Math.random() * USER_TYPES.length);

  let userType = USER_TYPES[randomIndex];
  const safeUserType = String(userType);
  const baseUsername = safeUserType.replace('-', '_');
  const timestamp = new Date().getTime();
  let randomSuffix = Math.floor(Math.random() * 1000, 9999);
  console.log("BaseUsername" + baseUsername)
  const commonData = {
    password: '123456',
    lineManager: `LineManager_${randomSuffix}`,
  };

  let payload;
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
  return result;
}