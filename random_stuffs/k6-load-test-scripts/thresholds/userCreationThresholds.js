import { commonThresholds } from './commonThresholds.js';

export const userCreationThresholds = {
  ...commonThresholds,
  // Add any specific thresholds for user creation here if needed
  // e.g., http_req_duration: ['p(90)<300'], // 90% of requests under 300ms
};