import http from 'k6/http';
import { checkResponse } from '../util/validate.js';
import { log, logError } from '../util/logger.js';
import { BASE_URL, SUPER_ADMIN_USERNAME, SUPER_ADMIN_PASSWORD } from '../../config/staging.js';

export function getSuperAdminToken() {
  log('Attempting to authenticate as Super Admin...');
  const url = `${BASE_URL}/authenticate`;

  // The payload must be form-encoded
  const payload = `username=${SUPER_ADMIN_USERNAME}&password=${SUPER_ADMIN_PASSWORD}`;
  const params = {
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
    },
  };

  const response = http.post(url, payload, params);
  const success = checkResponse(response, 'Super Admin Authentication');

  if (!success) {
    logError('Authentication failed. Aborting test.');
    return null; // This will cause the test to fail gracefully
  }

  const responseBody = JSON.parse(response.body);

  const token = responseBody.token;

  if (!token) {
    logError('Authentication succeeded, but no token was found in the response.');
    return null;
  }

  log('Successfully authenticated Super Admin.');
  return token;
}