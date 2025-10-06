import http from 'k6/http';
import { checkResponse } from '../util/validate.js';
import { log } from '../util/logger.js';
import { BASE_URL } from '../../config/staging.js';

export function createUser(userType, token, payload) {
  log(`Creating user of type: ${userType}`);
  const url = `${BASE_URL}/api/v1/users?userType=${userType}`;

  const params = {
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${token}`,
    },
  };

  const response = http.post(url, JSON.stringify(payload), params);
  checkResponse(response, `Create ${userType} User`);
  return response;
}